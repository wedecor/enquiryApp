import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/tinted_icon_badge.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../domain/occasion_kind.dart';
import '../../domain/occasion_reminder.dart';
import '../reengagement_actions.dart';

enum _RowMenu { markSent, skip, dontRemind }

/// One upcoming occasion: customer, occasion ("2nd wedding anniversary · 12 Dec"),
/// last year's event type, and WhatsApp / Mark sent / Skip / Don't remind again.
class OccasionRow extends ConsumerWidget {
  const OccasionRow({super.key, required this.reminder});

  final OccasionReminder reminder;

  static IconData iconFor(OccasionKind kind) {
    switch (kind) {
      case OccasionKind.weddingAnniversary:
      case OccasionKind.anniversary:
        return Icons.favorite_border_rounded;
      case OccasionKind.birthday:
        return Icons.cake_outlined;
      case OccasionKind.baby:
        return Icons.child_care_outlined;
      case OccasionKind.home:
        return Icons.home_outlined;
      case OccasionKind.corporate:
        return Icons.business_center_outlined;
      case OccasionKind.celebration:
        return Icons.event_repeat_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final canOpen = ReengagementActions.canOpenEnquiry(ref, reminder);

    return Pressable(
      onTap: canOpen ? () => ReengagementActions.openEnquiry(context, reminder) : null,
      borderRadius: AppRadius.medium,
      semanticLabel: '${reminder.customerName}, ${reminder.occasionText}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        child: Row(
          children: [
            TintedIconBadge(icon: iconFor(reminder.kind), size: 36),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reminder.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reminder.occasionText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                  Text(
                    'Last year: ${reminder.eventTypeLabel}',
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
              onPressed: reminder.customerPhone == null
                  ? null
                  : () => ReengagementActions.sendWhatsApp(context, ref, reminder),
            ),
            PopupMenuButton<_RowMenu>(
              tooltip: 'More',
              icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
              onSelected: (choice) {
                switch (choice) {
                  case _RowMenu.markSent:
                    ReengagementActions.markSent(context, ref, reminder);
                  case _RowMenu.skip:
                    ReengagementActions.skip(context, ref, reminder);
                  case _RowMenu.dontRemind:
                    ReengagementActions.dontRemindAgain(context, ref, reminder);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _RowMenu.markSent,
                  child: ListTile(
                    leading: Icon(Icons.check_rounded),
                    title: Text('Mark sent'),
                    subtitle: Text('Already wished them'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _RowMenu.skip,
                  child: ListTile(
                    leading: Icon(Icons.skip_next_outlined),
                    title: Text('Skip'),
                    subtitle: Text('Not this year'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _RowMenu.dontRemind,
                  child: ListTile(
                    leading: Icon(Icons.notifications_off_outlined),
                    title: Text("Don't remind again"),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
