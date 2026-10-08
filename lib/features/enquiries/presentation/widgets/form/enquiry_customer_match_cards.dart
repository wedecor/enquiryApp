import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/components/tinted_icon_badge.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../data/customer_lookup_service.dart';

/// "{eventType} · {date} · {status}" for a customer's enquiry.
String customerEventSummary(CustomerEvent event) => [
  event.eventType,
  if (event.eventDate != null && event.eventDate!.year > 1971)
    DateFormat('d MMM yyyy').format(event.eventDate!),
  event.statusLabel,
].join(' · ');

/// Shown under the phone field when the number belongs to an existing customer.
class ExistingCustomerCard extends StatelessWidget {
  const ExistingCustomerCard({super.key, required this.result, this.onUseDetails});

  final CustomerLookupResult result;

  /// Null hides the button (nothing left to fill).
  final VoidCallback? onUseDetails;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final name = result.customer?.name ?? 'Customer';
    final n = result.totalEvents;
    final earlier = n == 0 ? 'no other events' : '$n earlier event${n == 1 ? '' : 's'}';

    return _MatchPanel(
      tint: AppColorScheme.info,
      icon: Icons.person_search_outlined,
      title: 'Existing customer · $name',
      subtitle: earlier,
      action: onUseDetails == null
          ? null
          : TextButton(onPressed: onUseDetails, child: const Text('Use details')),
      titleStyle: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      subtitleStyle: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    );
  }
}

/// Warns that the customer already has an open enquiry (likely a duplicate).
class OpenEnquiryWarningCard extends StatelessWidget {
  const OpenEnquiryWarningCard({
    super.key,
    required this.customerName,
    required this.openEvents,
    required this.onOpen,
    required this.onDismiss,
  });

  final String customerName;

  /// Open enquiries, newest first (non-empty).
  final List<CustomerEvent> openEvents;
  final ValueChanged<CustomerEvent> onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final first = openEvents.first;
    final assignee = first.assignedToName;
    final more = openEvents.length - 1;

    return _MatchPanel(
      tint: AppColorScheme.warning,
      icon: Icons.warning_amber_rounded,
      title: '$customerName already has an open enquiry',
      subtitle: [
        '${customerEventSummary(first)}${assignee != null ? ' (assigned to $assignee)' : ''}',
        if (more > 0) '+$more more open',
      ].join('\n'),
      titleStyle: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      subtitleStyle: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      action: Wrap(
        spacing: AppTokens.space2,
        children: [
          TextButton(onPressed: () => onOpen(first), child: const Text('Open it')),
          TextButton(onPressed: onDismiss, child: const Text('This is a different event')),
        ],
      ),
    );
  }
}

class _MatchPanel extends StatelessWidget {
  const _MatchPanel({
    required this.tint,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.titleStyle,
    this.subtitleStyle,
  });

  final Color tint;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: GlassPanel(
        strong: true,
        tint: tint.withValues(alpha: 0.08),
        borderColor: tint.withValues(alpha: 0.28),
        borderRadius: AppRadius.medium,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space3,
          AppTokens.space3,
          AppTokens.space3,
          AppTokens.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TintedIconBadge(icon: icon, color: tint, size: 32),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      const SizedBox(height: 2),
                      Text(subtitle, style: subtitleStyle),
                    ],
                  ),
                ),
              ],
            ),
            if (action != null) Align(alignment: Alignment.centerRight, child: action),
          ],
        ),
      ),
    );
  }
}
