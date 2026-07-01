import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../ui/components/enquiry_list_tile.dart';
import '../../../admin/users/presentation/users_providers.dart' as users_providers;
import '../screens/enquiry_details_screen.dart';

/// Maps Firestore enquiry data to the shared [EnquiryTileStatusStrip] list tile.
class EnquiryListItem extends ConsumerWidget {
  const EnquiryListItem({
    super.key,
    required this.enquiryId,
    required this.data,
    required this.dropdownLookup,
    this.showAssignee = false,
    this.assigneeLabel,
    this.onEdit,
  });

  final String enquiryId;
  final Map<String, dynamic> data;
  final DropdownLookup? dropdownLookup;
  final bool showAssignee;
  final String? assigneeLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusValueRaw = data['statusValue'] as String?;
    final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
        ? statusValueRaw!.trim()
        : 'new';
    final statusLabel =
        (data['statusLabel'] as String?) ??
        (dropdownLookup != null
            ? dropdownLookup!.labelForStatus(statusValue)
            : DropdownLookup.titleCase(statusValue));
    final eventTypeValueRaw = (data['eventTypeValue'] ?? data['eventType']) as String?;
    final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
        ? eventTypeValueRaw!.trim()
        : 'event';
    final eventTypeLabel =
        (data['eventTypeLabel'] as String?) ??
        (dropdownLookup != null
            ? dropdownLookup!.labelForEventType(eventTypeValue)
            : DropdownLookup.titleCase(eventTypeValue));

    final customerName = (data['customerName'] as String?) ?? 'Customer';
    final phone = data['customerPhone'] as String?;
    final whatsapp = data['whatsappNumber'] as String? ?? phone;
    final createdAt = _parseDateTime(data['createdAt']) ?? DateTime.now();
    final eventDate = _parseDateTime(data['eventDate']);
    final location = (data['eventLocation'] as String?) ?? (data['location'] as String?);
    final notes = (data['description'] as String?) ?? (data['notes'] as String?);

    // Resolve assignee name via provider so we show a real name, not a UID.
    final assignedTo = data['assignedTo'] as String?;
    String? resolvedAssignee;
    if (showAssignee && assignedTo != null) {
      resolvedAssignee = ref
          .watch(users_providers.userDisplayNameProvider(assignedTo))
          .when(data: (v) => v, loading: () => '…', error: (_, __) => 'Unknown');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
      child: EnquiryTileStatusStrip(
        name: customerName,
        status: statusLabel,
        eventType: eventTypeLabel,
        eventCountdownLabel: _formatEventCountdownLabel(eventDate),
        ageLabel: _formatAgeLabel(createdAt),
        assignee: showAssignee ? resolvedAssignee : null,
        dateLabel: _formatDateLabel(eventDate),
        location: location,
        notes: notes,
        phoneNumber: phone,
        whatsappNumber: whatsapp,
        onView: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId),
            ),
          );
        },
        enquiryId: enquiryId,
        onCall: phone == null
            ? null
            : () async {
                final launcher = ref.read(contactLauncherProvider);
                await launcher.callNumberWithAudit(phone, enquiryId: enquiryId);
              },
        onWhatsApp: whatsapp == null
            ? null
            : () async {
                final launcher = ref.read(contactLauncherProvider);
                await launcher.openWhatsAppWithAudit(
                  whatsapp,
                  prefillText: 'Hi $customerName, this is from We Decor.',
                  enquiryId: enquiryId,
                );
              },
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatDateLabel(DateTime? date) {
    if (date == null) return 'Date TBC';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
    return '${age.inDays ~/ 365}y old';
  }
}
