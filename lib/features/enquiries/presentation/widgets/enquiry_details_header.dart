import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'contact_buttons.dart';
import 'enquiry_round_action.dart';
import 'enquiry_sheet_header.dart';
import 'review_request_button.dart';

/// Expanding sheet header for enquiry details: event eyebrow, customer name,
/// enquiry reference, live status and round contact actions.
class EnquiryDetailsHeader extends StatelessWidget {
  const EnquiryDetailsHeader({
    super.key,
    required this.enquiryId,
    required this.customerName,
    required this.customerPhone,
    required this.location,
    required this.eventTypeLabel,
    required this.eventDate,
    required this.statusValue,
    required this.statusLabel,
    this.actions = const [],
  });

  final String enquiryId;
  final String customerName;
  final String? customerPhone;
  final String? location;
  final String eventTypeLabel;
  final DateTime? eventDate;
  final String statusValue;
  final String statusLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final textScale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0);
    final statusColor = AppColorScheme.statusColorFor(statusValue);
    final date = eventDate;
    final shortId = enquiryId.length > 8 ? enquiryId.substring(0, 8) : enquiryId;
    final place = location?.trim();

    return EnquirySheetHeader(
      title: customerName,
      eyebrow: [
        eventTypeLabel,
        if (date != null && date.year > 1971) DateFormat('d MMM yyyy').format(date),
      ].join(' · '),
      subtitle: [
        'Enquiry #$shortId',
        if (place != null && place.isNotEmpty && place != 'N/A') place,
      ].join(' · '),
      tint: statusColor,
      actions: actions,
      meta: Row(
        children: [
          StatusDot(color: statusColor, size: 9, pulse: statusValue == 'new'),
          const SizedBox(width: AppTokens.space2),
          Flexible(
            child: Text(
              statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      footerHeight: EnquiryRoundAction.circleSize + 6 + 18 * textScale,
      footer: Wrap(
        spacing: AppTokens.space2,
        runSpacing: AppTokens.space2,
        children: [
          ContactButtons(
            customerPhone: customerPhone,
            customerName: customerName,
            enquiryId: enquiryId,
            eventType: eventTypeLabel,
            eventDate: eventDate,
          ),
          if (statusValue == 'completed')
            ReviewRequestButton(
              customerPhone: customerPhone,
              customerName: customerName,
              enquiryId: enquiryId,
            ),
        ],
      ),
    );
  }
}
