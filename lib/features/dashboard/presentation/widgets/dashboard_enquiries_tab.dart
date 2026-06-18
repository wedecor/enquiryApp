import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../widgets/enquiry_tile_status_strip.dart';
import '../../../admin/users/presentation/users_providers.dart' as users_providers;
import '../../../enquiries/domain/enquiry.dart';
import 'dashboard_empty_enquiries.dart';
import 'dashboard_enquiry_utils.dart';

/// Callbacks for enquiry list item actions (kept on the screen).
class DashboardEnquiryTabActions {
  const DashboardEnquiryTabActions({
    required this.onView,
    required this.onCall,
    required this.onWhatsApp,
    required this.onReminderWhatsApp,
    required this.onUpdateStatus,
    required this.onShare,
    required this.onAddNote,
    required this.onReviewRequest,
    required this.onMarkNotInterested,
  });

  final void Function(String enquiryId) onView;
  final Future<void> Function(String? phone, String customerName, String enquiryId) onCall;
  final Future<void> Function(String? phone, String customerName, String enquiryId) onWhatsApp;
  final Future<void> Function(
    String phone,
    String customerName,
    String enquiryId,
    String eventType,
    DateTime createdAt,
    DateTime? eventDate,
  ) onReminderWhatsApp;
  final Future<void> Function(Enquiry enquiry) onUpdateStatus;
  final Future<void> Function(Enquiry enquiry) onShare;
  final Future<void> Function(Enquiry enquiry) onAddNote;
  final Future<void> Function(String phone, String customerName, String enquiryId) onReviewRequest;
  final Future<void> Function(String enquiryId, String userId) onMarkNotInterested;
}

/// Filtered enquiries list for a single dashboard status tab.
class DashboardEnquiriesTab extends ConsumerWidget {
  const DashboardEnquiriesTab({
    super.key,
    required this.status,
    required this.isAdmin,
    required this.userId,
    required this.searchQuery,
    required this.onClearSearch,
    required this.statusColorCache,
    required this.eventColorCache,
    required this.actions,
    required this.errorBuilder,
    this.onTabVisible,
  });

