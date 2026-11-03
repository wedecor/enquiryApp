import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../domain/pipeline_metrics.dart';
import 'analytics_controller.dart';

/// Which date places an enquiry in the selected period (Enquiry date by default).
final analyticsAttributionProvider = StateProvider<AnalyticsAttribution>(
  (ref) => AnalyticsAttribution.enquiryDate,
);

/// Pipeline / team / money analytics for the current analytics filters.
///
/// Re-computes whenever the main analytics controller reloads (filters,
/// refresh) or the attribution toggle changes. Rows come from the cached
/// [analyticsRawRowsProvider], so filter changes and tab hops don't re-download.
final pipelineReportProvider = FutureProvider.autoDispose<PipelineReport>((ref) async {
  final analytics = await ref.watch(analyticsControllerProvider.future);
  final attribution = ref.watch(analyticsAttributionProvider);

  final rows = await ref.watch(analyticsRawRowsProvider.future);
  final filtered = rows.where((r) => matchesAnalyticsFilters(r, analytics.filters)).toList();

  return buildPipelineReport(
    allRows: filtered,
    start: analytics.filters.dateRange.start,
    end: analytics.filters.dateRange.end,
    attribution: attribution,
    now: DateTime.now(),
  );
});
