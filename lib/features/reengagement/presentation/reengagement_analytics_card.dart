import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../admin/analytics/data/analytics_repository.dart';
import '../../admin/analytics/domain/pipeline_metrics.dart';
import '../../admin/analytics/presentation/analytics_controller.dart';
import '../../admin/analytics/presentation/widgets/analytics_section_card.dart';
import '../../admin/analytics/presentation/widgets/pipeline_sections.dart';
import '../data/reengagement_repository.dart';
import '../domain/reengagement_stats.dart';

/// Yearly-reminder results for the analytics period: wishes sent and customers
/// who came back (new enquiry from the same phone within 60 days of the wish).
/// Computed in memory from the cached enquiry rows + the period's sent reminders.
final reengagementAnalyticsProvider = FutureProvider.autoDispose<ReengagementStats>((ref) async {
  final analytics = await ref.watch(analyticsControllerProvider.future);
  final range = analytics.filters.dateRange;
  final rows = await ref.watch(analyticsRawRowsProvider.future);
  final sent = await ref.read(reengagementRepositoryProvider).fetchSent(range.start, range.end);
  final arrivals = <EnquiryArrival>[];
  for (final row in rows) {
    final createdAt = metricDate(row['createdAt']);
    if (createdAt == null) continue;
    final stored = row['phoneNormalized'];
    final phone = stored is String && stored.isNotEmpty
        ? stored
        : normalizePhone(row['customerPhone'] as String?);
    if (phone.isEmpty) continue;
    arrivals.add(EnquiryArrival(phoneNormalized: phone, createdAt: createdAt));
  }
  return ReengagementStats.compute(sent: sent, enquiries: arrivals);
});

/// "Re-engagement" card (Analytics → Team). Hidden while loading / on error.
class ReengagementAnalyticsCard extends ConsumerWidget {
  const ReengagementAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(reengagementAnalyticsProvider).valueOrNull;
    if (stats == null) return const SizedBox.shrink();
    final rate = stats.customers == 0 ? '—' : '${(stats.comeBackRate * 100).round()}%';
    return AnalyticsSectionCard(
      eyebrow: 'Same time next year',
      title: 'Re-engagement',
      subtitle: 'Yearly wishes sent in this period and customers who enquired again within 60 days',
      child: Wrap(
        spacing: AppTokens.space6,
        runSpacing: AppTokens.space4,
        children: [
          MiniStat(label: 'Wishes sent', value: '${stats.sent}'),
          MiniStat(label: 'Came back', value: '${stats.cameBack}'),
          MiniStat(label: 'Come-back rate', value: rate),
        ],
      ),
    );
  }
}
