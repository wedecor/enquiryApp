import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/dropdown_lookup.dart';
import '../../../../ui/components/enquiry_list_row.dart';
import '../../../../ui/components/enquiry_row_actions_sheet.dart';
import '../../../admin/users/presentation/users_providers.dart'
    as users_providers;
import '../../../enquiries/domain/enquiry.dart';
import 'dashboard_enquiry_tab_actions.dart';
import 'dashboard_enquiry_utils.dart';

/// Dashboard list row using the shared [EnquiryListRow] + quick-action sheet.
class DashboardEnquiryListRow extends ConsumerWidget {
  const DashboardEnquiryListRow({
    super.key,
    required this.enquiry,
    required this.actions,
    required this.dropdownLookup,
    this.isReminderTab = false,
  });

  final QueryDocumentSnapshot<Object?> enquiry;
  final DashboardEnquiryTabActions actions;
  final DropdownLookup? dropdownLookup;
  final bool isReminderTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = enquiry.data()! as Map<String, dynamic>;
    final enquiryId = enquiry.id;
    final enquiryModel = Enquiry.fromFirestore(enquiry);
    final customerName = (data['customerName'] as String?) ?? 'Customer';
    final phone = data['customerPhone'] as String?;
    final whatsapp = data['whatsappNumber'] as String? ?? phone;

    final statusValueRaw = data['statusValue'] as String?;
    final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
        ? statusValueRaw!.trim().toLowerCase()
        : 'new';
    final eventTypeValueRaw =
        (data['eventTypeValue'] ?? data['eventType']) as String?;
    final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
        ? eventTypeValueRaw!.trim()
        : 'event';
    final eventTypeLabel =
        (data['eventTypeLabel'] as String?) ??
        (dropdownLookup != null
            ? dropdownLookup!.labelForEventType(eventTypeValue)
            : DropdownLookup.titleCase(eventTypeValue));

    final createdAt = parseEnquiryDateTime(data['createdAt']) ?? DateTime.now();
    final eventDate = parseEnquiryDateTime(data['eventDate']);
    final location =
        (data['eventLocation'] as String?) ?? (data['location'] as String?);
    final assignedUserId = data['assignedTo'] as String?;
    final assigneeLabel = assignedUserId == null
        ? null
        : ref
              .watch(users_providers.userDisplayNameProvider(assignedUserId))
              .when(
                data: (v) => v,
                loading: () => '…',
                error: (_, __) => 'Unknown',
              );

    final sheetActions = contactEnquiryRowActions(
      customerName: customerName,
      phone: phone,
      whatsapp: whatsapp,
      enquiryId: enquiryId,
      onCall: (p) => actions.onCall(p, customerName, enquiryId),
      onWhatsApp: (p) => isReminderTab
          ? actions.onReminderWhatsApp(
              p,
              customerName,
              enquiryId,
              eventTypeLabel,
              createdAt,
              eventDate,
            )
          : actions.onWhatsApp(p, customerName, enquiryId),
      onView: () => actions.onView(enquiryId),
      onUpdateStatus: () => actions.onUpdateStatus(enquiryModel),
    );

    final statusLabel =
        (data['statusLabel'] as String?) ??
        (dropdownLookup != null
            ? dropdownLookup!.labelForStatus(statusValue)
            : DropdownLookup.titleCase(statusValue));

    return EnquiryListRow(
      customerName: customerName,
      statusValue: statusValue,
      statusLabel: statusLabel,
      firestoreStatusColors: dropdownLookup?.statusColorMap,
      eventTypeLabel: eventTypeLabel,
      eventTypeValue: eventTypeValue,
      eventDateLabel: formatDateLabel(eventDate),
      location: location?.trim(),
      ageLabel: formatAgeLabel(createdAt),
      assigneeLabel: assigneeLabel?.trim(),
      onTap: () => actions.onView(enquiryId),
      onLongPress: sheetActions.isEmpty
          ? null
          : () => showEnquiryRowActionsSheet(
              context,
              customerName: customerName,
              actions: sheetActions,
            ),
    );
  }
}
