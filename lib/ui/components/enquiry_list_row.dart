import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/status_colors.dart';
import '../../utils/event_colors.dart';

/// Scannable enquiry row — left status strip, event badge, icon meta.
///
/// Pass [location], [ageLabel], [assigneeLabel] separately for structured display.
/// Set [compact] to hide the meta row (e.g. in Kanban or condensed lists).
class EnquiryListRow extends StatelessWidget {
  const EnquiryListRow({
    super.key,
    required this.customerName,
    required this.statusValue,
    required this.eventTypeLabel,
    required this.eventDateLabel,

    /// Raw event type key (e.g. 'wedding', 'haldi') — used to derive badge color.
    this.eventTypeValue,
    this.statusLabel,
    this.statusColor,
    this.firestoreStatusColors,
    // Structured meta — preferred over secondaryMeta
    this.location,
    this.ageLabel,
    this.assigneeLabel,
    // Legacy fallback (plain dot-joined string)
    this.secondaryMeta,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final String customerName;
  final String statusValue;
  final String eventTypeLabel;
  final String eventDateLabel;
  final String? eventTypeValue;
  final String? statusLabel;
  final Color? statusColor;
  final Map<String, Color>? firestoreStatusColors;

  /// Structured meta fields — displayed with icons when non-null.
  final String? location;
  final String? ageLabel;
  final String? assigneeLabel;

  /// Legacy dot-joined fallback shown only when the structured fields are all null.
  final String? secondaryMeta;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accentColor =
        statusColor ??
        resolveStatusColor(
          context,
          statusValue,
          firestoreColors: firestoreStatusColors,
        );
    final chipLabel = statusLabel ?? _formatStatusLabel(statusValue);
    final isLight = cs.brightness == Brightness.light;

    // Subtle status-tinted card background — makes each status group scannable at a glance.
    final cardColor = isLight
        ? Color.alphaBlend(accentColor.withValues(alpha: 0.035), cs.surface)
        : cs.surfaceContainerHighest.withValues(alpha: 0.45);

    // Event type color for the inline badge.
    final eventColor = EventColors.accentFor(eventTypeValue ?? eventTypeLabel);

    // Whether the structured meta row has anything to show
    final hasStructuredMeta =
        location != null || ageLabel != null || assigneeLabel != null;
    final hasLegacyMeta =
        secondaryMeta != null && secondaryMeta!.trim().isNotEmpty;
    final showMeta = !compact && (hasStructuredMeta || hasLegacyMeta);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: Material(
        color: cardColor,
        elevation: 0,
        shadowColor: cs.shadow.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: isLight ? 0.75 : 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: isLight ? AppShadows.elevation1 : null,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Status strip ───────────────────────────────────────
                  ColoredBox(
                    color: accentColor,
                    child: const SizedBox(width: 5),
                  ),

                  // ── Content ────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space3,
                        vertical: AppTokens.space3,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Name
                                Text(
                                  customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: AppTokens.space1),

                                // Event type badge (event color) + date
                                _EventLine(
                                  eventTypeLabel: eventTypeLabel,
                                  eventDateLabel: eventDateLabel,
                                  eventColor: eventColor,
                                  cs: cs,
                                  theme: theme,
                                ),

                                // Meta row — structured fields or legacy fallback
                                if (showMeta) ...[
                                  const SizedBox(height: AppTokens.space1),
                                  if (hasStructuredMeta)
                                    _StructuredMeta(
                                      location: location,
                                      ageLabel: ageLabel,
                                      assigneeLabel: assigneeLabel,
                                      cs: cs,
                                      theme: theme,
                                    )
                                  else
                                    Text(
                                      secondaryMeta!.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.8),
                                            fontSize: AppTokens.fontSizeSmall,
                                          ),
                                    ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: AppTokens.space2),
                          _StatusChip(label: chipLabel, color: accentColor),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatStatusLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

// ─── Event line ──────────────────────────────────────────────────────────────

/// Shows event type as a small colored badge followed by the event date.
/// The badge uses [eventColor] so each event type has its own visual identity.
class _EventLine extends StatelessWidget {
  const _EventLine({
    required this.eventTypeLabel,
    required this.eventDateLabel,
    required this.eventColor,
    required this.cs,
    required this.theme,
  });

  final String eventTypeLabel;
  final String eventDateLabel;
  final Color eventColor;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasType = eventTypeLabel.trim().isNotEmpty;
    final hasDate = eventDateLabel.trim().isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasType)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: eventColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: eventColor.withValues(alpha: 0.30)),
            ),
            child: Text(
              eventTypeLabel.trim(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: eventColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (hasType && hasDate) const SizedBox(width: 6),
        if (hasDate) ...[
          Icon(
            Icons.calendar_today_outlined,
            size: 12,
            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              eventDateLabel.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Structured meta ─────────────────────────────────────────────────────────

/// Location, age, and assignee — each with a distinct icon, laid out in a Wrap.
class _StructuredMeta extends StatelessWidget {
  const _StructuredMeta({
    this.location,
    this.ageLabel,
    this.assigneeLabel,
    required this.cs,
    required this.theme,
  });

  final String? location;
  final String? ageLabel;
  final String? assigneeLabel;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final items = <_MetaItem>[];
    if (location != null && location!.trim().isNotEmpty) {
      items.add(
        _MetaItem(icon: Icons.location_on_outlined, label: location!.trim()),
      );
    }
    if (ageLabel != null && ageLabel!.trim().isNotEmpty) {
      items.add(
        _MetaItem(icon: Icons.access_time_outlined, label: ageLabel!.trim()),
      );
    }
    if (assigneeLabel != null && assigneeLabel!.trim().isNotEmpty) {
      items.add(
        _MetaItem(icon: Icons.person_outline, label: assigneeLabel!.trim()),
      );
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 3),
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.82),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _MetaItem {
  const _MetaItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ─── Status chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space2,
        vertical: AppTokens.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
