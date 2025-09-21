import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/enquiry_history_widget.dart';
import '../widgets/contact_buttons.dart';
import 'enquiry_form_screen.dart';

class NotificationService {
  Future<void> notifyStatusUpdated({
    required String enquiryId,
    required String customerName,
    required String oldStatus,
    required String newStatus,
    required String updatedBy,
  }) async {
    // TODO: Implement notification
    print('Notification: Status updated for $customerName from $oldStatus to $newStatus');
  }
}

class EnquiryDetailsScreen extends ConsumerStatefulWidget {
  final String enquiryId;

  const EnquiryDetailsScreen({super.key, required this.enquiryId});

  @override
  ConsumerState<EnquiryDetailsScreen> createState() => _EnquiryDetailsScreenState();
}

class _EnquiryDetailsScreenState extends ConsumerState<EnquiryDetailsScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final userRole = currentUser.value?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (userRole == UserRole.admin) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        EnquiryFormScreen(enquiryId: widget.enquiryId, mode: 'edit'),
                  ),
                );
              },
              tooltip: 'Edit Enquiry',
            ),
          ],
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in to view enquiry details'));
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('enquiries')
                .doc(widget.enquiryId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Enquiry not found'));
              }

              final enquiryData = snapshot.data!.data() as Map<String, dynamic>;

              // Check if staff user can access this enquiry
              if (userRole != UserRole.admin) {
                final assignedTo = enquiryData['assignedTo'] as String?;
                final currentUserId = user.uid;

                if (assignedTo != null && assignedTo != currentUserId) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        const Text(
                          'Access Denied',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can only view enquiries assigned to you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status
                    _buildHeader(enquiryData, userRole),
                    const SizedBox(height: 24),

                    // Basic Information (Visible to all)
                    _buildSection(
                      title: 'Basic Information',
                      children: [
                        _buildInfoRow(
                          'Customer Name',
                          (enquiryData['customerName'] as String?) ?? 'N/A',
                        ),
                        _buildInfoRow('Phone', (enquiryData['customerPhone'] as String?) ?? 'N/A'),
                        // Contact shortcuts - Call and WhatsApp buttons
                        ContactButtons(
                          customerPhone: enquiryData['customerPhone'] as String?,
                          customerName: (enquiryData['customerName'] as String?) ?? 'Customer',
                          enquiryId: widget.enquiryId,
                        ),
                        _buildInfoRow(
                          'Location',
                          (enquiryData['eventLocation'] as String?) ??
                              (enquiryData['location'] as String? ?? 'N/A'),
                        ),
                      ],
                    ),

                    // Event Details (Visible to all)
                    _buildSection(
                      title: 'Event Details',
                      children: [
                        _buildInfoRow('Event Type', (enquiryData['eventType'] as String?) ?? 'N/A'),
                        _buildInfoRow('Event Date', _formatDate(enquiryData['eventDate'])),
                        _buildInfoRow(
                          'Guest Count',
                          '${enquiryData['guestCount'] ?? 'N/A'} guests',
                        ),
                        _buildInfoRow(
                          'Budget Range',
                          (enquiryData['budgetRange'] as String?) ?? 'N/A',
                        ),
                        _buildInfoRow(
                          'Priority',
                          _capitalizeFirst((enquiryData['priority'] as String?) ?? 'N/A'),
                        ),
                        _buildInfoRow('Source', (enquiryData['source'] as String?) ?? 'N/A'),
                      ],
                    ),

                    // Assignment Information (Admin Only)
                    if (userRole == UserRole.admin) ...[
                      _buildSection(
                        title: 'Assignment',
                        children: [
                          _buildInfoRow(
                            'Assigned To',
                            _getAssignedUserName(enquiryData['assignedTo'] as String?),
                          ),
                          _buildInfoRow(
                            'Created By',
                            _getCreatedByUserName(enquiryData['createdBy'] as String?),
                          ),
                        ],
                      ),
                    ] else if (userRole == UserRole.staff) ...[
                      // Staff can see their own assignment status
                      _buildSection(
                        title: 'Assignment',
                        children: [
                          _buildInfoRow(
                            'Assigned To',
                            _getAssignmentStatusForStaff(
                              enquiryData['assignedTo'] as String?,
                              user.uid,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Financial Information (Admin Only)
                    if (userRole == UserRole.admin) ...[
                      _buildSection(
                        title: 'Financial Information',
                        children: [
                          _buildInfoRow('Total Cost', _formatCurrency(enquiryData['totalCost'])),
                          _buildInfoRow(
                            'Advance Paid',
                            _formatCurrency(enquiryData['advancePaid']),
                          ),
                          _buildInfoRow(
                            'Payment Status',
                            _capitalizeFirst((enquiryData['paymentStatus'] as String?) ?? 'N/A'),
                          ),
                        ],
                      ),
                    ],

                    // Description (Visible to all)
                    _buildSection(
                      title: 'Description',
                      children: [
                        _buildInfoRow(
                          'Notes',
                          (enquiryData['description'] as String?) ?? 'No description provided',
                        ),
                      ],
                    ),

                    // Timestamps (Visible to all)
                    _buildSection(
                      title: 'Timestamps',
                      children: [
                        _buildInfoRow('Created', _formatTimestamp(enquiryData['createdAt'])),
                        _buildInfoRow('Last Updated', _formatTimestamp(enquiryData['updatedAt'])),
                      ],
                    ),

                    // Change History (Visible to all)
                    _buildSection(
                      title: 'Change History',
                      children: [EnquiryHistoryWidget(enquiryId: widget.enquiryId)],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading user data: $error')),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> enquiryData, UserRole? userRole) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Enquiry #${widget.enquiryId.substring(0, 8)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (userRole == UserRole.admin) ...[
                  // Admin can edit status
                  _buildStatusDropdown(enquiryData),
                ] else if (userRole == UserRole.staff) ...[
                  // Staff can edit status (but only status)
                  _buildStatusDropdown(enquiryData),
                ] else ...[
                  // Read-only status for other users
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(enquiryData['eventStatus'] as String?),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _capitalizeFirst(enquiryData['eventStatus'] as String? ?? 'N/A'),
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${(enquiryData['customerName'] as String?) ?? 'N/A'}',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(Map<String, dynamic> enquiryData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dropdowns')
          .doc('statuses')
          .collection('items')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        // Show loading only briefly, then fallback to default statuses
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // Use fallback statuses if Firestore collection is empty or has error
        List<Map<String, dynamic>> statuses;
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Fallback to default statuses
          statuses = [
            {'value': 'new', 'label': 'New', 'order': 1},
            {'value': 'in_progress', 'label': 'In Progress', 'order': 2},
            {'value': 'quote_sent', 'label': 'Quote Sent', 'order': 3},
            {'value': 'approved', 'label': 'Approved', 'order': 4},
            {'value': 'scheduled', 'label': 'Scheduled', 'order': 5},
            {'value': 'completed', 'label': 'Completed', 'order': 6},
            {'value': 'cancelled', 'label': 'Cancelled', 'order': 7},
            {'value': 'closed_lost', 'label': 'Closed Lost', 'order': 8},
          ];
        } else {
          statuses = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        }

        final currentStatus = (_selectedStatus ?? (enquiryData['eventStatus'] as String?)) ?? 'new';
        final values = statuses.map((s) => (s['value'] as String?) ?? '').toList();
        final safeValue = values.contains(currentStatus)
            ? currentStatus
            : (values.isNotEmpty ? values.first : 'new');

        return DropdownButton<String>(
          value: safeValue,
          items: statuses.map((status) {
            final value = (status['value'] as String?) ?? '';
            final label = (status['label'] as String?) ?? value;
            return DropdownMenuItem<String>(value: value, child: Text(label));
          }).toList(),
          onChanged: (value) async {
            if (value != null && value != enquiryData['eventStatus']) {
              setState(() {});

              try {
                final oldStatus = (enquiryData['eventStatus'] as String?) ?? 'Unknown';

                await FirebaseFirestore.instance
                    .collection('enquiries')
                    .doc(widget.enquiryId)
                    .update({
                      'eventStatus': value,
                      'updatedAt': FieldValue.serverTimestamp(),
                      'updatedBy':
                          ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
                    });

                // Record audit trail for status change
                final auditService = AuditService();
                await auditService.recordChange(
                  enquiryId: widget.enquiryId,
                  fieldChanged: 'eventStatus',
                  oldValue: oldStatus,
                  newValue: value,
                );

                // Send notification for status update
                final notificationService = NotificationService();
                await notificationService.notifyStatusUpdated(
                  enquiryId: widget.enquiryId,
                  customerName: enquiryData['customerName'] as String? ?? 'Unknown Customer',
                  oldStatus: oldStatus,
                  newStatus: value,
                  updatedBy: ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
                );

                setState(() {
                  _selectedStatus = value;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Status updated successfully'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                setState(() {});

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating status: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value == null ? 'N/A' : value.toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    if (amount is num) {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return amount.toString();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute}';
    }
    return timestamp.toString();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Color _getStatusColor(String? status) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (status) {
      case 'new':
        return const Color(0xFFFF9800); // Orange
      case 'in_progress':
        return colorScheme.primary;
      case 'quote_sent':
        return const Color(0xFF009688); // Teal
      case 'approved':
        return const Color(0xFF3F51B5); // Indigo
      case 'scheduled':
        return const Color(0xFF9C27B0); // Purple
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'cancelled':
      case 'closed_lost':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  String _getAssignedUserName(String? assignedTo) {
    if (assignedTo == null) return 'Unassigned';
    // TODO: Fetch user name from Firestore
    return 'User ID: $assignedTo';
  }

  String _getCreatedByUserName(String? createdBy) {
    if (createdBy == null) return 'Unknown';
    // TODO: Fetch user name from Firestore
    return 'User ID: $createdBy';
  }

  String _getAssignmentStatusForStaff(String? assignedTo, String currentUserId) {
    if (assignedTo == null) {
      return 'Unassigned';
    }
    if (assignedTo == currentUserId) {
      return 'You';
    }
    return 'User ID: $assignedTo';
  }
}
