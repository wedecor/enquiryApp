import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/services/notification_service.dart' as notification_service;
import '../../../../services/dropdown_lookup.dart';
import '../../../admin/users/presentation/users_providers.dart' as users_providers;
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/enquiry_history_widget.dart';
import '../../../../utils/logger.dart';
import '../widgets/contact_buttons.dart';
import '../widgets/review_request_button.dart';
import 'enquiry_form_screen.dart';

class EnquiryDetailsScreen extends ConsumerStatefulWidget {
  final String enquiryId;

  const EnquiryDetailsScreen({super.key, required this.enquiryId});

  @override
  ConsumerState<EnquiryDetailsScreen> createState() => _EnquiryDetailsScreenState();
}

class _EnquiryDetailsScreenState extends ConsumerState<EnquiryDetailsScreen> {
  String? _selectedStatus;
  // Cache user display strings (name · phone) by uid to reduce lookups
  final Map<String, String> _userDisplayCache = <String, String>{};
  bool _isUpdatingStatus = false;

  // Allowed status transitions for staff users
  static const Map<String, List<String>> _allowedTransitions = {
    'new': ['in_talks', 'cancelled', 'not_interested'],
    'in_talks': ['quote_sent', 'cancelled', 'not_interested'],
    'quote_sent': ['confirmed', 'closed_lost', 'not_interested'],
    'confirmed': ['scheduled', 'cancelled'],
    'scheduled': ['completed', 'cancelled'],
    'completed': [],
    'cancelled': [],
    'closed_lost': [],
    'not_interested': [],
  };

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final roleAsync = ref.watch(roleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Details'),
        actions: [
          roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _isUpdatingStatus
                        ? null
                        : () async {
                            await _confirmAndDelete(context);
                          },
                    tooltip: 'Delete Enquiry',
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in to view enquiry details'));
          }

          return roleAsync.when(
            data: (userRole) {
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
                  final dropdownLookup = ref
                      .watch(dropdownLookupProvider)
                      .maybeWhen(data: (value) => value, orElse: () => null);

                  String _labelOrLookup(
                    String? label,
                    String value,
                    String Function(DropdownLookup, String) resolver,
                  ) {
                    if (label != null && label.trim().isNotEmpty) return label;
                    return dropdownLookup != null
                        ? resolver(dropdownLookup, value)
                        : DropdownLookup.titleCase(value);
                  }

                  final statusValueRaw =
                      (enquiryData['statusValue'] ?? enquiryData['eventStatus']) as String?;
                  final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
                      ? statusValueRaw!.trim()
                      : 'new';
                  final statusLabel = _labelOrLookup(
                    enquiryData['statusLabel'] as String?,
                    statusValue,
                    (l, v) => l.labelForStatus(v),
                  );

                  final eventTypeValueRaw =
                      (enquiryData['eventTypeValue'] ?? enquiryData['eventType']) as String?;
                  final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
                      ? eventTypeValueRaw!.trim()
                      : 'event';
                  final eventTypeLabel = _labelOrLookup(
                    enquiryData['eventTypeLabel'] as String?,
                    eventTypeValue,
                    (l, v) => l.labelForEventType(v),
                  );

                  final priorityValueRaw =
                      (enquiryData['priorityValue'] ?? enquiryData['priority']) as String?;
                  final priorityValue = (priorityValueRaw?.trim().isNotEmpty ?? false)
                      ? priorityValueRaw!.trim()
                      : null;
                  final priorityLabel = priorityValue != null
                      ? _labelOrLookup(
                          enquiryData['priorityLabel'] as String?,
                          priorityValue,
                          (l, v) => l.labelForPriority(v),
                        )
                      : 'N/A';

                  final paymentStatusValueRaw =
                      (enquiryData['paymentStatusValue'] ?? enquiryData['paymentStatus']) as String?;
                  final paymentStatusValue = (paymentStatusValueRaw?.trim().isNotEmpty ?? false)
                      ? paymentStatusValueRaw!.trim()
                      : null;
                  final paymentStatusLabel = paymentStatusValue != null
                      ? _labelOrLookup(
                          enquiryData['paymentStatusLabel'] as String?,
                          paymentStatusValue,
                          (l, v) => l.labelForPaymentStatus(v),
                        )
                      : 'N/A';

                  final sourceValueRaw =
                      (enquiryData['sourceValue'] ?? enquiryData['source']) as String?;
                  final sourceValue = (sourceValueRaw?.trim().isNotEmpty ?? false)
                      ? sourceValueRaw!.trim()
                      : null;
                  final sourceLabel = sourceValue != null
                      ? _labelOrLookup(
                          enquiryData['sourceLabel'] as String?,
                          sourceValue,
                          (l, v) => l.labelForSource(v),
                        )
                      : 'N/A';

                  // Check if staff user can access this enquiry
                  if (userRole != UserRole.admin) {
                    final assignedTo = enquiryData['assignedTo'] as String?;
                    final currentUserId = user.uid;

                    if (assignedTo != null && assignedTo != currentUserId) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
                        _buildHeader(enquiryData, userRole, user.uid, statusValue, statusLabel),
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
                        // Review request button for completed enquiries
                        if (statusValue == 'completed')
                          ReviewRequestButton(
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
                        _buildInfoRow('Event Type', eventTypeLabel),
                        _buildInfoRow('Event Date', _formatDate(enquiryData['eventDate'])),
                        _buildInfoRow(
                          'Guest Count',
                          '${enquiryData['guestCount'] ?? 'N/A'} guests',
                        ),
                        _buildInfoRow(
                          'Budget Range',
                          (enquiryData['budgetRange'] as String?) ?? 'N/A',
                        ),
                        _buildInfoRow('Priority', priorityLabel),
                        _buildInfoRow('Source', sourceLabel),
                      ],
                    ),

                        // Reference Images (Admins and Assignee)
                        if (_canViewImages(userRole, enquiryData, user.uid))
                          _buildImagesSection(enquiryData),

                        // Assignment Information (Admin Only)
                        if (userRole == UserRole.admin) ...[
                      _buildSection(
                        title: 'Assignment',
                        children: [
                          _buildAsyncUserRow(
                            label: 'Assigned To',
                            userId: enquiryData['assignedTo'] as String?,
                            currentUserId: currentUser.value?.uid,
                          ),
                          _buildAsyncUserRow(
                            label: 'Created By',
                            userId: enquiryData['createdBy'] as String?,
                          ),
                        ],
                      ),
                        ] else if (userRole == UserRole.staff) ...[
                      // Staff can see their own assignment status
                      _buildSection(
                        title: 'Assignment',
                        children: [
                          _buildAsyncUserRow(
                            label: 'Assigned To',
                            userId: enquiryData['assignedTo'] as String?,
                            currentUserId: user.uid,
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
                          _buildInfoRow('Payment Status', paymentStatusLabel),
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
            error: (error, stack) => Center(child: Text('Error checking permissions: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading user data: $error')),
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> enquiryData,
    UserRole? userRole,
    String currentUserId,
    String statusValue,
    String statusLabel,
  ) {
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
                  _buildStatusDropdown(enquiryData, statusValue, statusLabel, isAdmin: true),
                ] else if (userRole == UserRole.staff) ...[
                  // Staff can edit status (but only status) if assigned
                  _buildStatusDropdown(
                    enquiryData,
                    statusValue,
                    statusLabel,
                    isAdmin: false,
                    isAssignee: (enquiryData['assignedTo'] as String?) == currentUserId,
                  ),
                ] else ...[
                  // Read-only status for other users
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusValue),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildStatusDropdown(
    Map<String, dynamic> enquiryData,
    String currentStatusValue,
    String currentStatusLabel, {
    required bool isAdmin,
    bool isAssignee = true,
  }) {
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
            {'value': 'in_talks', 'label': 'In Talks', 'order': 2},
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

        final currentStatus = (_selectedStatus ?? currentStatusValue);
        final values = statuses.map((s) => (s['value'] as String?) ?? '').toList();
        final safeValue = values.contains(currentStatus)
            ? currentStatus
            : (values.isNotEmpty ? values.first : 'new');

        // Limit staff to allowed transitions
        final nextOptions = <Map<String, dynamic>>[...statuses];
        if (!isAdmin) {
          final allowed = _allowedTransitions[safeValue] ?? const <String>[];
          // Keep current value plus allowed next states only
          nextOptions.retainWhere((s) {
            final v = (s['value'] as String?) ?? '';
            return v == safeValue || allowed.contains(v);
          });
        }

        final canChange = isAdmin || (!isAdmin && isAssignee);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              key: const Key('statusDropdown'),
              value: safeValue,
              items: nextOptions.map((status) {
                final value = (status['value'] as String?) ?? '';
                final label = (status['label'] as String?) ?? value;
                return DropdownMenuItem<String>(value: value, child: Text(label));
              }).toList(),
              onChanged: (!canChange || _isUpdatingStatus)
                  ? null
                  : (value) async {
                      if (value == null || value == currentStatusValue) return;

                      // Staff transition guard
                      if (!isAdmin) {
                        final allowed = _allowedTransitions[safeValue] ?? const <String>[];
                        if (!allowed.contains(value)) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('This status change is not allowed'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      setState(() {
                        _isUpdatingStatus = true;
                        _selectedStatus = value; // optimistic
                      });

                      try {
                        final oldStatus = currentStatusLabel;
                        final lookup = await ref.read(dropdownLookupProvider.future);
                        final nextLabel = lookup.labelForStatus(value);

                        await FirebaseFirestore.instance
                            .collection('enquiries')
                            .doc(widget.enquiryId)
                            .update({
                              'eventStatus': value,
                              'status': value,
                              'statusValue': value,
                              'statusLabel': nextLabel,
                              'statusUpdatedAt': FieldValue.serverTimestamp(),
                              'statusUpdatedBy':
                                  ref.read(currentUserWithFirestoreProvider).value?.uid ??
                                  'unknown',
                              'updatedAt': FieldValue.serverTimestamp(),
                              'updatedBy':
                                  ref.read(currentUserWithFirestoreProvider).value?.uid ??
                                  'unknown',
                            });

                        // Record audit trail for status change
                        final auditService = AuditService();
                        await auditService.recordChange(
                          enquiryId: widget.enquiryId,
                          fieldChanged: 'eventStatus',
                          oldValue: oldStatus,
                          newValue: nextLabel,
                        );

                        // Send notification for status update
                        final notificationService = notification_service.NotificationService();
                        await notificationService.notifyStatusUpdated(
                          enquiryId: widget.enquiryId,
                          customerName:
                              enquiryData['customerName'] as String? ?? 'Unknown Customer',
                          oldStatus: oldStatus,
                          newStatus: nextLabel,
                          updatedBy:
                              ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
                          assignedTo: enquiryData['assignedTo'] as String?,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Status updated'),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        // Rollback optimistic selection on error
                        setState(() {
                          _selectedStatus = currentStatusValue;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update status: $e'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isUpdatingStatus = false;
                          });
                        }
                      }
                    },
            ),
            if (_isUpdatingStatus) ...[
              const SizedBox(width: 8),
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
            if (!isAdmin && !isAssignee) ...[
              const SizedBox(height: 6),
              Text(
                'Only the assigned user can change status',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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

  // Note: edit-mode helpers removed as part of revert

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

  bool _canViewImages(UserRole? role, Map<String, dynamic> data, String meUid) {
    if (role == UserRole.admin) return true;
    final assignedTo = data['assignedTo'] as String?;
    return assignedTo != null && assignedTo == meUid;
  }

  Widget _buildImagesSection(Map<String, dynamic> enquiryData) {
    final images = (enquiryData['images'] as List?)?.cast<dynamic>() ?? const [];
    if (images.isEmpty) {
      return _buildSection(title: 'Reference Images', children: const [Text('No images attached')]);
    }

    return _buildSection(
      title: 'Reference Images',
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final url = images[index] as String?;
            if (url == null || url.isEmpty) {
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: InteractiveViewer(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, fit: BoxFit.cover),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Enquiry'),
        content: const Text(
          'Are you sure you want to delete this enquiry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
      setState(() {
        _isUpdatingStatus = true;
      });

      // Record audit trail before deletion
      final auditService = AuditService();
      await auditService.recordChange(
        enquiryId: widget.enquiryId,
        fieldChanged: 'deleted',
        oldValue: 'exists',
        newValue: 'deleted',
      );

      // Delete the enquiry document
      await FirebaseFirestore.instance.collection('enquiries').doc(widget.enquiryId).delete();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enquiry deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete enquiry: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Color _getStatusColor(String? status) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case 'new':
        return const Color(0xFFFF9800); // Orange
      case 'in_talks':
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

  Widget _buildAsyncUserRow({
    required String label,
    required String? userId,
    String? currentUserId,
  }) {
    // Layout mirrors _buildInfoRow styling
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: _buildUserDisplay(userId, currentUserId)),
        ],
      ),
    );
  }

  Widget _buildUserDisplay(String? userId, String? currentUserId) {
    if (userId == null || userId.isEmpty) {
      return const Text('Unassigned', style: TextStyle(fontSize: 16));
    }
    if (currentUserId != null && userId == currentUserId) {
      return const Text('You', style: TextStyle(fontSize: 16));
    }

    return FutureBuilder<String>(
      future: _getUserDisplayName(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 12, child: LinearProgressIndicator(minHeight: 2));
        }
        final value = snapshot.data ?? 'Unknown';
        return Text(value, style: const TextStyle(fontSize: 16));
      },
    );
  }

  Future<String> _getUserDisplayName(String userId) async {
    final cached = _userDisplayCache[userId];
    if (cached != null) return cached;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!doc.exists) {
        _userDisplayCache[userId] = 'Unknown';
        return 'Unknown';
      }
      final data = doc.data();
      final name = (data?['name'] as String?)?.trim();
      final phone = (data?['phone'] as String?)?.trim();
      final display = [name, phone].where((e) => e != null && e.isNotEmpty).join(' · ');
      final result = display.isNotEmpty ? display : 'Unknown';
      _userDisplayCache[userId] = result;
      return result;
    } catch (_) {
      return 'Unknown';
    }
  }
}
