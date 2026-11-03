import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../ui/components/enquiry_list_row.dart';
import '../../../../ui/components/enquiry_row_actions_sheet.dart';
import '../../../admin/users/presentation/users_providers.dart' as users_providers;
import '../../../enquiries/domain/booking_amounts.dart';
import '../../../enquiries/domain/enquiry.dart';
import '../../../enquiries/domain/enquiry_location.dart';
import '../../../enquiries/domain/event_functions.dart';
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
    this.showStatus = true,
  });

  final QueryDocumentSnapshot<Object?> enquiry;
  final DashboardEnquiryTabActions actions;
  final DropdownLookup? dropdownLookup;
  final bool isReminderTab;

  /// False on single-status tabs, where every row would repeat the tab name.
  final bool showStatus;

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
        ? (EnquiryStatus.canonicalValue(statusValueRaw) ?? statusValueRaw!.trim().toLowerCase())
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

    final createdAt = parseEnquiryDateTime(data['createdAt']) ?? DateTime.now();
    final location = (data['eventLocation'] as String?) ?? (data['location'] as String?);
    // Multi-function booking: one row, "4 functions · 10–13 Dec · Next: Haldi, 10 Dec (JP Nagar)",
    // dated by the next upcoming function.
    final now = DateTime.now();
    final functions = functionsOf(data);
    final functionsLine = functionsListSubtitle(functions, now);
    final nextFunction = functionsLine != null ? nextFunctionOf(functions, now) : null;
    final eventDate = nextFunction?.day ?? parseEnquiryDateTime(data['eventDate']);
    final assignedUserId = data['assignedTo'] as String?;
    final assigneeLabel = assignedUserId == null
        ? null
        : ref
              .watch(users_providers.userDisplayNameProvider(assignedUserId))
              .when(data: (v) => v, loading: () => '…', error: (_, _) => 'Unknown');

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
      statusValue: statusValue,
      onAddNote: () => actions.onAddNote(enquiryModel),
      onShare: () => actions.onShare(enquiryModel),
      onMarkNotInterested: () async {
        final userId = ref.read(currentUserWithFirestoreProvider).valueOrNull?.uid;
        if (userId == null) return;
        await actions.onMarkNotInterested(enquiryId, userId);
      },
      onRequestReview: (p) => actions.onReviewRequest(p, customerName, enquiryId),
    );

    final statusLabel = DropdownLookup.statusLabelOf(dropdownLookup, statusValue);

    return EnquiryListRow(
      customerName: customerName,
      statusValue: statusValue,
      statusLabel: statusLabel,
      firestoreStatusColors: dropdownLookup?.statusColorMap,
      eventTypeLabel: functionsLine ?? eventTypeLabel,
      eventTypeValue: eventTypeValue,
      eventDateLabel: formatDateLabel(eventDate),
      eventDate: (eventDate != null && eventDate.year > 1971) ? eventDate : null,
      location: functionsLine != null ? null : location?.trim(),
      ageLabel: formatAgeLabel(createdAt),
      assigneeLabel: assigneeLabel?.trim(),
      showStatusChip: showStatus,
      locationPending: isApprovedLocationPending(
        statusIsApproved: EnquiryStatus.isApproved(statusValue),
        data: data,
      ),
      amountPending: ref.watch(isAdminProvider) && isApprovedAmountPending(data),
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
