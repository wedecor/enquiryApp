import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../core/services/review_request_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../enquiries/data/enquiry_repository.dart';
import '../../../enquiries/domain/enquiry.dart';
import '../../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../../enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../../enquiries/presentation/widgets/status_inline_control.dart';
import '../../../settings/providers/settings_providers.dart';
import '../widgets/dashboard_enquiries_tab.dart';
import '../widgets/dashboard_enquiry_utils.dart';
import '../widgets/dashboard_navigation_drawer.dart';
import '../widgets/dashboard_statistics_section.dart';
import '../widgets/dashboard_tab_bar_delegate.dart';
import '../widgets/dashboard_welcome_panel.dart';

/// Enhanced Dashboard Screen with tabs and statistics
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.embeddedInShell = false, this.onNavigateToCalendar});

  /// When true, renders body only (no [Scaffold]); used inside [AppShell].
  final bool embeddedInShell;

  /// Called when the user taps the "this week" priority bucket, requesting
  /// the shell to switch to the Calendar tab.
  final VoidCallback? onNavigateToCalendar;

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
    {'label': 'Confirmed', 'value': 'confirmed'},
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
    _tabs = _statusTabs.map((tab) => Tab(text: tab['label']!)).toList(growable: false);
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final roleAsync = ref.watch(roleProvider);

    final body = currentUser.when(
      data: (user) => roleAsync.when(
        data: (role) => _buildDashboardContent(context, user, role == UserRole.admin),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildDashboardContent(context, user, false),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _buildErrorWidget(context, error),
    );

    if (widget.embeddedInShell) {
      return body;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('We Decor Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(ref),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      drawer: roleAsync.when(
        data: (role) => DashboardNavigationDrawer(isAdmin: role == UserRole.admin),
        loading: () => const DashboardNavigationDrawer(isAdmin: false),
        error: (_, __) => const DashboardNavigationDrawer(isAdmin: false),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push<void>(MaterialPageRoute<void>(builder: (context) => const EnquiryFormScreen()));
        },
        tooltip: 'Add New Enquiry',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, UserModel? user, bool isAdmin) {
    final tabBar = TabBar(controller: _tabController, tabs: _tabs, isScrollable: true);
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
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildWelcomeAndStats(user, isAdmin)),
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverPersistentHeader(
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
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _statusTabs
              .map(
                (s) => DashboardEnquiriesTab(
                  status: s['value']!,
                  isAdmin: isAdmin,
                  userId: user?.uid,
                  searchQuery: _searchQuery,
                  onClearSearch: () {
                    _searchController.clear();
                    _handleSearchChanged();
                  },
                  statusColorCache: _statusColorCache,
                  eventColorCache: _eventColorCache,
                  actions: tabActions,
                  errorBuilder: _buildErrorWidget,
                  onTabVisible: s['value'] == 'in_talks' ? _runAutomaticCleanup : null,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWelcomeAndStats(UserModel? user, bool isAdmin) {
    return DashboardWelcomePanel(
      user: user,
      isAdmin: isAdmin,
      statsChild: DashboardStatisticsSection(isAdmin: isAdmin, userId: user?.uid),
      onPriorityBucketTap: _jumpToTab,
    );
  }

  /// Jump to the tab matching [bucket] key ('new', 'reminders', 'this_week', 'quote_sent').
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
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              StatusInlineControl(enquiry: enquiry),
              const SizedBox(height: 12),
              Text(
                'Changes are saved automatically.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
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
    final controller = TextEditingController(text: enquiry.notes ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + viewInsets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Follow-up notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Add any internal notes or follow-up reminders',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel'),
                      ),
                      if (hasText)
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(''),
                          child: const Text('Clear'),
                        ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(value.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();

    if (!mounted || result == null) return;

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      if (result.isEmpty) {
        await firestoreService.updateEnquiry(enquiry.id, {'notes': FieldValue.delete()});
        _showSnack('Notes cleared');
      } else {
        await firestoreService.updateEnquiry(enquiry.id, {'notes': result});
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(WidgetRef ref) async {
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.signOut();
    } catch (e) {
      // handled by auth service
    }
  }
}
