import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/tinted_icon_badge.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../domain/past_customer_occasion.dart';
import '../reengagement_actions.dart';
import 'occasion_row.dart';

/// One past customer: name, next occasion ("2nd wedding anniversary · 12 Dec"),
/// when it is and the original event type, plus a WhatsApp wish button.
class PastCustomerRowTile extends ConsumerWidget {
  const PastCustomerRowTile({super.key, required this.row});

  final PastCustomerRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final source = row.source;

    return Pressable(
      onTap: () => ReengagementActions.openEnquiryById(context, source.enquiryId),
      borderRadius: AppRadius.medium,
      semanticLabel: '${source.customerName}, ${row.occasionText}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        child: Row(
          children: [
            TintedIconBadge(icon: OccasionRow.iconFor(source.kind), size: 36),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    source.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.occasionText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                  Text(
                    '${row.whenText} · ${source.eventTypeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Send wish on WhatsApp',
              icon: const Icon(Icons.chat_bubble_outline, color: AppColorScheme.whatsApp),
              onPressed: source.customerPhone == null
                  ? null
                  : () => ReengagementActions.sendPastWhatsApp(context, ref, row),
            ),
          ],
        ),
      ),
    );
  }
}
