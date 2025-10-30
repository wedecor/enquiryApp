import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart' as auth_provider;
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../shared/models/user_model.dart';
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
  // Simple in-memory cache to avoid refetching user names repeatedly
  final Map<String, String> _userNameCache = <String, String>{};
  // Use value keys that match Firestore (snake_case), plus display labels
  final List<Map<String, String>> _statusTabs = [
    {'label': 'All', 'value': 'All'},
    {'label': 'New', 'value': 'new'},
    {'label': 'In Talks', 'value': 'in_talks'},
    {'label': 'Quote Sent', 'value': 'quote_sent'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);

    // FCM registration is now handled automatically by FcmBootstrap
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
      appBar: AppBar(
        title: const Text('We Decor Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: true, // This will show the hamburger menu
        actions: [
          // Notifications will be added later
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(ref),
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTabs.map((s) => Tab(text: s['label']!)).toList(),
        ),
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
    return Column(
      children: [
        // Welcome and Statistics Section
        _buildWelcomeAndStats(user, isAdmin),

        // Enquiries Tab View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _statusTabs
                .map((s) => _buildEnquiriesTab(s['value']!, isAdmin, user?.uid))
                .toList(),
          ),
        ),
      ],
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
          // Welcome Section
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

          // Statistics Cards
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

        // Calculate statistics
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

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                totalEnquiries.toString(),
                Icons.inbox,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('New', newEnquiries.toString(), Icons.fiber_new, Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'In Talks',
                inProgressEnquiries.toString(),
                Icons.pending,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                completedEnquiries.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiriesTab(String status, bool isAdmin, String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEnquiriesStream(isAdmin, userId, status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final enquiries = snapshot.data?.docs ?? [];

        if (enquiries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'All' ? Icons.inbox : Icons.filter_list,
                  size: 64,
                  color: Colors.grey,
                ),
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

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: enquiries.length,
          itemBuilder: (context, index) {
            final enquiry = enquiries[index];
            final enquiryData = enquiry.data() as Map<String, dynamic>;
            final enquiryId = enquiry.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(enquiryData['eventStatus'] as String?),
                  child: Text(
                    _getStatusInitial(enquiryData['eventStatus'] as String?),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  (enquiryData['customerName'] as String?) ?? 'Unknown Customer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((enquiryData['eventType'] as String?) ?? 'Unknown Event'),
                    Text(
                      'Date: ${_formatDate(enquiryData['eventDate'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isAdmin && enquiryData['assignedTo'] != null) ...[
                      _buildAssignedToLabel(enquiryData['assignedTo'] as String),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(enquiryData['priority'] as String?),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _capitalizeFirst((enquiryData['priority'] as String?) ?? 'N/A'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if ((enquiryData['eventStatus'] as String?)?.toLowerCase() != 'confirmed') ...[
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        tooltip: 'Delete Enquiry',
                        onPressed: () {
                          _confirmAndDeleteEnquiry(
                            enquiryId,
                            (enquiryData['customerName'] as String?) ?? 'this enquiry',
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndDeleteEnquiry(String enquiryId, String customerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Enquiry'),
        content: Text('Are you sure you want to delete "$customerName"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('enquiries').doc(enquiryId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Enquiry deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Stream<QuerySnapshot> _getEnquiriesStream(bool isAdmin, String? userId, [String? status]) {
    Query query = FirebaseFirestore.instance.collection('enquiries');

    // Apply role-based filtering
    if (!isAdmin && userId != null) {
      query = query.where('assignedTo', isEqualTo: userId);
    }

    // Apply status filtering
    if (status != null && status != 'All') {
      query = query.where('eventStatus', isEqualTo: status);
    }

    // Sort: show oldest first for 'new' tab; otherwise newest first
    final bool descending = (status?.toLowerCase() == 'new') ? false : true;
    return query.orderBy('createdAt', descending: descending).snapshots();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _getStatusInitial(String? status) {
    if (status == null) return '?';
    return status.isEmpty ? '?' : status[0].toUpperCase();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'new':
        return Colors.orange;
      case 'in_talks':
        return Theme.of(context).colorScheme.primary;
      case 'quote_sent':
        return Theme.of(context).colorScheme.primary;
      case 'confirmed':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAssignedToLabel(String assignedUserId) {
    return FutureBuilder<String>(
      future: _getUserDisplayName(assignedUserId),
      builder: (context, snapshot) {
        final textStyle = TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 14,
            width: 100,
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        if (snapshot.hasError) {
          return Text('Assigned: Unknown', style: textStyle);
        }

        final display = snapshot.data ?? 'Unassigned';
        return Text('Assigned: $display', style: textStyle);
      },
    );
  }

  Future<String> _getUserDisplayName(String userId) async {
    // Return cached value if present
    final cached = _userNameCache[userId];
    if (cached != null) return cached;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!doc.exists) {
        _userNameCache[userId] = 'Unknown';
        return 'Unknown';
      }
      final data = doc.data() as Map<String, dynamic>?;
      final name = (data?['name'] as String?)?.trim();
      final phone = (data?['phone'] as String?)?.trim();
      final display = [name, phone].where((e) => e != null && e!.isNotEmpty).join(' · ');
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
      // Remove FCM token before signing out
      // FCM token cleanup is handled automatically by FcmBootstrap

      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.signOut();
    } catch (e) {
      // Error handling is done by the auth service
    }
  }

  Widget _buildNavigationDrawer(AsyncValue<UserModel?> currentUser, bool isAdmin) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Ultra-simple user header - NO COLUMN, NO OVERFLOW
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: currentUser.when(
              data: (user) => Row(
                children: [
                  const Icon(Icons.account_circle, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${user?.name ?? 'User'} (${isAdmin ? 'Admin' : 'Staff'})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (error, stack) =>
                  const Text('Error loading user', style: TextStyle(color: Colors.white)),
            ),
          ),

          // Navigation menu items
          _buildMenuItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Already on dashboard, no navigation needed
            },
          ),

          _buildMenuItem(
            icon: Icons.list,
            title: isAdmin ? 'All Enquiries' : 'My Enquiries',
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (context) => const EnquiriesListScreen()),
              );
            },
          ),

          _buildMenuItem(
            icon: Icons.add,
            title: 'New Enquiry',
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (context) => const EnquiryFormScreen()),
              );
            },
          ),

          // Admin-only menu items
          if (isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Admin Tools',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            _buildMenuItem(
              icon: Icons.people,
              title: 'User Management',
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (context) => const UserManagementScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Dropdown Management',
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (context) => const DropdownManagementScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.analytics,
              title: 'System Analytics',
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (context) => const AnalyticsScreen()),
                );
              },
            ),
          ],

          const Divider(),

          // Settings and logout
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(
                context,
              ).push<void>(MaterialPageRoute<void>(builder: (context) => const SettingsScreen()));
            },
          ),

          _buildMenuItem(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              _signOut(ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}
