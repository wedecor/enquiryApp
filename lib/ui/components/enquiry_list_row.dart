import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/status_colors.dart';

/// The single shared enquiry list item ("EnquiryCard") — used by the dashboard,
/// the enquiries list/search results and the calendar day view. Do not build an
/// enquiry row layout anywhere else; wrap this widget instead.
///
/// Dense, table-like row: flat on the surface, separated from its neighbours by
/// a 1px bottom hairline. One colour signal per row — the status dot.
///
///   Customer name                              12 Oct 2026
///   Baby Shower · Whitefield                       ● New
///   16m old · mohammed zakir
///
/// Pass [location], [ageLabel], [assigneeLabel] separately for structured display.
/// Set [compact] to hide the meta line. Set [bordered] where rows sit on a tinted
/// background as separate cards (Kanban columns).
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
    this.showStatusChip = true,
    this.showChevron = true,
    this.bordered = false,
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

  /// Hide where the status is already implied (e.g. inside a Kanban status column).
  final bool showStatusChip;

  /// Kept for call-site compatibility; the dense row has no chevron.
  final bool showChevron;

  /// Render as a separate bordered card instead of a flat divided row.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusDotColor =
        statusColor ??
        resolveStatusColor(context, statusValue, firestoreColors: firestoreStatusColors);
    final chipLabel = statusLabel ?? _formatStatusLabel(statusValue);

    final secondary = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final tertiary = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
      fontWeight: FontWeight.w400,
    );

    final line2 = [
      eventTypeLabel.trim(),
      if (location != null && location!.trim().isNotEmpty) location!.trim(),
    ].where((s) => s.isNotEmpty).join(' · ');

    final hasStructuredMeta =
        (ageLabel?.trim().isNotEmpty ?? false) || (assigneeLabel?.trim().isNotEmpty ?? false);
    final line3 = hasStructuredMeta
        ? [
            ageLabel?.trim() ?? '',
            assigneeLabel?.trim() ?? '',
          ].where((s) => s.isNotEmpty).join(' · ')
        : (secondaryMeta?.trim() ?? '');
    final showMeta = !compact && line3.isNotEmpty;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Text(
                eventDateLabel.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          Row(
            children: [
              Expanded(
                child: Text(
                  line2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: secondary,
                ),
              ),
              if (showStatusChip) ...[
                const SizedBox(width: AppTokens.space3),
                _StatusLabel(label: chipLabel, color: statusDotColor),
              ],
            ],
          ),
          if (showMeta) ...[
            const SizedBox(height: AppTokens.space1 / 2),
            Text(line3, maxLines: 1, overflow: TextOverflow.ellipsis, style: tertiary),
          ],
        ],
      ),
    );

    if (bordered) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.space2),
        child: Material(
          color: theme.cardTheme.color ?? cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
            side: BorderSide(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, onLongPress: onLongPress, child: content),
        ),
      );
    }

    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: content,
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

/// Status as a coloured dot + plain label — the row's only colour signal.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox(width: AppTokens.space2, height: AppTokens.space2),
          ),
          const SizedBox(width: AppTokens.space1 + 2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
