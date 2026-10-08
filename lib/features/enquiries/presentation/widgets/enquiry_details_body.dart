import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/enquiry_fields.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/enquiry_history_widget.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../reengagement/presentation/widgets/yearly_reminder_card.dart';
import '../../data/customer_lookup_service.dart';
import '../../domain/enquiry_lifecycle.dart';
import '../../domain/enquiry_location.dart';
import 'customer_info_section.dart';
import 'customer_other_events_section.dart';
import 'enquiry_assignment_section.dart';
import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';
import 'enquiry_display_labels.dart';
import 'enquiry_images_section.dart';
import 'event_details_section.dart';
import 'payment_section.dart';

/// Sliver list of the enquiry detail sections, cascading in on first build.
class EnquiryDetailsBody extends StatelessWidget {
  const EnquiryDetailsBody({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.labels,
    required this.userRole,
    required this.currentUserId,
    required this.canViewImages,
    required this.bottomClearance,
    this.onAddEvent,
    this.onOpenCustomerEvent,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final EnquiryDisplayLabels labels;
  final UserRole? userRole;
  final String currentUserId;
  final bool canViewImages;
  final double bottomClearance;

  /// "Add another event" for this customer (admins only).
  final VoidCallback? onAddEvent;

  /// Opens one of the customer's other enquiries; null hides that section.
  final ValueChanged<CustomerEvent>? onOpenCustomerEvent;

  static const double _maxContentWidth = 760;

  @override
  Widget build(BuildContext context) {
    final images = (enquiryData['images'] as List?)?.cast<dynamic>() ?? const [];
    final customerPhone = (enquiryData['customerPhone'] as String?)?.trim() ?? '';
    final width = MediaQuery.sizeOf(context).width;
    final side = ((width - _maxContentWidth) / 2).clamp(AppTokens.space4, double.infinity);

    final place = EnquiryPlace.fromData(enquiryData);
    final sections = <Widget>[
      EventDetailsSection(
        eventTypeLabel: labels.eventTypeLabel,
        eventDate: enquiryData['eventDate'],
        guestCount: enquiryData['guestCount'],
        budgetRange: enquiryData['budgetRange'] as String?,
        priorityLabel: labels.priorityLabel,
        sourceLabel: labels.sourceLabel,
      ),
      if (userRole == UserRole.admin)
        PaymentSection(
          totalCost: enquiryData['totalCost'],
          advancePaid: enquiryData['advancePaid'],
          paymentStatusLabel: labels.paymentStatusLabel,
        ),
      if (_outcomeRows(isAdmin: userRole == UserRole.admin).isNotEmpty)
        EnquiryDetailSection(
          eyebrow: 'Outcome',
          title: 'Quote & Outcome',
          children: _outcomeRows(isAdmin: userRole == UserRole.admin),
        ),
      if (EnquiryStatus.fromValue(enquiryData['statusValue'] as String?) ==
          EnquiryStatus.completed)
        YearlyReminderCard(
          enquiryId: enquiryId,
          enquiryData: enquiryData,
          isAdmin: userRole == UserRole.admin,
        ),
      _AsymmetricPair(
        major: CustomerInfoSection(
          customerPhone: enquiryData['customerPhone'] as String?,
          location:
              (enquiryData['eventLocation'] as String?) ??
              (enquiryData['location'] as String? ?? 'N/A'),
          locationAddress: place?.address,
          mapsUri: mapsSearchUri(
            eventLocation:
                (enquiryData['eventLocation'] as String?) ?? (enquiryData['location'] as String?),
            address: place?.address,
            placeId: place?.placeId,
          ),
          onAddEvent: onAddEvent,
        ),
        minor: EnquiryAssignmentSection(
          userRole: userRole,
          assignedTo: enquiryData['assignedTo'] as String?,
          createdBy: enquiryData['createdBy'] as String?,
          currentUserId: currentUserId,
        ),
      ),
      if (onOpenCustomerEvent != null && customerPhone.isNotEmpty)
        CustomerOtherEventsSection(
          enquiryId: enquiryId,
          customerPhone: customerPhone,
          onOpenEvent: onOpenCustomerEvent!,
        ),
      if (canViewImages) EnquiryImagesSection(images: images),
      _AsymmetricPair(
        major: EnquiryDetailSection(
          eyebrow: 'In their words',
          title: 'Description',
          children: [
            EnquiryDetailInfoRow(
              label: 'Notes',
              value: enquiryNotesFrom(enquiryData) ?? 'No description provided',
              maxLines: null,
            ),
          ],
        ),
        minor: EnquiryDetailSection(
          eyebrow: 'Timeline',
          title: 'Timestamps',
          children: [
            EnquiryDetailInfoRow(
              label: 'Created',
              value: _formatTimestamp(enquiryData['createdAt']),
            ),
            EnquiryDetailInfoRow(
              label: 'Last Updated',
              value: _formatTimestamp(enquiryData['updatedAt']),
            ),
            EnquiryDetailInfoRow(
              label: 'First Contacted',
              value: enquiryData['firstContactAt'] == null
                  ? 'Not yet'
                  : '${_formatTimestamp(enquiryData['firstContactAt'])}'
                        '${enquiryData['firstContactEstimated'] == true ? ' (est.)' : ''}',
            ),
            if ((enquiryData['contactCount'] as num?) != null)
              EnquiryDetailInfoRow(
                label: 'Contacts',
                value: '${(enquiryData['contactCount'] as num).toInt()}',
              ),
          ],
        ),
      ),
      const SectionHeader(
        eyebrow: 'Audit trail',
        title: 'Change History',
        padding: EdgeInsets.fromLTRB(
          AppTokens.space1,
          AppTokens.space4,
          AppTokens.space1,
          AppTokens.space3,
        ),
      ),
      EnquiryHistoryWidget(enquiryId: enquiryId),
    ];

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(side, AppTokens.space5, side, bottomClearance),
      sliver: SliverList.builder(
        itemCount: sections.length,
        itemBuilder: (context, i) => StaggerIn(index: i, child: sections[i]),
      ),
    );
  }

  /// Quote (admin only) and lost-reason rows; empty when there is nothing to show.
  List<Widget> _outcomeRows({required bool isAdmin}) {
    final rows = <Widget>[];
    final quoted = (enquiryData['quotedAmount'] as num?)?.toDouble();
    if (isAdmin && quoted != null) {
      final at = enquiryData['quotedAt'];
      rows.add(
        EnquiryDetailInfoRow(
          label: 'Quoted',
          value: '₹${quoted.toStringAsFixed(0)}${at is Timestamp ? ' on ${_formatDate(at)}' : ''}',
        ),
      );
    }
    if (EnquiryStatus.isLost(enquiryData['statusValue'] as String?)) {
      rows.add(
        EnquiryDetailInfoRow(
          label: 'Lost reason',
          value: LostReason.labelOf(enquiryData['lostReason'] as String?),
        ),
      );
      final note = (enquiryData['lostReasonNote'] as String?)?.trim();
      if (note != null && note.isNotEmpty) {
        rows.add(EnquiryDetailInfoRow(label: 'Note', value: note, maxLines: null));
      }
    }
    return rows;
  }

  static String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute}';
    }
    return timestamp.toString();
  }
}

/// Two sections side by side at a 3:2 ratio on wide layouts, stacked on phones.
class _AsymmetricPair extends StatelessWidget {
  const _AsymmetricPair({required this.major, required this.minor});

  final Widget major;
  final Widget minor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 600) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [major, minor]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: major),
            const SizedBox(width: AppTokens.space3),
            Expanded(flex: 2, child: minor),
          ],
        );
      },
    );
  }
}
