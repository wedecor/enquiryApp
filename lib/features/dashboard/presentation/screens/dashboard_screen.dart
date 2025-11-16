import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../core/services/review_request_service.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../ui/components/stats_card.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/enquiry_tile_status_strip.dart';
import '../../../admin/analytics/presentation/analytics_screen.dart';
import '../../../admin/dropdowns/presentation/dropdown_management_screen.dart';
import '../../../admin/users/presentation/user_management_screen.dart';
import '../../../admin/users/presentation/users_providers.dart' as users_providers;
import '../../../enquiries/domain/enquiry.dart';
import '../../../enquiries/presentation/screens/enquiries_list_screen.dart';
import '../../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../../enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../../enquiries/presentation/widgets/status_inline_control.dart';
import '../../../settings/presentation/settings_screen.dart';

/// Enhanced Dashboard Screen with tabs and statistics
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, Color> _statusColorCache = <String, Color>{};
  final Map<String, Color> _eventColorCache = <String, Color>{};
  final List<Map<String, String>> _statusTabs = [
    {'label': 'All', 'value': 'All'},
    {'label': 'New', 'value': 'new'},
    {'label': 'In Talks', 'value': 'in_talks'},
    {'label': 'Quote Sent', 'value': 'quote_sent'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Not Interested', 'value': 'not_interested'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
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
    final firestore = FirebaseFirestore.instance;
    try {
      final statusSnapshot = await firestore
          .collection('dropdowns')
          .doc('statuses')
          .collection('items')
          .where('active', isEqualTo: true)
          .get();
      for (final doc in statusSnapshot.docs) {
        final data = doc.data();
        final value = (data['value'] as String?)?.trim();
        final colorHex = data['color'] as String?;
        if (value == null || value.isEmpty || colorHex == null) continue;
        final color = _parseColor(colorHex);
        if (color != null) {
          _statusColorCache[value.toLowerCase()] = color;
        }
      }

      final eventSnapshot = await firestore
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .where('active', isEqualTo: true)
          .get();
      for (final doc in eventSnapshot.docs) {
        final data = doc.data();
        final value = (data['value'] as String?)?.trim();
        final colorHex = data['color'] as String?;
        if (value == null || value.isEmpty || colorHex == null) continue;
        final color = _parseColor(colorHex);
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

  Color? _parseColor(String? input) {
    if (input == null) return null;
    var s = input.trim();
    if (s.isEmpty) return null;

    final rgbRe = RegExp(
      r'^rgba?\s*\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*([0-1]?\.?\d+))?\s*\)$',
      caseSensitive: false,
    );
    final match = rgbRe.firstMatch(s);
    if (match != null) {
      int clampChannel(String v) => int.parse(v).clamp(0, 255);
      final r = clampChannel(match.group(1)!);
      final g = clampChannel(match.group(2)!);
      final b = clampChannel(match.group(3)!);
      final rawAlpha = match.group(4);
      final alpha = rawAlpha != null ? (double.tryParse(rawAlpha) ?? 1).clamp(0.0, 1.0) : 1.0;
      return Color.fromRGBO(r, g, b, alpha);
    }

    s = s.replaceAll('#', '').trim();
    if (s.startsWith('0x')) {
      try {
        var value = int.parse(s);
        if (value <= 0xFFFFFF) value = 0xFF000000 | value;
        return Color(value);
      } catch (_) {}
    }

    final hexRe = RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$');
    if (hexRe.hasMatch(s)) {
      if (s.length == 6) {
        return Color(int.parse('0xFF${s.toUpperCase()}'));
      }
      if (s.length == 8) {
        final rr = s.substring(0, 2).toUpperCase();
        final gg = s.substring(2, 4).toUpperCase();
        final bb = s.substring(4, 6).toUpperCase();
        final aa = s.substring(6, 8).toUpperCase();
        return Color(int.parse('0x$aa$rr$gg$bb'));
      }
    }

    try {
      final value = int.parse(s);
      return Color(value <= 0xFFFFFF ? (0xFF000000 | value) : value);
    } catch (_) {
      return null;
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
        data: (role) => _buildNavigationDrawer(role == UserRole.admin),
        loading: () => _buildNavigationDrawer(false), // Show non-admin drawer while loading
        error: (_, __) => _buildNavigationDrawer(false),
      ),
      body: currentUser.when(
        data: (user) => roleAsync.when(
          data: (role) => _buildDashboardContent(context, user, role == UserRole.admin),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildDashboardContent(context, user, false),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => _buildErrorWidget(context, error),
      ),
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

    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildWelcomeAndStats(user, isAdmin)),
          SliverPersistentHeader(pinned: true, delegate: _TabBarDelegate(tabBar)),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _statusTabs
              .map((s) => _buildEnquiriesTab(s['value']!, isAdmin, user?.uid))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWelcomeAndStats(UserModel? user, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user?.name ?? 'User'}!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isAdmin ? 'Administrator' : 'Staff Member',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatisticsCards(isAdmin, user?.uid),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or phone number',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _handleSearchChanged();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            ),
            textInputAction: TextInputAction.search,
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Filtering results for "$_searchQuery"',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(bool isAdmin, String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEnquiriesStream(isAdmin, userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading statistics');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final enquiries = snapshot.data?.docs ?? [];

        final totalEnquiries = enquiries.length;
        final newEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['eventStatus'] as String?)?.toLowerCase() == 'new';
        }).length;
        final inProgressEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['eventStatus'] as String?)?.toLowerCase() == 'in_talks';
        }).length;
        final completedEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['eventStatus'] as String?)?.toLowerCase() == 'completed';
        }).length;

        final cards = [
          StatsCard(
            icon: Icons.inbox_outlined,
            value: totalEnquiries.toString(),
            label: 'Total enquiries',
          ),
          StatsCard(icon: Icons.fiber_new, value: newEnquiries.toString(), label: 'New'),
          StatsCard(
            icon: Icons.handshake_outlined,
            value: inProgressEnquiries.toString(),
            label: 'In talks',
          ),
          StatsCard(
            icon: Icons.verified_outlined,
            value: completedEnquiries.toString(),
            label: 'Completed',
          ),
        ];

        return DashboardKpiRow(items: cards);
      },
    );
  }

  Widget _buildEnquiriesTab(String status, bool isAdmin, String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEnquiriesStream(isAdmin, userId, status == 'All' ? null : status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error!);
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawEnquiries = snapshot.data!.docs.toList();

        if (rawEnquiries.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return SearchEmptyState(
              query: _searchQuery,
              onClearSearch: () {
                _searchController.clear();
                _handleSearchChanged();
              },
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  status == 'All' ? 'No enquiries found' : 'No $status enquiries',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create a new enquiry',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        rawEnquiries.sort((a, b) => _compareByNearestEventDate(a, b, now));

        final filteredEnquiries = _searchQuery.isEmpty
            ? rawEnquiries
            : rawEnquiries
                  .where((doc) => _matchesSearchQuery(doc.data() as Map<String, dynamic>))
                  .toList(growable: false);

        if (_searchQuery.isNotEmpty && filteredEnquiries.isEmpty) {
          return SearchEmptyState(
            query: _searchQuery,
            onClearSearch: () {
              _searchController.clear();
              _handleSearchChanged();
            },
          );
        }

        final dropdownLookup = ref
            .watch(dropdownLookupProvider)
            .maybeWhen(data: (value) => value, orElse: () => null);

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredEnquiries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final enquiry = filteredEnquiries[index];
            final enquiryData = enquiry.data() as Map<String, dynamic>;
            final enquiryId = enquiry.id;
            final enquiryModel = Enquiry.fromFirestore(enquiry);
            final customerName = (enquiryData['customerName'] as String?) ?? 'Customer';
            final phone = enquiryData['customerPhone'] as String?;
            final assignedUserId = enquiryData['assignedTo'] as String?;

            final assignedDisplayAsync = assignedUserId == null
                ? const AsyncValue.data('Unassigned')
                : ref.watch(users_providers.userDisplayNameProvider(assignedUserId));

            final assignedDisplay = assignedUserId == null
                ? 'Unassigned'
                : assignedDisplayAsync.when(
                    data: (value) => value,
                    loading: () => 'Fetching assignee…',
                    error: (_, __) => 'Unknown',
                  );

            final createdAt = _parseDateTime(enquiryData['createdAt']) ?? DateTime.now();
            final eventDate = _parseDateTime(enquiryData['eventDate']);
            final location =
                (enquiryData['eventLocation'] as String?) ?? (enquiryData['location'] as String?);
            final notes =
                (enquiryData['description'] as String?) ?? (enquiryData['notes'] as String?);

            final statusValueRaw =
                (enquiryData['statusValue'] ?? enquiryData['eventStatus']) as String?;
            final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
                ? statusValueRaw!.trim()
                : 'new';
            final statusLabel =
                (enquiryData['statusLabel'] as String?) ??
                (dropdownLookup != null
                    ? dropdownLookup.labelForStatus(statusValue)
                    : DropdownLookup.titleCase(statusValue));
            final eventTypeValueRaw =
                (enquiryData['eventTypeValue'] ?? enquiryData['eventType']) as String?;
            final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
                ? eventTypeValueRaw!.trim()
                : 'event';
            final eventTypeLabel =
                (enquiryData['eventTypeLabel'] as String?) ??
                (dropdownLookup != null
                    ? dropdownLookup.labelForEventType(eventTypeValue)
                    : DropdownLookup.titleCase(eventTypeValue));
            final whatsappContact = enquiryData['whatsappNumber'] as String? ?? phone;
            final eventCountdownLabel = _formatEventCountdownLabel(eventDate);
            final statusColorHex =
                (enquiryData['statusColorHex'] as String?) ??
                (enquiryData['statusColor'] as String?);
            final eventColorHex =
                (enquiryData['eventColorHex'] as String?) ?? (enquiryData['eventColor'] as String?);
            final statusColorOverride =
                _colorFromDynamic(enquiryData['statusColorValue']) ??
                _colorFromDynamic(enquiryData['statusColorInt']) ??
                _colorFromDynamic(statusColorHex) ??
                _colorFromDynamic(enquiryData['statusColor']) ??
                _statusColorCache[statusValue.toLowerCase()];
            final eventColorOverride =
                _colorFromDynamic(enquiryData['eventColorValue']) ??
                _colorFromDynamic(enquiryData['eventColorInt']) ??
                _colorFromDynamic(eventColorHex) ??
                _colorFromDynamic(enquiryData['eventColor']) ??
                _eventColorCache[eventTypeValue.toLowerCase()];
            if (kDebugMode) {
              Log.d(
                'Enquiry tile data snapshot',
                data: {
                  'enquiryId': enquiryId,
                  'status': statusValue,
                  'eventType': eventTypeValue,
                  'hasStatusColor': statusColorHex != null || statusColorOverride != null,
                  'hasEventColor': eventColorHex != null || eventColorOverride != null,
                },
              );
            }

            return EnquiryTileStatusStrip(
              name: customerName,
              status: statusLabel,
              eventType: eventTypeLabel,
              eventCountdownLabel: eventCountdownLabel,
              ageLabel: _formatAgeLabel(createdAt),
              assignee: assignedDisplay,
              dateLabel: _formatDateLabel(eventDate),
              location: location,
              notes: notes,
              phoneNumber: phone,
              whatsappNumber: whatsappContact,
              statusColorHex: statusColorHex,
              eventColorHex: eventColorHex,
              statusColorOverride: statusColorOverride,
              eventColorOverride: eventColorOverride,
              whatsappPrefill: 'Hi $customerName, this is from We Decor.',
              onView: () => _openEnquiryDetails(enquiryId),
              enquiryId: enquiryId,
              onCall: phone == null ? null : () => _handleCall(phone, customerName, enquiryId),
              onWhatsApp: whatsappContact == null
                  ? null
                  : () => _handleWhatsApp(whatsappContact, customerName, enquiryId),
              onUpdateStatus: () => _showUpdateStatusSheet(enquiryModel),
              onShare: () => _shareEnquiry(enquiryModel),
              onAddNote: () => _showNotesSheet(enquiryModel),
              onRequestReview: statusValue.toLowerCase() == 'completed' && phone != null
                  ? () => _handleReviewRequest(phone!, customerName, enquiryId)
                  : null,
            );
          },
        );
      },
    );
  }

  String _formatAgeLabel(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m old';
    if (age.inHours < 24) return '${age.inHours}h old';
    if (age.inDays < 7) return '${age.inDays}d old';
    final weeks = age.inDays ~/ 7;
    if (weeks < 5) return '${weeks}w old';
    final months = age.inDays ~/ 30;
    if (months < 12) return '${months}mo old';
    final years = age.inDays ~/ 365;
    return '${years}y old';
  }

  String _formatDateLabel(DateTime? date) {
    if (date == null) return 'Date TBC';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String? _formatEventCountdownLabel(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final days = eventDay.difference(today).inDays;

    if (days > 1) return 'In $days days';
    if (days == 1) return 'Tomorrow';
    if (days == 0) return 'Today';
    if (days == -1) return 'Yesterday';
    return '${days.abs()} days ago';
  }

  Color? _colorFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Color) return value;
    if (value is int) {
      final normalized = value <= 0xFFFFFF ? 0xFF000000 | value : value;
      return Color(normalized);
    }
    if (value is String) {
      return _parseColor(value);
    }
    return null;
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
      ..writeln('Event date: ${_formatDateLabel(enquiry.eventDate)}')
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
      final doc = FirebaseFirestore.instance.collection('enquiries').doc(enquiry.id);
      if (result.isEmpty) {
        await doc.update({'notes': FieldValue.delete()});
        _showSnack('Notes cleared');
      } else {
        await doc.update({'notes': result});
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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  int _compareByNearestEventDate(
    QueryDocumentSnapshot<Object?> a,
    QueryDocumentSnapshot<Object?> b,
    DateTime now,
  ) {
    const int maxDiffMagnitude = 1 << 62;

    final aData = a.data() as Map<String, dynamic>;
    final bData = b.data() as Map<String, dynamic>;

    final aEvent = _parseDateTime(aData['eventDate']);
    final bEvent = _parseDateTime(bData['eventDate']);

    final aDiff = aEvent?.difference(now);
    final bDiff = bEvent?.difference(now);

    final aIsFuture = aDiff != null && !aDiff.isNegative;
    final bIsFuture = bDiff != null && !bDiff.isNegative;

    if (aIsFuture != bIsFuture) {
      // Prioritise upcoming events over past ones.
      return aIsFuture ? -1 : 1;
    }

    final aMagnitude = aDiff != null ? aDiff.inMilliseconds.abs() : maxDiffMagnitude;
    final bMagnitude = bDiff != null ? bDiff.inMilliseconds.abs() : maxDiffMagnitude;

    final magnitudeComparison = aMagnitude.compareTo(bMagnitude);
    if (magnitudeComparison != 0) {
      return magnitudeComparison;
    }

    if (aEvent != null && bEvent != null) {
      final eventComparison = aEvent.compareTo(bEvent);
      if (eventComparison != 0) {
        return eventComparison;
      }
    } else if (aEvent == null && bEvent != null) {
      return 1;
    } else if (aEvent != null && bEvent == null) {
      return -1;
    }

    final aCreated = _parseDateTime(aData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreated = _parseDateTime(bData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bCreated.compareTo(aCreated);
  }

  bool _matchesSearchQuery(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.trim();
    final queryLower = query.toLowerCase();

    if (queryLower.isNotEmpty) {
      final lowerFields = <String>[
        (data['customerName'] as String? ?? '').toLowerCase(),
        (data['customerNameLower'] as String? ?? '').toLowerCase(),
        (data['textIndex'] as String? ?? '').toLowerCase(),
      ];
      if (lowerFields.any((field) => field.contains(queryLower))) {
        return true;
      }
    }

    final digitQuery = query.replaceAll(RegExp(r'\D'), '');
    if (digitQuery.isEmpty) {
      return false;
    }

    bool matchesDigits(String? input) {
      if (input == null || input.isEmpty) return false;
      final cleaned = input.replaceAll(RegExp(r'\D'), '');
      return cleaned.contains(digitQuery);
    }

    return matchesDigits(data['customerPhone'] as String?) ||
        matchesDigits(data['whatsappNumber'] as String?) ||
        matchesDigits(data['phoneNormalized'] as String?);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Stream<QuerySnapshot> _getEnquiriesStream(bool isAdmin, String? userId, [String? status]) {
    Query query = FirebaseFirestore.instance.collection('enquiries');

    if (!isAdmin && userId != null) {
      query = query.where('assignedTo', isEqualTo: userId);
    }

    if (_searchQuery.isEmpty && status != null && status != 'All') {
      query = query.where('eventStatus', isEqualTo: status);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.grey),
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

  Drawer _buildNavigationDrawer(bool isAdmin) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrawerHeader(currentUser, isAdmin),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerSectionLabel('Overview'),
                  _buildDrawerTile(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.list_alt_outlined,
                    label: 'All Enquiries',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (context) => const EnquiriesListScreen()));
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.add_circle_outline,
                    label: 'Add Enquiry',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (context) => const EnquiryFormScreen()));
                    },
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    _buildDrawerSectionLabel('Admin Tools'),
                    _buildDrawerTile(
                      icon: Icons.people_outline,
                      label: 'User Management',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      icon: Icons.bar_chart_outlined,
                      label: 'Analytics',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                      },
                    ),
                    _buildDrawerTile(
                      icon: Icons.tune,
                      label: 'Dropdowns',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const DropdownManagementScreen()),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildDrawerSectionLabel('Preferences'),
                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            _buildDrawerTile(
              icon: Icons.logout,
              label: 'Sign out',
              danger: true,
              onTap: () async {
                Navigator.pop(context);
                await _signOut(ref);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(AsyncValue<UserModel?> currentUser, bool isAdmin) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: currentUser.when(
        data: (user) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAdmin ? 'Administrator' : 'Team Member',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (error, stack) =>
            const Text('Error loading user', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDrawerSectionLabel(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final theme = Theme.of(context);
    final color = danger ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.85);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
      onTap: onTap,
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(elevation: overlapsContent ? 2 : 0, child: _tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}

class DashboardKpiRow extends StatelessWidget {
  const DashboardKpiRow({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;

    if (width >= 1024) {
      crossAxisCount = 4;
      childAspectRatio = 3.2;
    } else if (width >= 720) {
      crossAxisCount = 3;
      childAspectRatio = 2.8;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 2.2;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: items,
    );
  }
}
