import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/audit_provider.dart';

/// Widget to display enquiry change history
class EnquiryHistoryWidget extends ConsumerWidget {
  final String enquiryId;

  const EnquiryHistoryWidget({super.key, required this.enquiryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(enquiryHistoryProvider(enquiryId));

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          final theme = Theme.of(context);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No changes recorded',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Changes to this enquiry will appear here',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final change = history[index];
            return _buildHistoryItem(context, change);
          },
        );
      },
      loading: () {
        final theme = Theme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading change history...',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) {
        final theme = Theme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Change history not available',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature requires additional setup',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> change) {
    final fieldChanged = change['field_changed'] as String? ?? 'Unknown Field';
    final oldValue = change['old_value'];
    final newValue = change['new_value'];
    final userEmail = change['user_email'] as String? ?? 'Unknown User';
    final timestamp = change['timestamp'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getFieldIcon(fieldChanged), color: _getFieldColor(fieldChanged), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getFieldDisplayName(fieldChanged),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (timestamp != null) ...[
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _formatValue(oldValue),
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          _formatValue(newValue),
                          style: TextStyle(color: Colors.green[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Changed by: $userEmail',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFieldIcon(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'status':
        return Icons.flag;
      case 'assignedto':
        return Icons.person_add;
      case 'priority':
        return Icons.priority_high;
      case 'totalcost':
        return Icons.attach_money;
      case 'advancepaid':
        return Icons.payment;
      case 'paymentstatus':
        return Icons.account_balance_wallet;
      case 'customername':
        return Icons.person;
      case 'customerphone':
        return Icons.phone;
      case 'eventtype':
        return Icons.event;
      case 'eventdate':
        return Icons.calendar_today;
      case 'eventlocation':
        return Icons.location_on;
      case 'description':
        return Icons.description;
      default:
        return Icons.edit;
    }
  }

  Color _getFieldColor(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'status':
        return const Color(0xFF2563EB); // Our new blue color
      case 'assignedto':
        return const Color(0xFF2563EB); // Blue
      case 'priority':
        return Colors.orange;
      case 'totalcost':
      case 'advancepaid':
      case 'paymentstatus':
        return Colors.green;
      case 'customername':
      case 'customerphone':
        return Colors.indigo;
      case 'eventtype':
      case 'eventdate':
      case 'eventlocation':
        return const Color(0xFF059669); // Our new green color
      case 'description':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getFieldDisplayName(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'status':
        return 'Status';
      case 'assignedto':
        return 'Assignment';
      case 'priority':
        return 'Priority';
      case 'totalcost':
        return 'Total Cost';
      case 'advancepaid':
        return 'Advance Paid';
      case 'paymentstatus':
        return 'Payment Status';
      case 'customername':
        return 'Customer Name';
      case 'customerphone':
        return 'Customer Phone';
      case 'eventtype':
        return 'Event Type';
      case 'eventdate':
        return 'Event Date';
      case 'eventlocation':
        return 'Event Location';
      case 'description':
        return 'Description';
      default:
        return fieldName.replaceAll('_', ' ').toTitleCase();
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Not Set';
    if (value is Timestamp) {
      return '${value.toDate().day}/${value.toDate().month}/${value.toDate().year}';
    }
    if (value is num) {
      return value.toString();
    }
    if (value is String) {
      return value.isEmpty ? 'Empty' : value;
    }
    return value.toString();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final changeTime = timestamp.toDate();
    final difference = now.difference(changeTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Extension to convert string to title case
extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
