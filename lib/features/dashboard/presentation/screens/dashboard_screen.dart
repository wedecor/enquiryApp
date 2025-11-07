import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart' as auth_provider;
import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/components/stats_card.dart';
import '../../../../widgets/enquiry_tile_status_strip.dart';
import '../../../admin/analytics/presentation/analytics_screen.dart';
import '../../../admin/dropdowns/presentation/dropdown_management_screen.dart';
import '../../../admin/users/presentation/user_management_screen.dart';
import '../../../enquiries/presentation/screens/enquiries_list_screen.dart';
import '../../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../../enquiries/presentation/screens/enquiry_form_screen.dart';
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
  final Map<String, String> _userNameCache = <String, String>{};
  final Map<String, Color> _statusColorCache = <String, Color>{};
  final Map<String, Color> _eventColorCache = <String, Color>{};
  final List<Map<String, String>> _statusTabs = [
    {'label': 'All', 'value': 'All'},
    {'label': 'New', 'value': 'new'},
    {'label': 'In Talks', 'value': 'in_talks'},
    {'label': 'Quote Sent', 'value': 'quote_sent'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  late final List<Tab> _tabs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _primeDropdownColors();
    _tabs = _statusTabs
        .map((tab) => Tab(text: tab['label']!))
        .toList(growable: false);
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
      if (kDebugMode) {
        debugPrint('Failed to load dropdown colors: $e');
        debugPrint('$st');
      }
    }

    if (mounted) setState(() {});

    if (kDebugMode) {
      debugPrint(
        '[DropdownCaches] statuses=${_statusColorCache.map((k, v) => MapEntry(k, v.value.toRadixString(16)))} '
        'events=${_eventColorCache.map((k, v) => MapEntry(k, v.value.toRadixString(16)))}',
      );
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
      final alpha = rawAlpha != null
          ? (double.tryParse(rawAlpha) ?? 1).clamp(0.0, 1.0)
          : 1.0;
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(auth_provider.firebaseAuthUserProvider);
    final currentUser = ref.watch(auth_provider.currentUserAsyncProvider);
    final isAdmin = ref.watch(auth_provider.isAdminProvider);

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
      drawer: _buildNavigationDrawer(currentUser, isAdmin),
      body: authUser.when(
        data: (user) {
          if (user != null) {
            return currentUser.when(
              data: (user) => _buildDashboardContent(context, user, isAdmin),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(context, error),
            );
          } else {
            return const Center(child: Text('Authentication required'));
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(context, error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => const EnquiryFormScreen(),
            ),
          );
        },
        tooltip: 'Add New Enquiry',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    UserModel? user,
    bool isAdmin,
  ) {
    final tabBar = TabBar(
      controller: _tabController,
      tabs: _tabs,
      isScrollable: true,
    );

    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _buildWelcomeAndStats(user, isAdmin),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabBar),
          ),
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
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
          StatsCard(
            icon: Icons.fiber_new,
            value: newEnquiries.toString(),
            label: 'New',
          ),
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
      stream: _getEnquiriesStream(
        isAdmin,
        userId,
        status == 'All' ? null : status,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error!);
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawEnquiries = snapshot.data!.docs.toList();

        if (rawEnquiries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'All'
                      ? 'No enquiries found'
                      : 'No $status enquiries',
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

        rawEnquiries.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate =
              _parseDateTime(aData['eventDate']) ??
              _parseDateTime(aData['createdAt']) ??
              DateTime(9999);
          final bDate =
              _parseDateTime(bData['eventDate']) ??
              _parseDateTime(bData['createdAt']) ??
              DateTime(9999);
          return aDate.compareTo(bDate);
        });

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: rawEnquiries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final enquiry = rawEnquiries[index];
            final enquiryData = enquiry.data() as Map<String, dynamic>;
            final enquiryId = enquiry.id;
            final customerName =
                (enquiryData['customerName'] as String?) ?? 'Customer';
            final phone = enquiryData['customerPhone'] as String?;
            final assignedUserId = enquiryData['assignedTo'] as String?;

            return FutureBuilder<String>(
              future: assignedUserId != null
                  ? _getUserDisplayName(assignedUserId)
                  : Future.value('Unassigned'),
              builder: (context, snapshot) {
                final assignedDisplay = assignedUserId == null
                    ? 'Unassigned'
                    : snapshot.connectionState == ConnectionState.waiting
                    ? 'Fetching assignee…'
                    : snapshot.hasError
                    ? 'Unknown'
                    : snapshot.data ?? 'Unassigned';

                final createdAt =
                    _parseDateTime(enquiryData['createdAt']) ?? DateTime.now();
                final eventDate = _parseDateTime(enquiryData['eventDate']);
                final location =
                    (enquiryData['eventLocation'] as String?) ??
                    (enquiryData['location'] as String?);
                final notes =
                    (enquiryData['description'] as String?) ??
                    (enquiryData['notes'] as String?);

                final status =
                    (enquiryData['eventStatus'] as String?)
                            ?.trim()
                            .isNotEmpty ==
                        true
                    ? enquiryData['eventStatus'] as String
                    : 'New';
                final eventType =
                    (enquiryData['eventType'] as String?)?.trim().isNotEmpty ==
                        true
                    ? enquiryData['eventType'] as String
                    : 'Event';
                final whatsappContact =
                    enquiryData['whatsappNumber'] as String? ?? phone;
                final statusColorHex =
                    (enquiryData['statusColorHex'] as String?) ??
                    (enquiryData['statusColor'] as String?);
                final eventColorHex =
                    (enquiryData['eventColorHex'] as String?) ??
                    (enquiryData['eventColor'] as String?);
                final statusColorOverride =
                    _colorFromDynamic(enquiryData['statusColorValue']) ??
                    _colorFromDynamic(enquiryData['statusColorInt']) ??
                    _colorFromDynamic(statusColorHex) ??
                    _colorFromDynamic(enquiryData['statusColor']) ??
                    _statusColorCache[status.toLowerCase()];
                final eventColorOverride =
                    _colorFromDynamic(enquiryData['eventColorValue']) ??
                    _colorFromDynamic(enquiryData['eventColorInt']) ??
                    _colorFromDynamic(eventColorHex) ??
                    _colorFromDynamic(enquiryData['eventColor']) ??
                    _eventColorCache[eventType.toLowerCase()];
                if (kDebugMode) {
                  debugPrint(
                    '[EnquiryData] id=$enquiryId '
                    "eventType=${enquiryData['eventType']} "
                    "status=${enquiryData['eventStatus']} "
                    'keys=${enquiryData.keys} '
                    'colors: statusHex=$statusColorHex eventHex=$eventColorHex '
                    'statusOverride=${statusColorOverride?.value.toRadixString(16)} '
                    'eventOverride=${eventColorOverride?.value.toRadixString(16)} '
                    "rawStatusColor=${enquiryData['statusColor']} "
                    "rawEventColor=${enquiryData['eventColor']}",
                  );
                }

                return EnquiryTileStatusStrip(
                  name: customerName,
                  status: status,
                  eventType: eventType,
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
                  onCall: phone == null
                      ? null
                      : () => _handleCall(phone, customerName, enquiryId),
                  onWhatsApp: whatsappContact == null
                      ? null
                      : () => _handleWhatsApp(
                          whatsappContact,
                          customerName,
                          enquiryId,
                        ),
                );
              },
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

  Future<void> _handleCall(
    String? phone,
    String customerName,
    String enquiryId,
  ) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack('No phone number available for $customerName');
      return;
    }

    final launcher = ref.read(contactLauncherProvider);
    final status = await launcher.callNumberWithAudit(
      phone,
      enquiryId: enquiryId,
    );

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

  Future<void> _handleWhatsApp(
    String? phone,
    String customerName,
    String enquiryId,
  ) async {
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

  void _openEnquiryDetails(String enquiryId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId),
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Stream<QuerySnapshot> _getEnquiriesStream(
    bool isAdmin,
    String? userId, [
    String? status,
  ]) {
    Query query = FirebaseFirestore.instance.collection('enquiries');

    if (!isAdmin && userId != null) {
      query = query.where('assignedTo', isEqualTo: userId);
    }

    if (status != null && status != 'All') {
      query = query.where('eventStatus', isEqualTo: status);
    }

    final bool descending = (status?.toLowerCase() == 'new') ? false : true;
    return query.orderBy('createdAt', descending: descending).snapshots();
  }

  Future<String> _getUserDisplayName(String userId) async {
    final cached = _userNameCache[userId];
    if (cached != null) return cached;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!doc.exists) {
        _userNameCache[userId] = 'Unknown';
        return 'Unknown';
      }
      final data = doc.data();
      final name = (data?['name'] as String?)?.trim();
      final phone = (data?['phone'] as String?)?.trim();
      final display = [
        name,
        phone,
      ].where((e) => e != null && e.isNotEmpty).join(' · ');
      final result = display.isNotEmpty ? display : 'Unknown';
      _userNameCache[userId] = result;
      return result;
    } catch (_) {
      return 'Unknown';
    }
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

  Drawer _buildNavigationDrawer(
    AsyncValue<UserModel?> currentUser,
    bool isAdmin,
  ) {
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EnquiriesListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.add_circle_outline,
                    label: 'Add Enquiry',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EnquiryFormScreen(),
                        ),
                      );
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
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      icon: Icons.bar_chart_outlined,
                      label: 'Analytics',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      icon: Icons.tune,
                      label: 'Dropdowns',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const DropdownManagementScreen(),
                          ),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
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
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
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
                (user?.name.isNotEmpty == true ? user!.name[0] : 'U')
                    .toUpperCase(),
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (error, stack) => const Text(
          'Error loading user',
          style: TextStyle(color: Colors.white),
        ),
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
    final color = danger
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withOpacity(0.85);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
      ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      child: _tabBar,
    );
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
