import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/status_vocabulary.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/status_colors.dart';
import '../primitives/primitives.dart';

/// The single shared enquiry list item — used by the dashboard, the enquiries
/// list/search results, the calendar day view and Kanban columns. Do not build
/// an enquiry row layout anywhere else; wrap this widget instead.
///
/// A floating glass tile with an asymmetric layout:
///
///   ┌────┐  Customer name                     ● New
///   │ 12 │  Baby Shower · Whitefield
///   │OCT │  16m old · mohammed zakir
///   └────┘
///
/// Pass [eventDate] to get the typographic date block; otherwise the
/// [eventDateLabel] text is shown in its place.
class EnquiryListRow extends StatelessWidget {
  const EnquiryListRow({
    super.key,
    required this.customerName,
    required this.statusValue,
    required this.eventTypeLabel,
    required this.eventDateLabel,

    /// Raw event type key (e.g. 'wedding', 'haldi').
    this.eventTypeValue,
    this.eventDate,
    this.statusLabel,
    this.statusColor,
    this.firestoreStatusColors,
    this.location,
    this.ageLabel,
    this.assigneeLabel,
    this.secondaryMeta,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
    this.showStatusChip = true,
    this.locationPending = false,
    this.showChevron = true,
    this.bordered = false,
    this.margin,
  });

  final String customerName;
  final String statusValue;
  final String eventTypeLabel;
  final String eventDateLabel;
  final String? eventTypeValue;
  final DateTime? eventDate;
  final String? statusLabel;
  final Color? statusColor;
  final Map<String, Color>? firestoreStatusColors;

  final String? location;
  final String? ageLabel;
  final String? assigneeLabel;

  /// Dot-joined fallback shown only when [ageLabel]/[assigneeLabel] are null.
  final String? secondaryMeta;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool compact;

  /// Hide where the status is already implied (e.g. inside a Kanban column).
  final bool showStatusChip;

  /// Approved without a known location: a small "Location pending" pill on line 2.
  final bool locationPending;

  /// Kept for call-site compatibility; the tile has no chevron.
  final bool showChevron;

  /// Tighter tile for dense containers such as Kanban columns.
  final bool bordered;

  /// Outer spacing; defaults depend on [bordered].
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dotColor =
        statusColor ??
        resolveStatusColor(context, statusValue, firestoreColors: firestoreStatusColors);
    final label = statusLabel ?? _formatStatusLabel(statusValue);
    final isNew = EnquiryStatus.fromValue(statusValue) == EnquiryStatus.newEnquiry;

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

    final radius = bordered ? AppRadius.medium : AppRadius.large;
    final pad = bordered ? AppTokens.space3 : AppTokens.space4;

    final content = Padding(
      padding: EdgeInsets.all(pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DateBlock(
            date: eventDate,
            fallback: eventDateLabel,
            accent: dotColor,
            compact: bordered,
          ),
          SizedBox(width: bordered ? AppTokens.space3 : AppTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (showStatusChip) ...[
                      const SizedBox(width: AppTokens.space2),
                      _StatusLabel(label: label, color: dotColor, pulse: isNew),
                    ],
                  ],
                ),
                if (line2.isNotEmpty || locationPending) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          line2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      if (locationPending) ...[
                        const SizedBox(width: AppTokens.space2),
                        const _LocationPendingPill(),
                      ],
                    ],
                  ),
                ],
                if (showMeta) ...[
                  const SizedBox(height: 4),
                  Text(
                    line3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding:
          margin ??
          (bordered
              ? const EdgeInsets.only(bottom: AppTokens.space2)
              : const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: 5)),
      child: Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: GlassPanel(
          strong: true,
          borderRadius: radius,
          tint: dotColor.withValues(alpha: 0.05),
          child: content,
        ),
      ),
    );
  }

  static String _formatStatusLabel(String value) {
    final canonical = EnquiryStatus.fromValue(value);
    if (canonical != null) return canonical.label;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

/// Day number (heavy) over a tracked month (whisper) — or the raw label when
/// no [date] is supplied.
class _DateBlock extends StatelessWidget {
  const _DateBlock({
    required this.date,
    required this.fallback,
    required this.accent,
    required this.compact,
  });

  final DateTime? date;
  final String fallback;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    final size = compact ? 44.0 : 52.0;

    final Widget inner;
    if (date != null) {
      inner = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('d').format(date!),
            style: t.titleLarge?.copyWith(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.8,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMM').format(date!).toUpperCase(),
            style: t.labelSmall?.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.6,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else {
      inner = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            fallback.trim().isEmpty ? '—' : fallback.trim(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.15),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.14), accent.withValues(alpha: 0.03)],
        ),
        border: Border.all(color: s.microBorder),
      ),
      child: inner,
    );
  }
}

/// Amber "Location pending" pill for approved enquiries without an area.
class _LocationPendingPill extends StatelessWidget {
  const _LocationPendingPill();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? AppColorScheme.warningDark
        : AppColorScheme.onWarningContainerLight;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.10),
        borderRadius: AppRadius.full,
        border: Border.all(color: ink.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2, vertical: 1),
        child: Text(
          'Location pending',
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Status as a glowing dot + label — the tile's only saturated colour.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.color, required this.pulse});

  final String label;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(color: color, size: 7, pulse: pulse),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