  final String status;
  final bool isAdmin;
  final String? userId;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final Map<String, Color> statusColorCache;
  final Map<String, Color> eventColorCache;
  final DashboardEnquiryTabActions actions;
  final Widget Function(BuildContext context, Object error) errorBuilder;
  final VoidCallback? onTabVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (onTabVisible != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onTabVisible!());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .read(firestoreServiceProvider)
          .watchEnquiriesForRole(isAdmin: isAdmin, assignedToUid: userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorBuilder(context, snapshot.error!);
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawEnquiries = snapshot.data!.docs.toList();

        if (rawEnquiries.isEmpty) {
          return DashboardEmptyEnquiries(
            status: status,
            searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
            onClearSearch: searchQuery.isNotEmpty ? onClearSearch : null,
          );
        }

        final now = DateTime.now();
        List<QueryDocumentSnapshot<Object?>> preFilteredEnquiries = rawEnquiries;

        if (status == 'All') {
          preFilteredEnquiries = rawEnquiries;
        } else if (status == 'reminders') {
          preFilteredEnquiries = rawEnquiries
              .where((doc) => shouldShowReminder(doc.data() as Map<String, dynamic>, now))
              .toList(growable: false);
        } else if (status == 'in_talks') {
          preFilteredEnquiries = rawEnquiries
              .where((doc) => shouldShowInTalks(doc.data() as Map<String, dynamic>, now))
              .toList(growable: false);
        } else {
          preFilteredEnquiries = rawEnquiries
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final statusValueRaw = data['statusValue'] as String?;
                final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
                    ? statusValueRaw!.trim().toLowerCase()
                    : 'new';
                return statusValue == status.toLowerCase();
              })
              .toList(growable: false);
        }

        if (status == 'reminders') {
          preFilteredEnquiries.sort((a, b) => compareByEventDate(b, a));
        } else if (status == 'in_talks') {
          preFilteredEnquiries.sort((a, b) => compareByCreatedDate(b, a));
        } else {
          preFilteredEnquiries.sort((a, b) => compareByNearestEventDate(a, b, now));
        }

        final filteredEnquiries = searchQuery.isEmpty
            ? preFilteredEnquiries
            : preFilteredEnquiries
                  .where((doc) => matchesEnquirySearchQuery(
                        doc.data() as Map<String, dynamic>,
                        searchQuery,
                      ))
                  .toList(growable: false);

        if (searchQuery.isNotEmpty && filteredEnquiries.isEmpty) {
          return SearchEmptyState(
            query: searchQuery,
            onClearSearch: onClearSearch,
          );
        }

        final dropdownLookup = ref
            .watch(dropdownLookupProvider)
            .maybeWhen(data: (value) => value, orElse: () => null);

        return ListView.separated(
          padding: AppSpacing.space3,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredEnquiries.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space3),
          itemBuilder: (context, index) {
            final enquiry = filteredEnquiries[index];
            final enquiryData = enquiry.data() as Map<String, dynamic>;
            final enquiryId = enquiry.id;
            final enquiryModel = Enquiry.fromFirestore(enquiry);
            final customerName = (enquiryData['customerName'] as String?) ?? 'Customer';
            final phone = enquiryData['customerPhone'] as String?;
            final assignedUserId = enquiryData['assignedTo'] as String?;

            final assignedDisplayAsync = assignedUserId == null
                ? const AsyncValue.data('Unassigned')
                : ref.watch(users_providers.userDisplayNameProvider(assignedUserId));

            final assignedDisplay = assignedUserId == null
                ? 'Unassigned'
                : assignedDisplayAsync.when(
                    data: (value) => value,
                    loading: () => 'Fetching assignee…',
                    error: (_, __) => 'Unknown',
                  );

            final createdAt = parseEnquiryDateTime(enquiryData['createdAt']) ?? DateTime.now();
            final eventDate = parseEnquiryDateTime(enquiryData['eventDate']);
            final location =
                (enquiryData['eventLocation'] as String?) ?? (enquiryData['location'] as String?);
            final notes =
                (enquiryData['description'] as String?) ?? (enquiryData['notes'] as String?);

            final statusValueRaw = enquiryData['statusValue'] as String?;
            final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
                ? statusValueRaw!.trim()
                : 'new';
            final statusLabel =
                (enquiryData['statusLabel'] as String?) ??
                (dropdownLookup != null
                    ? dropdownLookup.labelForStatus(statusValue)
                    : DropdownLookup.titleCase(statusValue));
            final eventTypeValueRaw =
                (enquiryData['eventTypeValue'] ?? enquiryData['eventType']) as String?;
            final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
                ? eventTypeValueRaw!.trim()
                : 'event';
            final eventTypeLabel =
                (enquiryData['eventTypeLabel'] as String?) ??
                (dropdownLookup != null
                    ? dropdownLookup.labelForEventType(eventTypeValue)
                    : DropdownLookup.titleCase(eventTypeValue));
            final whatsappContact = enquiryData['whatsappNumber'] as String? ?? phone;
            final eventCountdownLabel = formatEventCountdownLabel(eventDate);
            final reminderCount = (enquiryData['reminderClickCount'] as int?) ?? 0;
            final isReminderTab = status == 'reminders';
            final todayStart = DateTime(now.year, now.month, now.day);
            final isPastEvent = eventDate != null &&
                DateTime(eventDate.year, eventDate.month, eventDate.day).isBefore(todayStart);
            final canMarkNotInterested = isPastEvent &&
                ['in_talks', 'new', 'quote_sent'].contains(statusValue.toLowerCase());
            final statusColorHex =
                (enquiryData['statusColorHex'] as String?) ??
                (enquiryData['statusColor'] as String?);
            final eventColorHex =
                (enquiryData['eventColorHex'] as String?) ?? (enquiryData['eventColor'] as String?);
            final statusColorOverride =
                colorFromDynamic(enquiryData['statusColorValue']) ??
                colorFromDynamic(enquiryData['statusColorInt']) ??
                colorFromDynamic(statusColorHex) ??
                colorFromDynamic(enquiryData['statusColor']) ??
                statusColorCache[statusValue.toLowerCase()];
            final eventColorOverride =
                colorFromDynamic(enquiryData['eventColorValue']) ??
                colorFromDynamic(enquiryData['eventColorInt']) ??
                colorFromDynamic(eventColorHex) ??
                colorFromDynamic(enquiryData['eventColor']) ??
                eventColorCache[eventTypeValue.toLowerCase()];

            if (kDebugMode) {
              Log.d(
                'Enquiry tile data snapshot',
                data: {
                  'enquiryId': enquiryId,
                  'status': statusValue,
                  'eventType': eventTypeValue,
                  'hasStatusColor': statusColorHex != null || statusColorOverride != null,
                  'hasEventColor': eventColorHex != null || eventColorOverride != null,
                },
              );
            }

            String? reminderPrefill;
            if (isReminderTab && whatsappContact != null) {
              reminderPrefill = buildReminderMessage(
                customerName,
                eventTypeLabel,
                createdAt,
                eventDate,
              );
            }

            return EnquiryTileStatusStrip(
              name: customerName,
              status: statusLabel,
              eventType: eventTypeLabel,
              eventCountdownLabel: eventCountdownLabel,
              ageLabel: formatAgeLabel(createdAt),
              assignee: assignedDisplay,
              dateLabel: formatDateLabel(eventDate),
              location: location,
              notes: notes,
              phoneNumber: phone,
              whatsappNumber: whatsappContact,
              statusColorHex: statusColorHex,
              eventColorHex: eventColorHex,
              statusColorOverride: statusColorOverride,
              eventColorOverride: eventColorOverride,
              whatsappPrefill: reminderPrefill ?? 'Hi $customerName, this is from We Decor.',
              onView: () => actions.onView(enquiryId),
              enquiryId: enquiryId,
              onCall: phone == null ? null : () => actions.onCall(phone, customerName, enquiryId),
              onWhatsApp: whatsappContact == null
                  ? null
                  : (isReminderTab
                        ? () => actions.onReminderWhatsApp(
                            whatsappContact,
                            customerName,
                            enquiryId,
                            eventTypeLabel,
                            createdAt,
                            eventDate,
                          )
                        : () => actions.onWhatsApp(whatsappContact, customerName, enquiryId)),
              onUpdateStatus: () => actions.onUpdateStatus(enquiryModel),
              onShare: () => actions.onShare(enquiryModel),
              onAddNote: () => actions.onAddNote(enquiryModel),
              onRequestReview: statusValue.toLowerCase() == 'completed' && phone != null
                  ? () => actions.onReviewRequest(phone, customerName, enquiryId)
                  : null,
              reminderCount: isReminderTab ? reminderCount : null,
              isPastEvent: canMarkNotInterested,
              onMarkNotInterested: canMarkNotInterested && userId != null
                  ? () => actions.onMarkNotInterested(enquiryId, userId!)
                  : null,
            );
          },
        );
      },
    );
  }
}
