import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../core/services/review_request_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../enquiries/data/enquiry_repository.dart';
import '../../../enquiries/domain/enquiry.dart';
import '../../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../../../core/theme/tokens.dart';
import '../widgets/dashboard_action_sheets.dart';
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
    with SingleTickerProviderStateMixin {
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

  late final List<Tab> _tabs;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _primeDropdownColors();
    _tabs = _statusTabs
        .map(
          (tab) => Tab(
            height: AppTokens.space10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
              child: Text(tab['label']!),
            ),
          ),
        )
        .toList(growable: false);
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
      cleanupService
          .runAutomaticCleanup(userId: userId)
          .then((updatedCount) {
            if (updatedCount != null && updatedCount > 0 && mounted) {
              // Optionally show a subtle notification
              Log.i('Automatic cleanup completed', data: {'updatedCount': updatedCount});
            }
          })
          .catchError((Object error, StackTrace stack) {
            Log.e('Automatic cleanup error', error: error, stackTrace: stack);
          });
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

  TabBar _buildStatusTabBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TabBar(
      controller: _tabController,
      tabs: _tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space1),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
      // Underline in the single brand accent — no pill-shaped indicator.
      indicator: UnderlineTabIndicator(borderSide: BorderSide(color: cs.tertiary, width: 2)),
      labelColor: cs.onSurface,
      unselectedLabelColor: cs.onSurfaceVariant,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppTokens.fontSizeBody),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: AppTokens.fontSizeBody,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final roleAsync = ref.watch(roleProvider);

    final body = currentUser.when(
      data: (user) {
        final isAdmin = roleAsync.valueOrNull == UserRole.admin;
        return _buildDashboardContent(context, user, isAdmin);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _buildErrorWidget(context, error),
    );

    // Always hosted inside AppShell, which owns the Scaffold, AppBar, nav and FAB.
    return body;
  }

  Widget _buildDashboardContent(BuildContext context, UserModel? user, bool isAdmin) {
    final tabBar = _buildStatusTabBar(context);
    final tabActions = DashboardEnquiryTabActions(
      onView: _openEnquiryDetails,
      onCall: _handleCall,
      onWhatsApp: _handleWhatsApp,
      onReminderWhatsApp: _handleReminderWhatsApp,
      onUpdateStatus: _showUpdateStatusSheet,
      onShare: _shareEnquiry,
      onAddNote: _showNotesSheet,
      onReviewRequest: _handleReviewRequest,
      onMarkNotInterested: _markAsNotInterested,
    );

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
            onClearSearch: () {
              _searchController.clear();
              _handleSearchChanged();
            },
            actions: tabActions,
            errorBuilder: _buildErrorWidget,
            onTabVisible: s['value'] == 'in_talks' ? _runAutomaticCleanup : null,
            headerSlivers: [
              SliverToBoxAdapter(child: _buildWelcomeAndStats(user, isAdmin)),
              SliverPersistentHeader(
                pinned: true,
                delegate: DashboardTabBarDelegate(
                  tabBar,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onClearSearch: () {
                    _searchController.clear();
                    _handleSearchChanged();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeAndStats(UserModel? user, bool isAdmin) {
    return DashboardWelcomePanel(
      user: user,
      isAdmin: isAdmin,
      onPriorityBucketTap: _jumpToTab,
      onViewAnalytics: isAdmin ? widget.onNavigateToAnalytics : null,
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

  Future<void> _handleCall(String? phone, String customerName, String enquiryId) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack('No phone number available for $customerName');
      return;
    }

    final launcher = ref.read(contactLauncherProvider);
    final status = await launcher.callNumberWithAudit(phone, enquiryId: enquiryId);

    switch (status) {
      case ContactLaunchStatus.opened:
        _showSnack('Dialer opened for $customerName');
        break;
      case ContactLaunchStatus.invalidNumber:
        _showSnack('Invalid phone number for $customerName');
        break;
      case ContactLaunchStatus.notInstalled:
        _showSnack('Phone dialer not available on this device');
        break;
      case ContactLaunchStatus.failed:
        _showSnack('Unable to start call to $customerName');
        break;
    }
  }

  Future<void> _handleWhatsApp(String? phone, String customerName, String enquiryId) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack('No phone number available for WhatsApp');
      return;
    }

    final launcher = ref.read(contactLauncherProvider);
    final prefill = 'Hi $customerName, this is from We Decor.';
    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: prefill,
      enquiryId: enquiryId,
    );

    switch (status) {
      case ContactLaunchStatus.opened:
        _showSnack('WhatsApp opened for $customerName');
        break;
      case ContactLaunchStatus.invalidNumber:
        _showSnack('Invalid WhatsApp number');
        break;
      case ContactLaunchStatus.notInstalled:
        _showSnack('WhatsApp is not installed on this device');
        break;
      case ContactLaunchStatus.failed:
        _showSnack('Unable to launch WhatsApp');
        break;
    }
  }

  Future<void> _handleReviewRequest(String phone, String customerName, String enquiryId) async {
    try {
      final reviewService = ref.read(reviewRequestServiceProvider);
      final appConfigAsync = ref.read(appGeneralConfigProvider);

      final appConfig = appConfigAsync.valueOrNull;
      if (appConfig == null) {
        _showSnack('Error loading app configuration');
        return;
      }

      final googleReviewLink = appConfig.googleReviewLink.isNotEmpty
          ? appConfig.googleReviewLink
          : null;
      final instagramHandle = appConfig.instagramHandle.isNotEmpty
          ? appConfig.instagramHandle
          : null;
      final websiteUrl = appConfig.websiteUrl.isNotEmpty ? appConfig.websiteUrl : null;

      final status = await reviewService.sendReviewRequest(
        customerPhone: phone,
        customerName: customerName,
        googleReviewLink: googleReviewLink,
        instagramHandle: instagramHandle,
        websiteUrl: websiteUrl,
        enquiryId: enquiryId,
      );

      if (!mounted) return;

      switch (status) {
        case ContactLaunchStatus.opened:
          _showSnack('Review request sent to $customerName');
          break;
        case ContactLaunchStatus.invalidNumber:
          _showSnack('Invalid phone number for review request');
          break;
        case ContactLaunchStatus.notInstalled:
          _showSnack('WhatsApp not installed. Opened in browser instead.');
          break;
        case ContactLaunchStatus.failed:
          _showSnack('Could not send review request');
          break;
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error sending review request: $e');
      }
    }
  }

  /// Mark enquiry as "not_interested" (for past events in In Talks tab)
  Future<void> _markAsNotInterested(String enquiryId, String userId) async {
    try {
      final repository = ref.read(enquiryRepositoryProvider);

      // Show confirmation dialog
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'Mark as Not Interested',
        message:
            'Mark this enquiry as "Not Interested"?\n\nThis will update the status and notify all admins.',
        confirmText: 'Mark as Not Interested',
        cancelText: 'Cancel',
        isDestructive: false,
        icon: Icons.block,
      );

      if (!confirmed || !mounted) return;

      await repository.updateStatus(id: enquiryId, nextStatus: 'not_interested', userId: userId);

      if (mounted) {
        _showSnack('Enquiry marked as Not Interested');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to update status: $e');
      }
    }
  }

  Future<void> _showUpdateStatusSheet(Enquiry enquiry) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => UpdateStatusSheet(enquiry: enquiry),
    );
  }

  Future<void> _shareEnquiry(Enquiry enquiry) async {
    final buffer = StringBuffer()
      ..writeln('Enquiry: ${enquiry.customerName}')
      ..writeln('Event: ${enquiry.eventTypeDisplay}')
      ..writeln('Status: ${enquiry.statusDisplay}')
      ..writeln('Event date: ${formatDateLabel(enquiry.eventDate)}')
      ..writeln('Assigned to: ${enquiry.assigneeName ?? 'Unassigned'}')
      ..writeln('Phone: ${enquiry.customerPhone ?? 'N/A'}')
      ..writeln(
        'Notes: ${enquiry.notes?.trim().isNotEmpty == true ? enquiry.notes!.trim() : 'N/A'}',
      );

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      _showSnack('Enquiry details copied to clipboard');
    }
  }

  Future<void> _showNotesSheet(Enquiry enquiry) async {
    if (!mounted) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FollowUpNotesSheet(initialNotes: enquiry.notes),
    );

    if (!mounted || result == null) return;

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      if (result.isEmpty) {
        await firestoreService.updateEnquiry(enquiry.id, {
          'notes': FieldValue.delete(),
          'description': FieldValue.delete(),
        });
        _showSnack('Notes cleared');
      } else {
        await firestoreService.updateEnquiry(enquiry.id, {'notes': result, 'description': result});
        _showSnack('Notes updated');
      }
    } catch (e) {
      _showSnack('Failed to update notes');
    }
  }

  void _openEnquiryDetails(String enquiryId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId)),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Handle reminder WhatsApp click - increments count and opens WhatsApp
  Future<void> _handleReminderWhatsApp(
    String phone,
    String customerName,
    String enquiryId,
    String eventType,
    DateTime createdAt,
    DateTime? eventDate,
  ) async {
    if (phone.trim().isEmpty) {
      _showSnack('No phone number available for WhatsApp');
      return;
    }

    // Increment reminder count
    try {
      await ref.read(firestoreServiceProvider).updateEnquiry(enquiryId, {
        'reminderClickCount': FieldValue.increment(1),
        'lastReminderSentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Log.e('Failed to increment reminder count', error: e);
      // Continue even if count update fails
    }

    // Build and send reminder message
    final launcher = ref.read(contactLauncherProvider);
    final prefill = buildReminderMessage(customerName, eventType, createdAt, eventDate);
    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: prefill,
      enquiryId: enquiryId,
    );

    switch (status) {
      case ContactLaunchStatus.opened:
        _showSnack('Reminder sent to $customerName via WhatsApp');
        break;
      case ContactLaunchStatus.invalidNumber:
        _showSnack('Invalid WhatsApp number');
        break;
      case ContactLaunchStatus.notInstalled:
        _showSnack('WhatsApp is not installed on this device');
        break;
      case ContactLaunchStatus.failed:
        _showSnack('Unable to launch WhatsApp');
        break;
    }
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return ErrorState(message: 'Something went wrong', error: error);
  }
}
