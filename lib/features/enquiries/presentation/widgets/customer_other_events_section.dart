import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../data/customer_lookup_service.dart';
import 'enquiry_detail_section.dart';
import 'enquiry_status_parts.dart';

/// "Other events for this customer": the customer's other enquiries (same
/// normalized phone), fetched server-side. Renders nothing when there are none
/// or the lookup failed.
class CustomerOtherEventsSection extends ConsumerWidget {
  const CustomerOtherEventsSection({
    super.key,
    required this.enquiryId,
    required this.customerPhone,
    required this.onOpenEvent,
  });

  final String enquiryId;
  final String customerPhone;

  /// Called when a row is tapped (the caller checks access).
  final ValueChanged<CustomerEvent> onOpenEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref
        .watch(customerOtherEventsProvider((phone: customerPhone, excludeEnquiryId: enquiryId)))
        .valueOrNull;
    final events = result?.events ?? const <CustomerEvent>[];
    if (events.isEmpty) return const SizedBox.shrink();

    return EnquiryDetailSection(
      eyebrow: 'Same customer',
      title: 'Other events for this customer',
      children: [
        for (var i = 0; i < events.length; i++) ...[
          if (i > 0) const Divider(height: AppTokens.space2),
          _EventRow(event: events[i], onTap: () => onOpenEvent(events[i])),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});

  final CustomerEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final date = event.eventDate;
    final title = [
      event.eventType,
      if (date != null && date.year > 1971) DateFormat('d MMM yyyy').format(date),
    ].join(' · ');
    final assignee = event.assignedToName;

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      semanticLabel: '$title, ${event.statusLabel}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (assignee != null)
                    Text(
                      'Assigned to $assignee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space2),
            Flexible(
              child: EnquiryStatusChip(
                label: event.statusLabel,
                color: AppColorScheme.statusColorFor(event.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
