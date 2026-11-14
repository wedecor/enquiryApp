import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../domain/timing_metrics.dart';
import 'analytics_controller.dart';

/// Timing tab report: period from Analytics filters; season uses all rows.
final timingReportProvider = FutureProvider.autoDispose<TimingReport>((ref) async {
  final analytics = await ref.watch(analyticsControllerProvider.future);
  final rows = await ref.watch(analyticsRawRowsProvider.future);
  final filtered = rows.where((r) => matchesAnalyticsFilters(r, analytics.filters)).toList();
  final range = analytics.filters.dateRange;
  return buildTimingReport(
    allRows: filtered,
    start: range.start,
    end: range.end,
    now: DateTime.now(),
  );
});
