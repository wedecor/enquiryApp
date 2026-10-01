import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';

/// Event panel: a hero date tile beside stacked guest/budget tiles, then the
/// remaining attributes as eyebrow/value pairs.
class EventDetailsSection extends StatelessWidget {
  const EventDetailsSection({
    super.key,
    required this.eventTypeLabel,
    required this.eventDate,
    required this.guestCount,
    required this.budgetRange,
    required this.priorityLabel,
    required this.sourceLabel,
  });

  final String eventTypeLabel;
  final dynamic eventDate;
  final dynamic guestCount;
  final String? budgetRange;
  final String priorityLabel;
  final String sourceLabel;

  DateTime? get _date {
    final value = eventDate;
    final date = value is Timestamp ? value.toDate() : (value is DateTime ? value : null);
    if (date == null || date.year <= 1971) return null;
    return date;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else {
      return value.toString();
    }
    if (date.year <= 1971) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return EnquiryDetailSection(
      eyebrow: 'The celebration',
      title: 'Event Details',
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _DateHero(date: _date, fallback: _formatDate(eventDate)),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(
                      child: _MiniTile(
                        label: 'Guest Count',
                        value: '${guestCount ?? 'N/A'}',
                        unit: 'guests',
                      ),
                    ),
                    const SizedBox(height: AppTokens.space3),
                    Expanded(
                      child: _MiniTile(label: 'Budget Range', value: budgetRange ?? 'N/A'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space5),
        EnquiryInfoGrid(
          children: [
            EnquiryDetailInfoRow(label: 'Event Type', value: eventTypeLabel),
            EnquiryDetailInfoRow(label: 'Priority', value: priorityLabel),
            EnquiryDetailInfoRow(label: 'Source', value: sourceLabel),
          ],
        ),
      ],
    );
  }
}

class _DateHero extends StatelessWidget {
  const _DateHero({required this.date, required this.fallback});

  final DateTime? date;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final d = date;

    return GlassPanel(
      strong: true,
      tint: s.accent.withValues(alpha: 0.10),
      borderRadius: AppRadius.large,
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Eyebrow('Event Date', accent: true),
          const SizedBox(height: AppTokens.space3),
          if (d == null)
            Text(
              fallback,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            )
          else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${d.day}',
                style: AppTypography.numeral.copyWith(fontSize: 52, color: cs.onSurface),
              ),
            ),
            const SizedBox(height: AppTokens.space1),
            Text(
              DateFormat('MMM yyyy').format(d).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
            Text(
              DateFormat('EEEE').format(d),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w300,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return GlassPanel(
      strong: true,
      borderRadius: AppRadius.large,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Eyebrow(label),
          const SizedBox(height: AppTokens.space1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
