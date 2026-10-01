import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// One timeline entry: a type-tinted node on a hairline rail and a glass
/// card with time-ago eyebrow, title and body. Unread entries carry a pulsing
/// dot. Swipe end-to-start calls [onDismiss].
class NotificationTimelineTile extends StatelessWidget {
  const NotificationTimelineTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.isFirst = false,
    this.isLast = false,
  });

  static const double _railWidth = 44;
  static const double _nodeSize = 40;
  static const double _nodeTop = AppTokens.space3;

  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    final isRead = notification['read'] == true;
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final type = notification['data']?['type'] as String? ?? notification['type'] as String? ?? '';
    final createdAt = _parseDate(notification['createdAt']);
    final tone = _iconColor(type, cs);
    const nodeCenter = _nodeTop + _nodeSize / 2;

    return Dismissible(
      key: Key(notification['id'] as String? ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Padding(
        padding: const EdgeInsets.only(left: _railWidth + AppTokens.space2, bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(color: cs.errorContainer, borderRadius: AppRadius.large),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: AppTokens.space5),
              child: Icon(Icons.delete_outline_rounded, color: cs.onErrorContainer),
            ),
          ),
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Stack(
        children: [
          if (!(isFirst && isLast))
            Positioned(
              left: _railWidth / 2 - 0.75,
              width: 1.5,
              top: isFirst ? nodeCenter : 0,
              bottom: isLast ? null : 0,
              height: isLast ? nodeCenter : null,
              child: ColoredBox(color: s.microBorderStrong),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _railWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(top: _nodeTop),
                    child: Center(
                      child: Container(
                        width: _nodeSize,
                        height: _nodeSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.alphaBlend(tone.withValues(alpha: 0.14), cs.surface),
                          border: Border.all(color: tone.withValues(alpha: isRead ? 0.2 : 0.45)),
                        ),
                        child: Icon(_iconFor(type), size: 19, color: tone),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Pressable(
                    onTap: onTap,
                    borderRadius: AppRadius.large,
                    pressedScale: 0.985,
                    child: GlassPanel(
                      strong: !isRead,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: createdAt != null
                                    ? Eyebrow(_relativeTime(createdAt), accent: !isRead)
                                    : const SizedBox.shrink(),
                              ),
                              if (!isRead) StatusDot(color: s.accent, pulse: true),
                            ],
                          ),
                          if (createdAt != null || !isRead) const SizedBox(height: 6),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w300,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'new_enquiry' => Icons.fiber_new_outlined,
      'enquiry_assigned' || 'assignment' => Icons.assignment_ind_outlined,
      'status_update' || 'statusChange' => Icons.update_outlined,
      'enquiry_updated' || 'enquiryUpdate' => Icons.edit_note_outlined,
      'payment_update' || 'paymentUpdate' => Icons.payments_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  Color _iconColor(String type, ColorScheme cs) {
    return switch (type) {
      'new_enquiry' => AppColorScheme.statusColorFor('new'),
      'enquiry_assigned' || 'assignment' => cs.primary,
      'status_update' || 'statusChange' => AppColorScheme.statusColorFor('approved'),
      'payment_update' || 'paymentUpdate' => AppColorScheme.statusColorFor('completed'),
      _ => cs.secondary,
    };
  }

  DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
