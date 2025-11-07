import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/analytics_models.dart';

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

  /// Get count breakdown by status
  Future<Map<String, int>> countByStatus({
    required DateRange dateRange,
    AnalyticsFilters? filters,
  }) async {
    final Query query = _buildBaseQuery(dateRange, filters);
    final snapshot = await query.get();

    final statusCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['eventStatus'] as String?) ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return statusCounts;
  }

  /// Get count breakdown by event type
  Future<Map<String, int>> countByEventType({
    required DateRange dateRange,
    AnalyticsFilters? filters,
  }) async {
    final Query query = _buildBaseQuery(dateRange, filters);
    final snapshot = await query.get();

    final eventTypeCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final eventType = (data['eventType'] as String?) ?? 'unknown';
      eventTypeCounts[eventType] = (eventTypeCounts[eventType] ?? 0) + 1;
    }

    return eventTypeCounts;
  }

  /// Get count breakdown by source
  Future<Map<String, int>> countBySource({
    required DateRange dateRange,
    AnalyticsFilters? filters,
  }) async {
    final Query query = _buildBaseQuery(dateRange, filters);
    final snapshot = await query.get();

    final sourceCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final source = (data['source'] as String?) ?? 'unknown';
      sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
    }

    return sourceCounts;
  }

  /// Get count breakdown by priority
  Future<Map<String, int>> countByPriority({
    required DateRange dateRange,
    AnalyticsFilters? filters,
  }) async {
    final Query query = _buildBaseQuery(dateRange, filters);
    final snapshot = await query.get();

    final priorityCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final priority = (data['priority'] as String?) ?? 'unknown';
      priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
    }

    return priorityCounts;
  }

  /// Generate time series data
  Future<List<SeriesPoint>> getTimeSeries({
    required DateRange dateRange,
    required TimeBucket bucket,
    AnalyticsFilters? filters,
  }) async {
    final Query query = _buildBaseQuery(dateRange, filters);
    final snapshot = await query.get();

    final Map<DateTime, int> dateCounts = {};

    // Initialize all buckets to 0
    DateTime current = _truncateToTimeBucket(dateRange.start, bucket);
    final end = _truncateToTimeBucket(dateRange.end, bucket);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dateCounts[current] = 0;
      current = _incrementTimeBucket(current, bucket);
    }

    // Count actual data points
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      if (createdAt != null) {
        final bucketDate = _truncateToTimeBucket(createdAt, bucket);
        if (dateCounts.containsKey(bucketDate)) {
          dateCounts[bucketDate] = (dateCounts[bucketDate] ?? 0) + 1;
        }
      }
    }

    return dateCounts.entries.map((entry) => SeriesPoint(x: entry.key, count: entry.value)).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  /// Sum total revenue from totalCost field
  Future<double> sumRevenue({required DateRange dateRange, AnalyticsFilters? filters}) async {
    final Query query = _buildBaseQuery(dateRange, filters);
    final snapshot = await query.get();

    double totalRevenue = 0.0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final totalCost = data['totalCost'];

      if (totalCost is num) {
        totalRevenue += totalCost.toDouble();
      }
    }

    return totalRevenue;
  }

  /// Get recent enquiries for table display
  Future<List<RecentEnquiry>> getRecentEnquiries({
    required DateRange dateRange,
    AnalyticsFilters? filters,
    int limit = 20,
  }) async {
    Query query = _buildBaseQuery(dateRange, filters);
    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      return RecentEnquiry(
        id: doc.id,
        date: createdAt,
        customerName: (data['customerName'] as String?) ?? 'Unknown',
        eventType: (data['eventType'] as String?) ?? 'Unknown',
        status: (data['eventStatus'] as String?) ?? 'Unknown',
        source: (data['source'] as String?) ?? 'Unknown',
        priority: (data['priority'] as String?) ?? 'medium',
        totalCost: (data['totalCost'] as num?)?.toDouble(),
      );
    }).toList();
  }

  /// Get all available dropdown values for filters
  Future<List<String>> getEventTypes() async {
    try {
      final snapshot = await _firestore
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .get();

      return snapshot.docs.map((doc) => (doc.data()['value'] as String?) ?? doc.id).toList()
        ..sort();
    } catch (e) {
      // Fallback to unique values from enquiries
      return _getUniqueFieldValues('eventType');
    }
  }

  /// Get all available statuses for filters
  Future<List<String>> getStatuses() async {
    try {
      final snapshot = await _firestore
          .collection('dropdowns')
          .doc('statuses')
          .collection('items')
          .get();

      return snapshot.docs.map((doc) => (doc.data()['value'] as String?) ?? doc.id).toList()
        ..sort();
    } catch (e) {
      // Fallback to unique values from enquiries
      return _getUniqueFieldValues('eventStatus');
    }
  }

  /// Get all available sources for filters
  Future<List<String>> getSources() async {
    return _getUniqueFieldValues('source');
  }

  /// Get all available priorities for filters
  Future<List<String>> getPriorities() async {
    return _getUniqueFieldValues('priority');
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
        query = query.where('eventType', isEqualTo: filters.eventType);
      }
      if (filters.status != null && filters.status!.isNotEmpty) {
        query = query.where('eventStatus', isEqualTo: filters.status);
      }
      if (filters.priority != null && filters.priority!.isNotEmpty) {
        query = query.where('priority', isEqualTo: filters.priority);
      }
      if (filters.source != null && filters.source!.isNotEmpty) {
        query = query.where('source', isEqualTo: filters.source);
      }
    }

    return query;
  }

  /// Get unique values for a field from enquiries collection
  Future<List<String>> _getUniqueFieldValues(String fieldName) async {
    final snapshot = await _firestore.collection('enquiries').get();
    final values = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final value = data[fieldName] as String?;
      if (value != null && value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.toList()..sort();
  }

  /// Truncate date to time bucket boundary
  DateTime _truncateToTimeBucket(DateTime date, TimeBucket bucket) {
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

  /// Increment date by one time bucket
  DateTime _incrementTimeBucket(DateTime date, TimeBucket bucket) {
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
  return AnalyticsRepository();
});
