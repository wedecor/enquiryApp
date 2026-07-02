import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../ui/components/enquiry_list_row.dart';
import '../../../../ui/components/enquiry_row_actions_sheet.dart';
import '../screens/enquiry_details_screen.dart';

/// Maps Firestore enquiry data to the shared [EnquiryListRow].
class EnquiryListItem extends ConsumerWidget {
  const EnquiryListItem({
    super.key,
    required this.enquiryId,
    required this.data,
    required this.dropdownLookup,
    this.showAssignee = false,
    this.assigneeLabel,
    this.onEdit,
    this.compact = false,
    this.onReturnFromDetail,
  });

  final String enquiryId;
  final Map<String, dynamic> data;
  final DropdownLookup? dropdownLookup;
  final bool showAssignee;
  final String? assigneeLabel;
  final VoidCallback? onEdit;
  final bool compact;
  final VoidCallback? onReturnFromDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusValueRaw = data['statusValue'] as String?;
    final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
        ? statusValueRaw!.trim().toLowerCase()
        : 'new';
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

    void openDetails() {
      Navigator.of(context)
          .push<void>(
            MaterialPageRoute<void>(
              builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId),
            ),
          )
          .then((_) => onReturnFromDetail?.call());
    }

    final sheetActions = contactEnquiryRowActions(
      customerName: customerName,
      phone: phone,
      whatsapp: whatsapp,
      enquiryId: enquiryId,
      onCall: (p) async {
        final launcher = ref.read(contactLauncherProvider);
        await launcher.callNumberWithAudit(p, enquiryId: enquiryId);
      },
      onWhatsApp: (p) async {
        final launcher = ref.read(contactLauncherProvider);
        await launcher.openWhatsAppWithAudit(
          p,
          prefillText: 'Hi $customerName, this is from We Decor.',
          enquiryId: enquiryId,
        );
      },
      onView: openDetails,
    );

    return Padding(
      padding: EdgeInsets.zero,
      child: EnquiryListRow(
        customerName: customerName,
        statusValue: statusValue,
        firestoreStatusColors: dropdownLookup?.statusColorMap,
        eventTypeLabel: eventTypeLabel,
        eventTypeValue: eventTypeValue,
        eventDateLabel: _formatDateLabel(eventDate),
        location: compact ? null : location?.trim(),
        ageLabel: compact ? null : _formatAgeLabel(createdAt),
        assigneeLabel: compact || !showAssignee ? null : assigneeLabel?.trim(),
        compact: compact,
        onTap: onEdit ?? openDetails,
        onLongPress: sheetActions.isEmpty
            ? null
            : () => showEnquiryRowActionsSheet(
                context,
                customerName: customerName,
                actions: sheetActions,
              ),
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
    if (date.year <= 1971) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
