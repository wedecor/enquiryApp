import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/enquiry_financials.dart';

/// Session cache of every enquiry row behind the admin analytics.
///
/// The pipeline metrics need lifetime data, so the first load per session
/// still reads every enquiry. Later loads read only documents whose
/// `updatedAt` moved past [watermark] (every app, website and status write
/// stamps it), plus one `count()` aggregate to catch deletions; on any doubt
/// they fall back to a full read. Metric definitions are untouched: the
/// merged rows are the same rows a full read returns.
///
/// Money lives in `enquiries/{id}/financial/summary` ([EnquiryFinancials]); the
/// cache keeps parents and summaries apart and merges them into each row, so a
/// change to either refreshes the row.
class AnalyticsRowCache {
  AnalyticsRowCache({
    required this.uid,
    required Map<String, Map<String, dynamic>> rowsById,
    Map<String, Map<String, dynamic>> summariesById = const {},
    required this.watermark,
    required this.fullLoadedAt,
  }) : parentsById = Map.unmodifiable(rowsById),
       summariesById = Map.unmodifiable(summariesById);

  /// Signed-in user the rows were read as; another user always reloads.
  final String? uid;

  /// Enquiry documents as read (each with its `id`).
  final Map<String, Map<String, dynamic>> parentsById;

  /// Financial summaries keyed by enquiry id.
  final Map<String, Map<String, dynamic>> summariesById;

  /// Latest `updatedAt` seen (server time), the lower bound of the next delta.
  final DateTime? watermark;
  final DateTime fullLoadedAt;

  /// Server writes that don't bump `updatedAt` (e.g. occasion stamps) are
  /// picked up by a full reload at least this often.
  static const Duration maxAge = Duration(hours: 6);

  /// Delta queries overlap the watermark to absorb server-timestamp ordering.
  static const Duration overlap = Duration(minutes: 2);

  /// Merged rows (parent + its money), keyed by enquiry id.
  Map<String, Map<String, dynamic>> get rowsById => {
    for (final entry in parentsById.entries)
      entry.key: EnquiryFinancials.merge(entry.value, summariesById[entry.key]),
  };

  List<Map<String, dynamic>> get rows => rowsById.values.toList(growable: false);

  static DateTime? _updatedAt(Map<String, dynamic> row) {
    final raw = row['updatedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  static DateTime? maxUpdatedAt(Iterable<Map<String, dynamic>> rows, [DateTime? start]) {
    var max = start;
    for (final row in rows) {
      final t = _updatedAt(row);
      if (t != null && (max == null || t.isAfter(max))) max = t;
    }
    return max;
  }

  /// Rows keyed by their `id` (as the repository adds it).
  static AnalyticsRowCache fromFullRead(
    List<Map<String, dynamic>> rows, {
    Map<String, Map<String, dynamic>> summaries = const {},
    required String? uid,
    required DateTime now,
  }) {
    return AnalyticsRowCache(
      uid: uid,
      rowsById: {for (final row in rows) row['id'] as String: row},
      summariesById: summaries,
      watermark: maxUpdatedAt(summaries.values, maxUpdatedAt(rows)),
      fullLoadedAt: now,
    );
  }

  /// Lower bound for the next delta query, or null when a full read is needed.
  DateTime? get deltaSince => watermark?.subtract(overlap);

  /// True when the next load must read everything.
  static bool needsFullReload(
    AnalyticsRowCache? cache, {
    required String? uid,
    required DateTime now,
    bool force = false,
  }) {
    if (force || cache == null || cache.uid != uid || cache.watermark == null) return true;
    return now.difference(cache.fullLoadedAt) >= maxAge;
  }

  /// Rows after applying [changed] parents and [changedSummaries] (newer copies
  /// replace older ones by id).
  AnalyticsRowCache applyDelta(
    List<Map<String, dynamic>> changed, [
    Map<String, Map<String, dynamic>> changedSummaries = const {},
  ]) {
    final parents = Map<String, Map<String, dynamic>>.of(parentsById);
    for (final row in changed) {
      parents[row['id'] as String] = row;
    }
    final summaries = {...summariesById, ...changedSummaries};
    return AnalyticsRowCache(
      uid: uid,
      rowsById: parents,
      summariesById: summaries,
      watermark: maxUpdatedAt(changedSummaries.values, maxUpdatedAt(changed, watermark)),
      fullLoadedAt: fullLoadedAt,
    );
  }
}
