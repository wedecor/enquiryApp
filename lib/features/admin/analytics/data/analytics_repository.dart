import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/enquiry_fields.dart';
import '../../../../services/dropdown_lookup.dart';
import '../domain/analytics_models.dart';
import '../domain/pipeline_metrics.dart';

/// Repository for analytics data from Firestore
class AnalyticsRepository {
  final FirebaseFirestore _firestore;

  AnalyticsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Count total enquiries in date range with optional filters
  Future<int> countEnquiries({required DateRange dateRange, AnalyticsFilters? filters}) async {
    try {
      // Try using aggregate query first (more efficient)
      final Query query = _buildBaseQuery(dateRange, filters);

      final aggregateQuery = query.count();
      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Fallback to regular query if aggregate fails
      final Query query = _buildBaseQuery(dateRange, filters);
      final snapshot = await query.get();
      return snapshot.docs.length;
    }
  }

  /// Every enquiry (admin view) with its document id under `id`.
  ///
  /// Used by the pipeline analytics, which need lifetime data (forecast win
  /// rate, upcoming money, open follow-ups) and apply the period client-side.
  /// Fine for a few thousand enquiries; move to precomputed snapshots beyond that.
  Future<List<Map<String, dynamic>>> fetchAllEnquiriesRaw() async {
    final snapshot = await _firestore.collection('enquiries').get();
    return snapshot.docs.map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()}).toList();
  }

  /// Fetch all enquiry documents for a period in a single query.
  Future<List<Map<String, dynamic>>> fetchEnquiriesRaw({
    required DateRange dateRange,
    AnalyticsFilters? filters,
  }) async {
    final snapshot = await _buildBaseQuery(dateRange, filters).get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)})
        .toList();
  }

  /// Get count breakdown by status
  Future<Map<String, int>> countByStatus({
    required DateRange dateRange,
    AnalyticsFilters? filters,
    List<Map<String, dynamic>>? rawData,
  }) async {
    final raw = rawData ?? await fetchEnquiriesRaw(dateRange: dateRange, filters: filters);
    return aggregateCountByStatus(raw);
  }

  /// Get count breakdown by event type
  Future<Map<String, int>> countByEventType({
    required DateRange dateRange,
    AnalyticsFilters? filters,
    List<Map<String, dynamic>>? rawData,
  }) async {
    final raw = rawData ?? await fetchEnquiriesRaw(dateRange: dateRange, filters: filters);
    return aggregateCountByEventType(raw);
  }

  /// Get count breakdown by source
  Future<Map<String, int>> countBySource({
    required DateRange dateRange,
    AnalyticsFilters? filters,
    List<Map<String, dynamic>>? rawData,
  }) async {
    final raw = rawData ?? await fetchEnquiriesRaw(dateRange: dateRange, filters: filters);
    return aggregateCountBySource(raw);
  }

  /// Get count breakdown by priority
  Future<Map<String, int>> countByPriority({
    required DateRange dateRange,
    AnalyticsFilters? filters,
    List<Map<String, dynamic>>? rawData,
  }) async {
    final raw = rawData ?? await fetchEnquiriesRaw(dateRange: dateRange, filters: filters);
    return aggregateCountByPriority(raw);
  }

  /// Generate time series data
  Future<List<SeriesPoint>> getTimeSeries({
    required DateRange dateRange,
    required TimeBucket bucket,
    AnalyticsFilters? filters,
    List<Map<String, dynamic>>? rawData,
  }) async {
    final raw = rawData ?? await fetchEnquiriesRaw(dateRange: dateRange, filters: filters);
    return aggregateTimeSeries(raw, dateRange: dateRange, bucket: bucket);
  }

  /// Sum total revenue from totalCost field.
  ///
  /// Only counts won-category enquiries.
  Future<double> sumRevenue({
    required DateRange dateRange,
    AnalyticsFilters? filters,
    List<Map<String, dynamic>>? rawData,
  }) async {
    final raw = rawData ?? await fetchEnquiriesRaw(dateRange: dateRange, filters: filters);
    return aggregateSumRevenue(raw);
  }

  static Map<String, int> aggregateCountByStatus(List<Map<String, dynamic>> raw) {
    final statusCounts = <String, int>{};

    for (final data in raw) {
      final status = EnquiryStatus.canonicalValue(data['statusValue'] as String?) ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return statusCounts;
  }

  /// Events per event type: a multi-function booking counts each function under its
  /// own type (Haldi 1, Mehendi 1, Wedding 1…); legacy enquiries count once.
  static Map<String, int> aggregateCountByEventType(List<Map<String, dynamic>> raw) {
    final eventTypeCounts = <String, int>{};

    for (final data in raw) {
      for (final f in metricFunctionsOf(data)) {
        final eventType = f.eventType.trim().isEmpty ? 'unknown' : f.eventType.trim();
        eventTypeCounts[eventType] = (eventTypeCounts[eventType] ?? 0) + 1;
      }
    }

    return eventTypeCounts;
  }

  static Map<String, int> aggregateCountBySource(List<Map<String, dynamic>> raw) {
    final sourceCounts = <String, int>{};

    for (final data in raw) {
      final source = canonicalFieldString(data, 'sourceValue', 'source');
      if (source.isEmpty) {
        sourceCounts['unknown'] = (sourceCounts['unknown'] ?? 0) + 1;
      } else {
        sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
      }
    }

    return sourceCounts;
  }

  static Map<String, int> aggregateCountByPriority(List<Map<String, dynamic>> raw) {
    final priorityCounts = <String, int>{};

    for (final data in raw) {
      final priority = canonicalFieldString(data, 'priorityValue', 'priority');
      if (priority.isEmpty) {
        priorityCounts['unknown'] = (priorityCounts['unknown'] ?? 0) + 1;
      } else {
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
      }
    }

    return priorityCounts;
  }

  static double aggregateSumRevenue(List<Map<String, dynamic>> raw) {
    double totalRevenue = 0.0;

    for (final data in raw) {
      final status = data['statusValue'] as String?;
      if (EnquiryStatus.fromValue(status)?.category != StatusCategory.won) continue;

      final totalCost = data['totalCost'];
      if (totalCost is num) {
        totalRevenue += totalCost.toDouble();
      }
    }

    return totalRevenue;
  }

  static List<SeriesPoint> aggregateTimeSeries(
    List<Map<String, dynamic>> raw, {
    required DateRange dateRange,
    required TimeBucket bucket,
  }) {
    final Map<DateTime, int> dateCounts = {};

    DateTime current = _truncateToTimeBucketStatic(dateRange.start, bucket);

    while (current.isBefore(dateRange.end)) {
      dateCounts[current] = 0;
      current = _incrementTimeBucketStatic(current, bucket);
    }

    for (final data in raw) {
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      if (createdAt != null) {
        final bucketDate = _truncateToTimeBucketStatic(createdAt, bucket);
        if (dateCounts.containsKey(bucketDate)) {
          dateCounts[bucketDate] = (dateCounts[bucketDate] ?? 0) + 1;
        }
      }
    }

    return dateCounts.entries.map((entry) => SeriesPoint(x: entry.key, count: entry.value)).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  /// Recent enquiries for table display: newest [limit] rows of [raw] by `createdAt`.
  ///
  /// Sorts in memory, so no `createdAt DESC` composite index is needed.
  static List<RecentEnquiry> aggregateRecentEnquiries(
    List<Map<String, dynamic>> raw, {
    int limit = 20,
  }) {
    DateTime? createdOf(Map<String, dynamic> row) => (row['createdAt'] as Timestamp?)?.toDate();
    final sorted = raw.where((row) => createdOf(row) != null).toList()
      ..sort((a, b) => createdOf(b)!.compareTo(createdOf(a)!));
    return sorted.take(limit).map(recentEnquiryFromRaw).toList();
  }

  /// Maps a raw enquiry row (with `id`) to a [RecentEnquiry].
  static RecentEnquiry recentEnquiryFromRaw(Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return RecentEnquiry(
      id: (data['id'] as String?) ?? '',
      date: createdAt,
      customerName: (data['customerName'] as String?) ?? 'Unknown',
      eventType: (data['eventType'] as String?) ?? 'Unknown',
      status:
          EnquiryStatus.canonicalValue(data['statusValue'] as String?) ??
          (data['statusValue'] as String?) ??
          'Unknown',
      source: (data['source'] as String?) ?? 'Unknown',
      priority: (data['priority'] as String?) ?? 'medium',
      totalCost: (data['totalCost'] as num?)?.toDouble(),
    );
  }

  /// Rows created inside [dateRange] that match the non-date [filters].
  ///
  /// Client-side equivalent of [fetchEnquiriesRaw], applied to the cached
  /// [analyticsRawRowsProvider] rows.
  static List<Map<String, dynamic>> rowsInPeriod(
    List<Map<String, dynamic>> rows, {
    required DateRange dateRange,
    AnalyticsFilters? filters,
  }) {
    return rows.where((row) {
      final createdAt = (row['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      if (createdAt.isBefore(dateRange.start) || !createdAt.isBefore(dateRange.end)) {
        return false;
      }
      return filters == null || matchesAnalyticsFilters(row, filters);
    }).toList();
  }

  /// Get all available event types for filters from canonical lookup.
  List<String> getEventTypes(DropdownLookup lookup) {
    return lookup.eventTypeMap.keys.toList()..sort();
  }

  /// Get all available statuses for filters from canonical lookup.
  List<String> getStatuses(DropdownLookup lookup) {
    return lookup.statusMap.keys.toList()..sort();
  }

  /// Get all available sources for filters from canonical lookup
  /// (`dropdowns/sources/items`).
  List<String> getSources(DropdownLookup lookup) {
    return lookup.sourceMap.keys.toList()..sort();
  }

  /// Get all available priorities for filters from canonical lookup
  /// (`dropdowns/priorities/items`).
  List<String> getPriorities(DropdownLookup lookup) {
    return lookup.priorityMap.keys.toList()..sort();
  }

  /// Build base query with date range and filters
  Query _buildBaseQuery(DateRange dateRange, AnalyticsFilters? filters) {
    Query query = _firestore.collection('enquiries');

    // Apply date range filter
    query = query
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(dateRange.end));

    // Apply additional filters
    if (filters != null) {
      if (filters.eventType != null && filters.eventType!.isNotEmpty) {
        query = query.where('eventTypeValue', isEqualTo: filters.eventType);
      }
      if (filters.status != null && filters.status!.isNotEmpty) {
        query = query.where('statusValue', whereIn: EnquiryStatus.rawValuesFor(filters.status!));
      }
      if (filters.priority != null && filters.priority!.isNotEmpty) {
        query = query.where('priorityValue', isEqualTo: filters.priority);
      }
      if (filters.source != null && filters.source!.isNotEmpty) {
        query = query.where('sourceValue', isEqualTo: filters.source);
      }
    }

    return query;
  }

  static DateTime _truncateToTimeBucketStatic(DateTime date, TimeBucket bucket) {
    switch (bucket) {
      case TimeBucket.day:
        return DateTime(date.year, date.month, date.day);
      case TimeBucket.week:
        final daysFromMonday = (date.weekday - 1) % 7;
        final monday = date.subtract(Duration(days: daysFromMonday));
        return DateTime(monday.year, monday.month, monday.day);
      case TimeBucket.month:
        return DateTime(date.year, date.month, 1);
    }
  }

  static DateTime _incrementTimeBucketStatic(DateTime date, TimeBucket bucket) {
    switch (bucket) {
      case TimeBucket.day:
        return date.add(const Duration(days: 1));
      case TimeBucket.week:
        return date.add(const Duration(days: 7));
      case TimeBucket.month:
        return DateTime(date.year, date.month + 1, date.day);
    }
  }
}

/// Riverpod provider for analytics repository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(firestore: ref.watch(firestoreServiceProvider).firestore);
});

/// How long [analyticsRawRowsProvider] keeps its rows once nothing watches it.
const Duration analyticsRawRowsTtl = Duration(minutes: 5);

/// Every enquiry row (see [AnalyticsRepository.fetchAllEnquiriesRaw]), cached
/// so filter changes and tab switches reuse one download.
///
/// Kept alive for [analyticsRawRowsTtl] after a successful fetch; the analytics
/// refresh button invalidates it. Errors are not cached.
final analyticsRawRowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final link = ref.keepAlive();
  Timer? expiry;
  ref.onDispose(() => expiry?.cancel());
  try {
    final rows = await repository.fetchAllEnquiriesRaw();
    expiry = Timer(analyticsRawRowsTtl, link.close);
    return rows;
  } catch (_) {
    link.close();
    rethrow;
  }
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
