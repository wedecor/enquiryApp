import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';
import '../domain/pipeline_metrics.dart';
import 'analytics_controller.dart';

/// Which date places an enquiry in the selected period (Enquiry date by default).
final analyticsAttributionProvider = StateProvider<AnalyticsAttribution>(
  (ref) => AnalyticsAttribution.enquiryDate,
);

/// Pipeline / team / money analytics for the current analytics filters.
///
/// Re-computes whenever the main analytics controller reloads (filters,
/// refresh) or the attribution toggle changes.
final pipelineReportProvider = FutureProvider.autoDispose<PipelineReport>((ref) async {
  final analytics = await ref.watch(analyticsControllerProvider.future);
  final attribution = ref.watch(analyticsAttributionProvider);
  final repository = ref.watch(analyticsRepositoryProvider);

  final rows = await repository.fetchAllEnquiriesRaw();
  final filtered = rows.where((r) => matchesAnalyticsFilters(r, analytics.filters)).toList();

  return buildPipelineReport(
    allRows: filtered,
    start: analytics.filters.dateRange.start,
    end: analytics.filters.dateRange.end,
    attribution: attribution,
    now: DateTime.now(),
  );
});

/// Applies the non-date analytics filters (event type, status, priority, source)
/// client-side, with legacy status values resolved to canonical.
bool matchesAnalyticsFilters(Map<String, dynamic> row, AnalyticsFilters filters) {
  bool matches(String? filter, String primary, String legacy) {
    if (filter == null || filter.isEmpty) return true;
    final value = (row[primary] ?? row[legacy])?.toString().trim();
    return value == filter;
  }

  if (filters.status != null && filters.status!.isNotEmpty) {
    final rowStatus = EnquiryStatus.canonicalValue(row['statusValue'] as String?);
    if (rowStatus != EnquiryStatus.canonicalValue(filters.status)) return false;
  }
  return matches(filters.eventType, 'eventTypeValue', 'eventType') &&
      matches(filters.priority, 'priorityValue', 'priority') &&
      matches(filters.source, 'sourceValue', 'source');
}
