import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/analytics_models.dart';
import 'analytics_format.dart';
import 'analytics_section_card.dart';

/// Recent enquiries as stacked typographic rows: date, customer and cost, then
/// event type · source, then status and priority dots.
class RecentEnquiriesTable extends ConsumerWidget {
  final List<RecentEnquiry> data;
  final String title;
  final int maxItems;

  const RecentEnquiriesTable({
    super.key,
    required this.data,
    required this.title,
    this.maxItems = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    final displayData = data.take(maxItems).toList();
    return AnalyticsSectionCard(
      eyebrow: 'Latest',
      title: title,
      child: data.isEmpty
          ? const AnalyticsEmptyState(
              icon: Icons.table_rows_rounded,
              message: 'No recent enquiries',
              hint: 'Select a different date range or filters',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < displayData.length; i++)
                  StaggerIn(
                    index: i,
                    child: _RecentRow(enquiry: displayData[i], lookup: dropdownLookup),
                  ),
              ],
            ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.enquiry, required this.lookup});

  final RecentEnquiry enquiry;
  final DropdownLookup? lookup;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);

    final eventType =
        lookup?.labelForEventType(enquiry.eventType) ?? DropdownLookup.titleCase(enquiry.eventType);
    final source =
        lookup?.labelForSource(enquiry.source) ?? DropdownLookup.titleCase(enquiry.source);
    final status = lookup?.labelForStatus(enquiry.status) ?? formatStatusName(enquiry.status);
    final priority =
        lookup?.labelForPriority(enquiry.priority) ?? _formatPriorityName(enquiry.priority);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: AppTokens.space2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatDate(enquiry.date),
                  maxLines: 1,
                  style: t.labelSmall?.copyWith(
                    color: s.accentInk,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        enquiry.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space2),
                    Text(
                      enquiry.totalCost != null ? formatAnalyticsCurrency(enquiry.totalCost!) : '—',
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$eventType · $source',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Wrap(
                  spacing: AppTokens.space4,
                  runSpacing: AppTokens.space1,
                  children: [
                    _Tag(color: AppColorScheme.statusColorFor(enquiry.status), label: status),
                    _Tag(color: _getPriorityColor(enquiry.priority), label: priority),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year % 100}';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColorScheme.chartRed;
      case 'medium':
        return AppColorScheme.chartAmber;
      case 'low':
        return AppColorScheme.chartGreen;
      default:
        return AppColorScheme.neutralGrey;
    }
  }

  String _formatPriorityName(String priority) {
    return priority.isNotEmpty
        ? priority[0].toUpperCase() + priority.substring(1).toLowerCase()
        : priority;
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, size: 7),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
