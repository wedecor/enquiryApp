import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  Future<void> _approveUser(BuildContext context, String uid) async {
    final role = await showDialog<String>(
      context: context,
      builder: (context) {
        String selected = 'partner';
        return AlertDialog(
          title: const Text('Approve User'),
          content: DropdownButtonFormField<String>(
            value: selected,
            items: const [
              DropdownMenuItem(value: 'partner', child: Text('Partner')),
              DropdownMenuItem(value: 'staff', child: Text('Staff')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) => selected = v ?? 'partner',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Approve')),
          ],
        );
      },
    );
    if (role == null) return;
    
    // Demo message - replace with real Firebase call
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demo: User $uid approved as $role')));
    }
  }

  Future<void> _deactivateUser(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: const Text('Are you sure you want to deactivate this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (ok != true) return;
    
    // Demo message - replace with real Firebase call
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demo: User $uid deactivated')));
    }
  }

  Future<void> _makeAdmin(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Admin'),
        content: const Text('Grant admin role to this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    
    // Demo message - replace with real Firebase call
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demo: User $uid is now admin')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for demo
    final mockUsers = [
      {
        'id': '1',
        'email': 'demo@example.com',
        'displayName': 'Demo User',
        'role': 'pending',
        'isApproved': false,
        'isActive': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '2',
        'email': 'admin@wedecorevents.com',
        'displayName': 'Admin User',
        'role': 'admin',
        'isApproved': true,
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      },
      {
        'id': '3',
        'email': 'partner@example.com',
        'displayName': 'Partner User',
        'role': 'partner',
        'isApproved': true,
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      },
      {
        'id': '4',
        'email': 'staff@example.com',
        'displayName': 'Staff Member',
        'role': 'staff',
        'isApproved': true,
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
      },
      {
        'id': '5',
        'email': 'newuser@example.com',
        'displayName': 'New User',
        'role': 'pending',
        'isApproved': false,
        'isActive': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
    ];

    // Group users by role
    final pendingUsers = mockUsers.where((u) => u['role'] == 'pending').toList();
    final approvedUsers = mockUsers.where((u) => u['role'] != 'pending' && u['isApproved'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pending Users Section
          if (pendingUsers.isNotEmpty) ...[
            _SectionHeader(
              title: 'Pending Approval',
              count: pendingUsers.length,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            ...pendingUsers.map((user) => _UserCard(
              user: user,
              onApprove: () => _approveUser(context, user['id'] as String),
              onReject: () => _rejectUser(context, user['id'] as String),
            )),
            const SizedBox(height: 24),
          ],
          
          // Approved Users Section
          _SectionHeader(
            title: 'Active Users',
            count: approvedUsers.length,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          ...approvedUsers.map((user) => _UserCard(
            user: user,
            onApprove: null, // Already approved
            onReject: () => _deactivateUser(context, user['id'] as String),
          )),
        ],
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final roleController = TextEditingController(text: 'partner');
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'partner',
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'partner', child: Text('Partner')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) => roleController.text = value ?? 'partner',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'email': emailController.text,
              'role': roleController.text,
            }),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
    
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite sent to ${result['email']}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectUser(BuildContext context, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: const Text('Are you sure you want to reject this user? They will not be able to access the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User $uid rejected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.group,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _UserCard({
    required this.user,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final email = user['email'] as String;
    final displayName = user['displayName'] as String;
    final role = user['role'] as String;
    final isApproved = user['isApproved'] as bool;
    final isActive = user['isActive'] as bool;
    final createdAt = user['createdAt'] as DateTime;
    
    final isPending = role == 'pending';
    final initials = displayName.split(' ').map((n) => n[0]).take(2).join().toUpperCase();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(role).withOpacity(0.1),
              child: Text(
                initials,
                style: TextStyle(
                  color: _getRoleColor(role),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isPending)
                        Chip(
                          label: const Text('PENDING'),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Chip(
                          label: Text(role.toUpperCase()),
                          backgroundColor: _getRoleColor(role).withOpacity(0.1),
                          side: BorderSide(color: _getRoleColor(role).withOpacity(0.3)),
                          labelStyle: TextStyle(
                            color: _getRoleColor(role),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            if (isPending) ...[
              IconButton(
                onPressed: onReject,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onApprove,
                icon: const Icon(Icons.check),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  foregroundColor: Colors.green,
                ),
              ),
            ] else ...[
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'deactivate':
                      onReject?.call();
                      break;
                    case 'make_admin':
                      // Handle make admin
                      break;
                    case 'view_details':
                      // Handle view details
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view_details',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  if (role != 'admin')
                    const PopupMenuItem(
                      value: 'make_admin',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings),
                          SizedBox(width: 8),
                          Text('Make Admin'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Deactivate', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'partner':
        return Colors.blue;
      case 'staff':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
