import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/audit_provider.dart';
import '../../features/admin/users/presentation/users_providers.dart' as users_providers;
import '../../services/dropdown_lookup.dart';

/// Widget to display enquiry change history
class EnquiryHistoryWidget extends ConsumerWidget {
  final String enquiryId;

  const EnquiryHistoryWidget({super.key, required this.enquiryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(enquiryHistoryProvider(enquiryId));

    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

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
            return _buildHistoryItem(context, change, ref, dropdownLookup);
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

  Widget _buildHistoryItem(
    BuildContext context,
    Map<String, dynamic> change,
    WidgetRef ref,
    DropdownLookup? dropdownLookup,
  ) {
    final fieldChanged = change['field_changed'] as String? ?? 'Unknown Field';
    final oldValue = change['old_value'];
    final newValue = change['new_value'];
    final userEmail = change['user_email'] as String? ?? 'Unknown User';
    final timestamp = change['timestamp'] as Timestamp?;
    final fieldKey = fieldChanged.toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFieldIcon(fieldChanged),
                  color: _getFieldColor(context, fieldChanged),
                  size: 20,
                ),
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
                      const Text('From:', style: _sectionLabelStyle),
                      const SizedBox(height: 4),
                      _ValueChip(
                        value: oldValue,
                        fieldKey: fieldKey,
                        dropdownLookup: dropdownLookup,
                        isNew: false,
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
                      const Text('To:', style: _sectionLabelStyle),
                      const SizedBox(height: 4),
                      _ValueChip(
                        value: newValue,
                        fieldKey: fieldKey,
                        dropdownLookup: dropdownLookup,
                        isNew: true,
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
      case 'eventstatus':
        return Icons.timeline;
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

  Color _getFieldColor(BuildContext context, String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'status':
        return Theme.of(context).colorScheme.primary;
      case 'assignedto':
        return Theme.of(context).colorScheme.primary;
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
        return Theme.of(context).colorScheme.secondary;
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
      case 'eventstatus':
        return 'Event Status';
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

class _ValueChip extends ConsumerWidget {
  const _ValueChip({
    required this.value,
    required this.fieldKey,
    required this.dropdownLookup,
    required this.isNew,
  });

  final dynamic value;
  final String fieldKey;
  final DropdownLookup? dropdownLookup;
  final bool isNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = isNew ? Colors.green[50] : Colors.red[50];
    final borderColor = isNew ? Colors.green[200]! : Colors.red[200]!;
    final textColor = isNew ? Colors.green[700]! : Colors.red[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: _ValueText(
        value: value,
        fieldKey: fieldKey,
        dropdownLookup: dropdownLookup,
        textColor: textColor,
      ),
    );
  }
}

class _ValueText extends ConsumerWidget {
  const _ValueText({
    required this.value,
    required this.fieldKey,
    required this.dropdownLookup,
    required this.textColor,
  });

  final dynamic value;
  final String fieldKey;
  final DropdownLookup? dropdownLookup;
  final Color textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = TextStyle(color: textColor, fontSize: 14);

    if (value == null) return Text('Not Set', style: style);
    if (value is String) {
      final normalized = (value as String).trim();
      if (normalized.isEmpty || normalized.toLowerCase() == 'not set') {
        return Text('Not Set', style: style);
      }
    }

    if (value is Timestamp) {
      final date = value.toDate();
      return Text('${date.day}/${date.month}/${date.year}', style: style);
    }

    final stringValue = value.toString();

    switch (fieldKey) {
      case 'assignedto':
        final asyncName = ref.watch(users_providers.userDisplayNameProvider(stringValue));
        return asyncName.when(
          data: (name) => Text(name, style: style),
          loading: () => Text('Loading...', style: style),
          error: (err, _) => Text(stringValue, style: style),
        );
      case 'status':
      case 'eventstatus':
        final label =
            dropdownLookup?.labelForStatus(stringValue) ?? DropdownLookup.titleCase(stringValue);
        return Text(label, style: style);
      case 'eventtype':
        final label =
            dropdownLookup?.labelForEventType(stringValue) ?? DropdownLookup.titleCase(stringValue);
        return Text(label, style: style);
      case 'priority':
        final label =
            dropdownLookup?.labelForPriority(stringValue) ?? DropdownLookup.titleCase(stringValue);
        return Text(label, style: style);
      case 'paymentstatus':
        final label =
            dropdownLookup?.labelForPaymentStatus(stringValue) ??
            DropdownLookup.titleCase(stringValue);
        return Text(label, style: style);
      case 'source':
        final label =
            dropdownLookup?.labelForSource(stringValue) ?? DropdownLookup.titleCase(stringValue);
        return Text(label, style: style);
      default:
        return Text(stringValue.isEmpty ? 'Not Set' : stringValue, style: style);
    }
  }
}

const TextStyle _sectionLabelStyle = TextStyle(
  fontSize: 12,
  color: Color(0xFF757575),
  fontWeight: FontWeight.w500,
);

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
