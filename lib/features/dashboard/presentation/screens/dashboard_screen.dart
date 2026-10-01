import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/error_state.dart';
import '../widgets/dashboard_action_handlers.dart';
import '../widgets/dashboard_enquiries_tab.dart';
import '../widgets/dashboard_enquiry_utils.dart';
import '../widgets/dashboard_tab_bar_delegate.dart';
import '../widgets/dashboard_welcome_panel.dart';

/// Enhanced Dashboard Screen with tabs and statistics
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    this.embeddedInShell = false,
    this.onNavigateToCalendar,
    this.onNavigateToAnalytics,
  });

  /// Retained for call-site compatibility; the dashboard is always rendered as a
  /// body inside [AppShell] (no own [Scaffold]).
  final bool embeddedInShell;

  /// Called when the user taps the "this week" priority bucket, requesting
  /// the shell to switch to the Calendar tab.
  final VoidCallback? onNavigateToCalendar;

  /// Called when admin taps "View all stats" on the dashboard.
  final VoidCallback? onNavigateToAnalytics;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin, DashboardActionHandlers<DashboardScreen> {
  late TabController _tabController;
  final Map<String, Color> _statusColorCache = <String, Color>{};
  final Map<String, Color> _eventColorCache = <String, Color>{};
  final List<Map<String, String>> _statusTabs = [
    {'label': 'New', 'value': 'new'},
    {'label': 'In Talks', 'value': 'in_talks'},
    {'label': 'Follow Up', 'value': 'reminders'},
    {'label': 'Approved', 'value': 'approved'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Closed', 'value': 'closed'},
  ];

  late final List<String> _tabLabels;

  /// Keeps the hero (and its live counters) mounted while the status tab
  /// subtree below is re-keyed on every tab switch.
  final GlobalKey _heroKey = GlobalKey(debugLabel: 'dashboard-hero');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _primeDropdownColors();
    _tabLabels = _statusTabs.map((tab) => tab['label']!).toList(growable: false);
    _searchController.addListener(_handleSearchChanged);
    // Run automatic cleanup for past enquiries (only for admins, runs silently in background)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAutomaticCleanup();
    });
  }

  Future<void> _primeDropdownColors() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    try {
      final statusSnapshot = await firestoreService.fetchActiveDropdownItems('statuses');
      for (final doc in statusSnapshot.docs) {
        final data = doc.data();
        final value = (data['value'] as String?)?.trim();
        final colorHex = data['color'] as String?;
        if (value == null || value.isEmpty || colorHex == null) continue;
        final color = parseDashboardColor(colorHex);
        if (color != null) {
          _statusColorCache[value.toLowerCase()] = color;
        }
      }

      final eventSnapshot = await firestoreService.fetchActiveDropdownItems('event_types');
      for (final doc in eventSnapshot.docs) {
        final data = doc.data();
        final value = (data['value'] as String?)?.trim();
        final colorHex = data['color'] as String?;
        if (value == null || value.isEmpty || colorHex == null) continue;
        final color = parseDashboardColor(colorHex);
        if (color != null) {
          _eventColorCache[value.toLowerCase()] = color;
        }
      }
    } catch (e, st) {
      Log.w('Failed to load dropdown colors', data: {'error': e.toString()});
      Log.d('Dropdown color load stack', data: st.toString());
    }

    if (mounted) setState(() {});

    if (kDebugMode) {
      Log.d(
        'Dropdown caches primed',
        data: {
          'statuses': _statusColorCache.keys.toList(),
          'eventTypes': _eventColorCache.keys.toList(),
        },
      );
    }
  }

  /// Runs automatic cleanup for past enquiries (only for admins)
  /// This runs silently in the background without blocking the UI
  Future<void> _runAutomaticCleanup() async {
    try {
      final roleAsync = ref.read(roleProvider);
      final role = roleAsync.valueOrNull;

      // Only run for admins
      if (role != UserRole.admin) {
        return;
      }

      final currentUserAsync = ref.read(currentUserWithFirestoreProvider);
      final currentUser = currentUserAsync.valueOrNull;
      final userId = currentUser?.uid ?? 'system';

      // Run cleanup in background (non-blocking)
      final cleanupService = ref.read(pastEnquiryCleanupServiceProvider);
      unawaited(
        cleanupService
            .runAutomaticCleanup(userId: userId)
            .then((updatedCount) {
              if (updatedCount != null && updatedCount > 0 && mounted) {
                Log.i('Automatic cleanup completed', data: {'updatedCount': updatedCount});
              }
            })
            .catchError((Object error, StackTrace stack) {
              Log.e('Automatic cleanup error', error: error, stackTrace: stack);
            }),
      );
    } catch (e) {
      Log.e('Error initiating automatic cleanup', error: e);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _searchQuery) return;
    setState(() {
      _searchQuery = next;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _handleSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final roleAsync = ref.watch(roleProvider);

    // Always hosted inside AppShell, which owns the Scaffold, AppBar, nav and FAB.
    return currentUser.when(
      data: (user) {
        final isAdmin = roleAsync.valueOrNull == UserRole.admin;
        return _buildDashboardContent(context, user, isAdmin);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _buildErrorWidget(context, error),
    );
  }

  Widget _buildDashboardContent(BuildContext context, UserModel? user, bool isAdmin) {
    final tabActions = buildTabActions();

    return SafeArea(
      child: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          final s = _statusTabs[_tabController.index];
          return DashboardEnquiriesTab(
            key: ValueKey(s['value']),
            status: s['value']!,
            isAdmin: isAdmin,
            userId: user?.uid,
            searchQuery: _searchQuery,
            onClearSearch: _clearSearch,
            actions: tabActions,
            errorBuilder: _buildErrorWidget,
            onTabVisible: s['value'] == 'in_talks' ? _runAutomaticCleanup : null,
            headerSlivers: [
              SliverToBoxAdapter(
                child: DashboardWelcomePanel(
                  key: _heroKey,
                  user: user,
                  isAdmin: isAdmin,
                  onPriorityBucketTap: _jumpToTab,
                  onViewAnalytics: isAdmin ? widget.onNavigateToAnalytics : null,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: DashboardTabBarDelegate(
                  controller: _tabController,
                  labels: _tabLabels,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onClearSearch: _clearSearch,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Jump to the tab matching [bucket] key ('new', 'reminders', 'this_week').
  /// Legacy bucket `quote_sent` maps to the In Talks tab.
  void _jumpToTab(String bucket) {
    if (bucket == 'this_week') {
      // Navigate to Calendar shell tab if possible, else fall through to All
      if (widget.onNavigateToCalendar != null) {
        widget.onNavigateToCalendar!();
        return;
      }
    }
    final targetStatus = switch (bucket) {
      'new' => 'new',
      'reminders' => 'reminders',
      'quote_sent' => 'in_talks', // quote_sent folded into In Talks
      _ => 'new',
    };
    final idx = _statusTabs.indexWhere((t) => t['value'] == targetStatus);
    if (idx >= 0) _tabController.animateTo(idx);
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return ErrorState(message: 'Something went wrong', error: error);
  }
}
