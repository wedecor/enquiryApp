import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../enquiries/domain/booking_amounts.dart';
import '../../../enquiries/domain/enquiry_lifecycle.dart';
import '../../../enquiries/domain/event_functions.dart';

/// Pure analytics over raw enquiry maps (as read from Firestore, plus `id`).
///
/// Everything here is deterministic given `rows` and `now`, so it is unit
/// tested directly. Statuses always go through [EnquiryStatus] so legacy values
/// (quote_sent, confirmed…) count as their canonical stage.
///
/// Conventions:
/// * Win rate = won ÷ (won + lost), same as the existing conversion KPI.
/// * "Won" = approved or completed. "Lost" = not interested / closed lost / cancelled.
/// * Booked value = `totalCost` of won enquiries.
/// * Duplicates (merged enquiries, lost reason `duplicate`) are not leads and are
///   dropped up front ([leadRows]).
/// * Owner's rule for multi-function bookings: EVENTS are counted per FUNCTION
///   (a Haldi + Mehendi + Wedding + Reception booking is 4 events, each with its own
///   type, date and area); REVENUE is counted per BOOKING, once (never multiplied).
///   Leads / funnel / win rate / speed to lead stay per booking.

// ── Field helpers ────────────────────────────────────────────────────────────

DateTime? metricDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return null;
}

double? metricNum(dynamic raw) => raw is num ? raw.toDouble() : null;

EnquiryStatus? metricStatus(Map<String, dynamic> row) =>
    EnquiryStatus.fromValue(row['statusValue'] as String?);

bool isWon(Map<String, dynamic> row) => metricStatus(row)?.category == StatusCategory.won;

bool isLostRow(Map<String, dynamic> row) => metricStatus(row)?.category == StatusCategory.lost;

/// Closed by "Mark as duplicate of…" (lost reason `duplicate` or `mergedInto` set).
/// A duplicate is not a lead: it is left out of every count and rate.
bool isDuplicateRow(Map<String, dynamic> row) =>
    (row['lostReason'] as String?)?.trim() == LostReason.duplicate.value ||
    row['mergedInto'] != null;

/// [rows] without duplicates (see [isDuplicateRow]).
List<Map<String, dynamic>> leadRows(List<Map<String, dynamic>> rows) =>
    rows.where((row) => !isDuplicateRow(row)).toList();

/// Open = a known active canonical status (new / in talks). Unknown or
/// missing statuses are not counted as open leads.
bool isOpen(Map<String, dynamic> row) => metricStatus(row)?.category == StatusCategory.active;

/// True when the payment status (`paymentStatusValue`, legacy `paymentStatus`)
/// is `paid`: the enquiry is fully collected whatever `advancePaid` says.
bool isFullyPaid(Map<String, dynamic> row) {
  final raw = row['paymentStatusValue'] ?? row['paymentStatus'];
  return raw is String && raw.trim().toLowerCase() == 'paid';
}

String _canonicalField(Map<String, dynamic> row, String primary, String legacy) {
  final v = row[primary] ?? row[legacy];
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? 'unknown' : s;
}

String sourceOf(Map<String, dynamic> row) => _canonicalField(row, 'sourceValue', 'source');

String eventTypeOf(Map<String, dynamic> row) => _canonicalField(row, 'eventTypeValue', 'eventType');

// ── Functions (events) ───────────────────────────────────────────────────────

/// One event (function) of a booking, for per-function counts.
class FunctionMetric {
  const FunctionMetric({required this.row, required this.eventType, this.date, this.area});

  /// The booking (enquiry row) it belongs to.
  final Map<String, dynamic> row;

  /// Event type value of this function (legacy: the booking's [eventTypeOf]).
  final String eventType;

  /// The function's day (legacy: `eventDate`); null when unknown.
  final DateTime? date;

  /// The function's `locationArea` (legacy: the booking's); null when unknown.
  final String? area;
}

/// The booking's events: one per stored function, or ONE for a legacy
/// single-event enquiry (its event type, `eventDate` and `locationArea`, even
/// when the date is missing).
List<FunctionMetric> metricFunctionsOf(Map<String, dynamic> row) {
  final functions = functionsOf(row);
  final raw = row['functions'];
  final stored = functions.isNotEmpty && raw is List && raw.any((e) => e is Map);
  if (!stored) {
    final area = row['locationArea'];
    return [
      FunctionMetric(
        row: row,
        eventType: eventTypeOf(row),
        date: metricDate(row['eventDate']),
        area: area is String ? area : null,
      ),
    ];
  }
  return [
    for (final f in functions)
      FunctionMetric(row: row, eventType: f.eventType, date: f.day, area: f.locationArea),
  ];
}

/// Events of [rows] in the period: with [AnalyticsAttribution.eventDate], every
/// function whose own date is in [start, end); with [AnalyticsAttribution.enquiryDate],
/// every function of the bookings created in the period.
List<FunctionMetric> functionsInPeriod(
  List<Map<String, dynamic>> rows, {
  required DateTime start,
  required DateTime end,
  required AnalyticsAttribution attribution,
}) {
  bool inPeriod(DateTime? d) => d != null && !d.isBefore(start) && d.isBefore(end);
  final result = <FunctionMetric>[];
  for (final row in rows) {
    if (attribution == AnalyticsAttribution.enquiryDate) {
      if (inPeriod(metricDate(row['createdAt']))) result.addAll(metricFunctionsOf(row));
    } else {
      result.addAll(metricFunctionsOf(row).where((f) => inPeriod(f.date)));
    }
  }
  return result;
}

/// Event type value → number of events (functions), largest first.
List<LabeledCount> computeEventTypeEvents(Iterable<FunctionMetric> functions) {
  final counts = <String, int>{};
  for (final f in functions) {
    counts[f.eventType] = (counts[f.eventType] ?? 0) + 1;
  }
  final list = [for (final e in counts.entries) LabeledCount(e.key, e.key, e.value)]
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return list;
}

/// Real (non-estimated) response time, or null if not contacted / estimated.
Duration? responseTime(Map<String, dynamic> row) {
  if (row['firstContactEstimated'] == true) return null;
  final created = metricDate(row['createdAt']);
  final first = metricDate(row['firstContactAt']);
  if (created == null || first == null) return null;
  final d = first.difference(created);
  return d.isNegative ? Duration.zero : d;
}

Duration? percentileDuration(List<Duration> values, double p) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * p).round().clamp(0, sorted.length - 1);
  return sorted[index];
}

double _winRate(int won, int lost) => (won + lost) == 0 ? 0 : won / (won + lost);

// ── Attribution & filtering ──────────────────────────────────────────────────

/// Which date places an enquiry inside the selected period.
enum AnalyticsAttribution {
  enquiryDate('Enquiry date', 'createdAt'),
  eventDate('Event date', 'eventDate');

  const AnalyticsAttribution(this.label, this.field);

  final String label;
  final String field;
}

/// Rows whose [attribution] date is in [start, end).
List<Map<String, dynamic>> rowsInPeriod(
  List<Map<String, dynamic>> rows, {
  required DateTime start,
  required DateTime end,
  required AnalyticsAttribution attribution,
}) {
  return rows.where((row) {
    final d = metricDate(row[attribution.field]);
    return d != null && !d.isBefore(start) && d.isBefore(end);
  }).toList();
}

// ── 1. Funnel ────────────────────────────────────────────────────────────────

class FunnelReport {
  const FunnelReport({
    required this.total,
    required this.reachedInTalks,
    required this.reachedApproved,
    required this.reachedCompleted,
    required this.lostBeforeInTalks,
    required this.lostAfterInTalks,
    required this.lostAfterApproved,
    required this.open,
  });

  final int total;
  final int reachedInTalks;
  final int reachedApproved;
  final int reachedCompleted;
  final int lostBeforeInTalks;
  final int lostAfterInTalks;
  final int lostAfterApproved;
  final int open;

  int get lost => lostBeforeInTalks + lostAfterInTalks + lostAfterApproved;

  static const empty = FunnelReport(
    total: 0,
    reachedInTalks: 0,
    reachedApproved: 0,
    reachedCompleted: 0,
    lostBeforeInTalks: 0,
    lostAfterInTalks: 0,
    lostAfterApproved: 0,
    open: 0,
  );
}

/// Furthest stage reached: 0 new, 1 in talks, 2 approved, 3 completed.
/// Lost enquiries use their stage timestamps (if any) to know how far they got.
int furthestStage(Map<String, dynamic> row) {
  final s = metricStatus(row);
  var rank = switch (s) {
    EnquiryStatus.inTalks => 1,
    EnquiryStatus.approved => 2,
    EnquiryStatus.completed => 3,
    _ => 0,
  };
  if (row[EnquiryStageFields.inTalksAt] != null && rank < 1) rank = 1;
  if (row[EnquiryStageFields.approvedAt] != null && rank < 2) rank = 2;
  if (row[EnquiryStageFields.completedAt] != null && rank < 3) rank = 3;
  return rank;
}

FunnelReport computeFunnel(List<Map<String, dynamic>> allRows) {
  final rows = leadRows(allRows);
  var inTalks = 0, approved = 0, completed = 0;
  var lostBefore = 0, lostAfterTalks = 0, lostAfterApproved = 0, open = 0;
  for (final row in rows) {
    final stage = furthestStage(row);
    if (stage >= 1) inTalks++;
    if (stage >= 2) approved++;
    if (stage >= 3) completed++;
    if (isLostRow(row)) {
      if (stage >= 2) {
        lostAfterApproved++;
      } else if (stage == 1) {
        lostAfterTalks++;
      } else {
        lostBefore++;
      }
    } else if (isOpen(row)) {
      open++;
    }
  }
  return FunnelReport(
    total: rows.length,
    reachedInTalks: inTalks,
    reachedApproved: approved,
    reachedCompleted: completed,
    lostBeforeInTalks: lostBefore,
    lostAfterInTalks: lostAfterTalks,
    lostAfterApproved: lostAfterApproved,
    open: open,
  );
}

// ── 2. Lost reasons ──────────────────────────────────────────────────────────

class LabeledCount {
  const LabeledCount(this.key, this.label, this.count);

  final String key;
  final String label;
  final int count;
}

/// Lost enquiries grouped by `lostReason` ("not_recorded" when missing), largest first.
List<LabeledCount> computeLostReasons(List<Map<String, dynamic>> rows) {
  final counts = <String, int>{};
  for (final row in leadRows(rows).where(isLostRow)) {
    final raw = (row['lostReason'] as String?)?.trim();
    final key = (raw == null || raw.isEmpty) ? 'not_recorded' : raw;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final list =
      counts.entries
          .map(
            (e) => LabeledCount(
              e.key,
              e.key == 'not_recorded' ? 'Not recorded' : LostReason.labelOf(e.key),
              e.value,
            ),
          )
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
  return list;
}

// ── 3. Speed to lead ─────────────────────────────────────────────────────────

class ResponseBucketRow {
  const ResponseBucketRow({
    required this.label,
    required this.leads,
    required this.won,
    required this.lost,
  });

  final String label;
  final int leads;
  final int won;
  final int lost;

  double get winRate => _winRate(won, lost);
}

class SpeedToLeadReport {
  const SpeedToLeadReport({
    required this.sampleSize,
    required this.estimatedExcluded,
    required this.neverContacted,
    required this.median,
    required this.p75,
    required this.within1h,
    required this.within24h,
    required this.within72h,
    required this.buckets,
  });

  /// Enquiries with a real (non-estimated) first-contact time.
  final int sampleSize;

  /// Enquiries whose first contact is a backfilled estimate (excluded).
  final int estimatedExcluded;

  /// Still New and never contacted.
  final int neverContacted;
  final Duration? median;
  final Duration? p75;

  /// Shares of (sample + never contacted), 0–1.
  final double within1h;
  final double within24h;
  final double within72h;
  final List<ResponseBucketRow> buckets;

  bool get hasData => sampleSize > 0;
}

SpeedToLeadReport computeSpeedToLead(List<Map<String, dynamic>> rows) {
  final times = <Duration>[];
  var estimated = 0, never = 0;
  const labels = ['< 1 hour', '1–24 hours', '1–3 days', '> 3 days', 'No logged contact'];
  final leads = List<int>.filled(5, 0);
  final won = List<int>.filled(5, 0);
  final lost = List<int>.filled(5, 0);

  for (final row in leadRows(rows)) {
    int? bucket;
    if (row['firstContactEstimated'] == true) {
      estimated++;
      continue;
    }
    final rt = responseTime(row);
    if (rt != null) {
      times.add(rt);
      if (rt < const Duration(hours: 1)) {
        bucket = 0;
      } else if (rt < const Duration(hours: 24)) {
        bucket = 1;
      } else if (rt < const Duration(days: 3)) {
        bucket = 2;
      } else {
        bucket = 3;
      }
    } else if (row['firstContactAt'] == null) {
      bucket = 4;
      if (metricStatus(row) == EnquiryStatus.newEnquiry || row['statusValue'] == null) {
        never++;
      }
    }
    if (bucket == null) continue;
    leads[bucket]++;
    if (isWon(row)) won[bucket]++;
    if (isLostRow(row)) lost[bucket]++;
  }

  final denominator = times.length + never;
  double share(Duration limit) =>
      denominator == 0 ? 0 : times.where((t) => t <= limit).length / denominator;

  return SpeedToLeadReport(
    sampleSize: times.length,
    estimatedExcluded: estimated,
    neverContacted: never,
    median: percentileDuration(times, 0.5),
    p75: percentileDuration(times, 0.75),
    within1h: share(const Duration(hours: 1)),
    within24h: share(const Duration(hours: 24)),
    within72h: share(const Duration(hours: 72)),
    buckets: [
      for (var i = 0; i < labels.length; i++)
        ResponseBucketRow(label: labels[i], leads: leads[i], won: won[i], lost: lost[i]),
    ],
  );
}

// ── 4 & 5. Source and team performance ───────────────────────────────────────

class PerformanceRow {
  const PerformanceRow({
    required this.key,
    required this.leads,
    required this.contacted,
    required this.won,
    required this.lost,
    required this.open,
    required this.stale,
    required this.bookedValue,
    required this.medianResponse,
  });

  /// Source value, or assignee uid ('' = unassigned).
  final String key;
  final int leads;
  final int contacted;
  final int won;
  final int lost;
  final int open;
  final int stale;
  final double bookedValue;
  final Duration? medianResponse;

  double get winRate => _winRate(won, lost);
  double get contactedShare => leads == 0 ? 0 : contacted / leads;
  double get averageBooked => won == 0 ? 0 : bookedValue / won;
}

/// Open and not updated (nor contacted) for [staleAfter].
bool isStale(
  Map<String, dynamic> row,
  DateTime now, {
  Duration staleAfter = const Duration(days: 7),
}) {
  if (!isOpen(row)) return false;
  final candidates = [
    metricDate(row['updatedAt']),
    metricDate(row['lastContactAt']),
    metricDate(row['createdAt']),
  ].whereType<DateTime>();
  if (candidates.isEmpty) return false;
  final last = candidates.reduce((a, b) => a.isAfter(b) ? a : b);
  return now.difference(last) >= staleAfter;
}

List<PerformanceRow> _groupPerformance(
  List<Map<String, dynamic>> rows,
  String Function(Map<String, dynamic>) keyOf,
  DateTime now,
) {
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final row in leadRows(rows)) {
    groups.putIfAbsent(keyOf(row), () => []).add(row);
  }
  final result = groups.entries.map((e) {
    final g = e.value;
    final times = g.map(responseTime).whereType<Duration>().toList();
    return PerformanceRow(
      key: e.key,
      leads: g.length,
      contacted: g.where((r) => r['firstContactAt'] != null).length,
      won: g.where(isWon).length,
      lost: g.where(isLostRow).length,
      open: g.where(isOpen).length,
      stale: g.where((r) => isStale(r, now)).length,
      bookedValue: g
          .where(isWon)
          .fold<double>(0, (total, r) => total + (metricNum(r['totalCost']) ?? 0)),
      medianResponse: percentileDuration(times, 0.5),
    );
  }).toList()..sort((a, b) => b.leads.compareTo(a.leads));
  return result;
}

List<PerformanceRow> computeSourcePerformance(List<Map<String, dynamic>> rows, DateTime now) =>
    _groupPerformance(rows, sourceOf, now);

List<PerformanceRow> computeTeamPerformance(List<Map<String, dynamic>> rows, DateTime now) =>
    _groupPerformance(rows, (r) => (r['assignedTo'] as String?)?.trim() ?? '', now);

// ── 6. Money ─────────────────────────────────────────────────────────────────

class MoneyMonth {
  const MoneyMonth({
    required this.month,
    required this.bookings,
    required this.booked,
    required this.collected,
  });

  /// First day of the month.
  final DateTime month;
  final int bookings;
  final double booked;
  final double collected;

  double get outstanding => (booked - collected).clamp(0, double.infinity).toDouble();
}

class OverdueItem {
  const OverdueItem({
    required this.id,
    required this.customerName,
    required this.eventDate,
    required this.outstanding,
  });

  final String id;
  final String customerName;
  final DateTime eventDate;
  final double outstanding;
}

/// Balance still due: `totalCost - advancePaid`, or 0 once marked paid.
double outstandingOf(Map<String, dynamic> row) {
  if (isFullyPaid(row)) return 0;
  final total = metricNum(row['totalCost']) ?? 0;
  final advance = metricNum(row['advancePaid']) ?? 0;
  final o = total - advance;
  return o > 0 ? o : 0;
}

/// Amount received: `advancePaid`, or the full `totalCost` once marked paid.
double collectedOf(Map<String, dynamic> row) {
  final advance = metricNum(row['advancePaid']) ?? 0;
  if (!isFullyPaid(row)) return advance;
  final total = metricNum(row['totalCost']) ?? 0;
  return total > advance ? total : advance;
}

/// Month bucket (0 = the current month) of a row's event date, or null when it
/// has no event date or falls outside the [months]-month window.
int? _moneyMonthIndex(Map<String, dynamic> row, DateTime now, int months) {
  final event = metricDate(row['eventDate']);
  if (event == null) return null;
  final index = (event.year - now.year) * 12 + (event.month - now.month);
  return index < 0 || index >= months ? null : index;
}

/// Won enquiries by event month, from the current month for [months] months.
List<MoneyMonth> computeMoneyByMonth(
  List<Map<String, dynamic>> rows,
  DateTime now, {
  int months = 6,
}) {
  final start = DateTime(now.year, now.month);
  final buckets = [for (var i = 0; i < months; i++) DateTime(start.year, start.month + i)];
  final booked = List<double>.filled(months, 0);
  final collected = List<double>.filled(months, 0);
  final count = List<int>.filled(months, 0);

  for (final row in rows.where(isWon)) {
    final index = _moneyMonthIndex(row, now, months);
    if (index == null) continue;
    booked[index] += metricNum(row['totalCost']) ?? 0;
    collected[index] += collectedOf(row);
    count[index]++;
  }
  return [
    for (var i = 0; i < months; i++)
      MoneyMonth(month: buckets[i], bookings: count[i], booked: booked[i], collected: collected[i]),
  ];
}

/// Won rows counted by [computeMoneyByMonth] (event month in the window).
List<Map<String, dynamic>> moneyWindowRows(
  List<Map<String, dynamic>> rows,
  DateTime now, {
  int months = 6,
}) => [
  for (final row in rows.where(isWon))
    if (_moneyMonthIndex(row, now, months) != null) row,
];

// ── Amount coverage ──────────────────────────────────────────────────────────

/// How many won bookings (approved + completed) carry an amount.
///
/// Approving never requires an amount, so booked-value totals can be partial.
class AmountCoverage {
  const AmountCoverage({required this.withAmount, required this.total});

  static const AmountCoverage none = AmountCoverage(withAmount: 0, total: 0);

  final int withAmount;
  final int total;

  /// Some bookings lack an amount, so money totals are understated.
  bool get isPartial => total > 0 && withAmount < total;
}

/// Coverage over the won rows of [rows] ([bookingHasAmount]: `totalCost` > 0).
AmountCoverage computeAmountCoverage(Iterable<Map<String, dynamic>> rows) {
  var total = 0;
  var withAmount = 0;
  for (final row in rows.where(isWon)) {
    total++;
    if (bookingHasAmount(row)) withAmount++;
  }
  return AmountCoverage(withAmount: withAmount, total: total);
}

/// "Based on 7 of 9 bookings with an amount" when some lack one; null otherwise.
String? amountCoverageCaption(AmountCoverage coverage) => coverage.isPartial
    ? 'Based on ${coverage.withAmount} of ${coverage.total} bookings with an amount'
    : null;

/// Won enquiries whose event day is before today and still have a balance due,
/// largest balance first.
List<OverdueItem> computeOverdue(List<Map<String, dynamic>> rows, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final items = <OverdueItem>[];
  for (final row in rows.where(isWon)) {
    final event = metricDate(row['eventDate']);
    if (event == null) continue;
    final eventDay = DateTime(event.year, event.month, event.day);
    if (!eventDay.isBefore(today)) continue;
    final due = outstandingOf(row);
    if (due <= 0) continue;
    items.add(
      OverdueItem(
        id: row['id'] as String? ?? '',
        customerName: (row['customerName'] as String?) ?? 'Customer',
        eventDate: event,
        outstanding: due,
      ),
    );
  }
  items.sort((a, b) => b.outstanding.compareTo(a.outstanding));
  return items;
}

// ── 7. Weighted pipeline forecast ────────────────────────────────────────────

class PipelineForecast {
  const PipelineForecast({
    required this.openCount,
    required this.quotedCount,
    required this.totalValue,
    required this.winProbability,
    required this.decidedSample,
  });

  final int openCount;
  final int quotedCount;

  /// Sum of each open In Talks enquiry's expected deal value (before weighting).
  final double totalValue;

  /// Trailing-12-month win rate of enquiries that reached In Talks (0–1).
  final double winProbability;

  /// Won + lost enquiries the probability is based on.
  final int decidedSample;

  double get expectedValue => totalValue * winProbability;
}

PipelineForecast computeForecast(List<Map<String, dynamic>> allRows, DateTime now) {
  final yearAgo = now.subtract(const Duration(days: 365));
  final recent = allRows.where((r) {
    final created = metricDate(r['createdAt']);
    return created != null && created.isAfter(yearAgo);
  }).toList();

  // Average booked value by event type (and overall) over the last 12 months.
  final byType = <String, List<double>>{};
  final all = <double>[];
  for (final row in recent.where(isWon)) {
    final v = metricNum(row['totalCost']);
    if (v == null || v <= 0) continue;
    byType.putIfAbsent(eventTypeOf(row), () => []).add(v);
    all.add(v);
  }
  double avg(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
  final overallAvg = avg(all);

  // Probability: of recent enquiries that reached In Talks and were decided.
  final talked = recent.where((r) => furthestStage(r) >= 1 || isLostRow(r));
  final decidedWon = talked.where(isWon).length;
  final decidedLost = talked.where((r) => isLostRow(r) && furthestStage(r) >= 1).length;

  var total = 0.0;
  var quoted = 0;
  final open = allRows.where((r) => metricStatus(r) == EnquiryStatus.inTalks).toList();
  for (final row in open) {
    final q = metricNum(row['quotedAmount']);
    if (q != null && q > 0) {
      total += q;
      quoted++;
      continue;
    }
    final typeAvg = avg(byType[eventTypeOf(row)] ?? const []);
    total += typeAvg > 0 ? typeAvg : overallAvg;
  }

  return PipelineForecast(
    openCount: open.length,
    quotedCount: quoted,
    totalValue: total,
    winProbability: _winRate(decidedWon, decidedLost),
    decidedSample: decidedWon + decidedLost,
  );
}

// ── 8. Demand ────────────────────────────────────────────────────────────────

/// How far ahead of the event people enquire — per function (each function's own
/// date). [functions] defaults to every function of [rows].
List<LabeledCount> computeLeadTime(
  List<Map<String, dynamic>> rows, {
  List<FunctionMetric>? functions,
}) {
  const labels = [
    ('lt2w', '< 2 weeks'),
    ('2to4w', '2–4 weeks'),
    ('1to3m', '1–3 months'),
    ('3to6m', '3–6 months'),
    ('gt6m', '> 6 months'),
  ];
  final counts = List<int>.filled(labels.length, 0);
  for (final f in functions ?? [for (final row in rows) ...metricFunctionsOf(row)]) {
    final created = metricDate(f.row['createdAt']);
    final event = f.date;
    if (created == null || event == null || event.year <= 1971) continue;
    final days = event.difference(created).inDays;
    if (days < 0) continue;
    final i = days < 14
        ? 0
        : days < 28
        ? 1
        : days < 90
        ? 2
        : days < 180
        ? 3
        : 4;
    counts[i]++;
  }
  return [
    for (var i = 0; i < labels.length; i++) LabeledCount(labels[i].$1, labels[i].$2, counts[i]),
  ];
}

class MonthDemand {
  const MonthDemand({required this.month, required this.byEventType});

  final DateTime month;

  /// Event type value → number of non-lost events (functions) that month.
  final Map<String, int> byEventType;

  int get total => byEventType.values.fold(0, (a, b) => a + b);
}

/// Upcoming events (functions of non-lost bookings, each by its own date and type)
/// per month for the next [months] months.
List<MonthDemand> computeUpcomingDemand(
  List<Map<String, dynamic>> rows,
  DateTime now, {
  int months = 12,
}) {
  final start = DateTime(now.year, now.month);
  final maps = List.generate(months, (_) => <String, int>{});
  for (final row in rows) {
    if (isLostRow(row)) continue;
    for (final f in metricFunctionsOf(row)) {
      final event = f.date;
      if (event == null) continue;
      final index = (event.year - start.year) * 12 + (event.month - start.month);
      if (index < 0 || index >= months) continue;
      maps[index][f.eventType] = (maps[index][f.eventType] ?? 0) + 1;
    }
  }
  return [
    for (var i = 0; i < months; i++)
      MonthDemand(month: DateTime(start.year, start.month + i), byEventType: maps[i]),
  ];
}

// ── 9. Follow-up discipline ──────────────────────────────────────────────────

class StaleItem {
  const StaleItem({
    required this.id,
    required this.customerName,
    required this.assignedTo,
    required this.daysSinceContact,
  });

  final String id;
  final String customerName;
  final String? assignedTo;

  /// Days since last contact (or since creation when never contacted).
  final int daysSinceContact;
}

class FollowUpReport {
  const FollowUpReport({
    required this.notContacted7d,
    required this.avgContactsBeforeWin,
    required this.avgContactsBeforeLoss,
    required this.remindersSent,
  });

  final List<StaleItem> notContacted7d;
  final double? avgContactsBeforeWin;
  final double? avgContactsBeforeLoss;
  final int remindersSent;
}

/// [openRows]: all currently open enquiries (any period). [periodRows]: the
/// selected period, for averages and reminder counts.
FollowUpReport computeFollowUp({
  required List<Map<String, dynamic>> openRows,
  required List<Map<String, dynamic>> periodRows,
  required DateTime now,
}) {
  final stale = <StaleItem>[];
  for (final row in openRows.where(isOpen)) {
    final last = metricDate(row['lastContactAt']) ?? metricDate(row['createdAt']);
    if (last == null) continue;
    final days = now.difference(last).inDays;
    if (days < 7) continue;
    stale.add(
      StaleItem(
        id: row['id'] as String? ?? '',
        customerName: (row['customerName'] as String?) ?? 'Customer',
        assignedTo: row['assignedTo'] as String?,
        daysSinceContact: days,
      ),
    );
  }
  stale.sort((a, b) => b.daysSinceContact.compareTo(a.daysSinceContact));

  double? avgContacts(Iterable<Map<String, dynamic>> rows) {
    final values = rows.map((r) => metricNum(r['contactCount'])).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  return FollowUpReport(
    notContacted7d: stale,
    avgContactsBeforeWin: avgContacts(periodRows.where(isWon)),
    avgContactsBeforeLoss: avgContacts(periodRows.where(isLostRow)),
    remindersSent: periodRows.fold<int>(
      0,
      (total, r) => total + (metricNum(r['reminderClickCount'])?.toInt() ?? 0),
    ),
  );
}

// ── 10. Bookings by area ─────────────────────────────────────────────────────

class AreaRow {
  const AreaRow({
    required this.key,
    required this.label,
    required this.bookings,
    required this.bookedValue,
    int? events,
  }) : events = events ?? bookings;

  /// Key used for an enquiry without `locationArea`.
  static const String notSpecifiedKey = '';

  /// Lower-cased, whitespace-collapsed area ('' = not specified).
  final String key;
  final String label;

  /// Bookings whose (main) area this is — booked value is counted here, once.
  final int bookings;
  final double bookedValue;

  /// Events (functions) held in this area, each function by its own area.
  final int events;

  bool get isNotSpecified => key == notSpecifiedKey;
}

/// Lower-cased, whitespace-collapsed `locationArea` ('' when missing).
String areaKeyOf(Map<String, dynamic> row) => _areaKey(row['locationArea']);

String _areaKey(Object? raw) {
  if (raw is! String) return AreaRow.notSpecifiedKey;
  return raw.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

/// Title case for display; short all-caps words (HSR, BTM, JP) are kept.
String areaDisplayLabel(String raw) {
  return raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) {
        if (w.length <= 4 && w == w.toUpperCase() && w != w.toLowerCase()) return w;
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      })
      .join(' ');
}

/// Approved + completed bookings grouped by area (case-insensitive), with a
/// "Not specified" row last for those without one.
///
/// Events = won functions by each function's own area ([functions], default:
/// every function of the won [rows]). Bookings and booked value = won bookings by
/// their top-level `locationArea` (the main function's), each counted once.
/// Most events first, then bookings, booked value, label.
List<AreaRow> computeAreaBreakdown(
  List<Map<String, dynamic>> rows, {
  List<FunctionMetric>? functions,
}) {
  final won = leadRows(rows).where(isWon).toList();
  final labels = <String, String>{};
  final counts = <String, int>{};
  final events = <String, int>{};
  final values = <String, double>{};
  void label(String key, Object? raw) {
    if (key != AreaRow.notSpecifiedKey) {
      labels.putIfAbsent(key, () => areaDisplayLabel(raw as String));
    }
  }

  for (final row in won) {
    final key = areaKeyOf(row);
    label(key, row['locationArea']);
    counts[key] = (counts[key] ?? 0) + 1;
    values[key] = (values[key] ?? 0) + (metricNum(row['totalCost']) ?? 0);
  }
  final wonFunctions =
      functions?.where((f) => isWon(f.row) && !isDuplicateRow(f.row)) ??
      [for (final row in won) ...metricFunctionsOf(row)];
  for (final f in wonFunctions) {
    final key = _areaKey(f.area);
    label(key, f.area);
    events[key] = (events[key] ?? 0) + 1;
  }
  final list = [
    for (final key in {...counts.keys, ...events.keys})
      AreaRow(
        key: key,
        label: key == AreaRow.notSpecifiedKey ? 'Not specified' : labels[key]!,
        bookings: counts[key] ?? 0,
        bookedValue: values[key] ?? 0,
        events: events[key] ?? 0,
      ),
  ];
  list.sort((a, b) {
    if (a.isNotSpecified != b.isNotSpecified) return a.isNotSpecified ? 1 : -1;
    final byEvents = b.events.compareTo(a.events);
    if (byEvents != 0) return byEvents;
    final byCount = b.bookings.compareTo(a.bookings);
    if (byCount != 0) return byCount;
    final byValue = b.bookedValue.compareTo(a.bookedValue);
    if (byValue != 0) return byValue;
    return a.label.compareTo(b.label);
  });
  return list;
}

// ── Full report ──────────────────────────────────────────────────────────────

class PipelineReport {
  const PipelineReport({
    required this.attribution,
    required this.periodCount,
    required this.funnel,
    required this.lostReasons,
    required this.speed,
    required this.sources,
    required this.team,
    required this.money,
    required this.overdue,
    required this.forecast,
    required this.leadTime,
    required this.upcomingDemand,
    required this.followUp,
    required this.bookedValueInPeriod,
    this.areas = const [],
    this.eventsInPeriod = 0,
    this.bookingsInPeriod = 0,
    this.eventTypeEvents = const [],
    this.bookedCoverage = AmountCoverage.none,
    this.moneyCoverage = AmountCoverage.none,
  });

  final AnalyticsAttribution attribution;
  final int periodCount;
  final FunnelReport funnel;
  final List<LabeledCount> lostReasons;
  final SpeedToLeadReport speed;
  final List<PerformanceRow> sources;
  final List<PerformanceRow> team;
  final List<MoneyMonth> money;
  final List<OverdueItem> overdue;
  final PipelineForecast forecast;
  final List<LabeledCount> leadTime;
  final List<MonthDemand> upcomingDemand;
  final FollowUpReport followUp;

  /// Booked value of won enquiries in the period (by the chosen attribution).
  final double bookedValueInPeriod;

  /// Approved + completed enquiries in the period by area ([computeAreaBreakdown]).
  final List<AreaRow> areas;

  /// "Events" KPI: functions of approved + completed bookings in the period
  /// (by function date, or by enquiry date — see [functionsInPeriod]).
  final int eventsInPeriod;

  /// Approved + completed bookings in the period (each booking once).
  final int bookingsInPeriod;

  /// Events (functions) of approved + completed bookings in the period by event type.
  final List<LabeledCount> eventTypeEvents;

  /// Won bookings in the period with an amount — behind [bookedValueInPeriod],
  /// the area / source / team booked values.
  final AmountCoverage bookedCoverage;

  /// Won bookings in the [money] window with an amount.
  final AmountCoverage moneyCoverage;
}

/// Builds every Phase-1 metric. [allRows] = every enquiry visible to the admin
/// (already filtered by event type / source / etc. if those filters are set);
/// the period is applied here with [attribution].
PipelineReport buildPipelineReport({
  required List<Map<String, dynamic>> allRows,
  required DateTime start,
  required DateTime end,
  required AnalyticsAttribution attribution,
  required DateTime now,
}) {
  allRows = leadRows(allRows);
  final period = rowsInPeriod(allRows, start: start, end: end, attribution: attribution);
  final periodFunctions = functionsInPeriod(
    allRows,
    start: start,
    end: end,
    attribution: attribution,
  );
  final wonFunctions = periodFunctions.where((f) => isWon(f.row)).toList();
  return PipelineReport(
    attribution: attribution,
    periodCount: period.length,
    funnel: computeFunnel(period),
    lostReasons: computeLostReasons(period),
    speed: computeSpeedToLead(period),
    sources: computeSourcePerformance(period, now),
    team: computeTeamPerformance(period, now),
    money: computeMoneyByMonth(allRows, now),
    overdue: computeOverdue(allRows, now),
    forecast: computeForecast(allRows, now),
    leadTime: computeLeadTime(period, functions: periodFunctions),
    upcomingDemand: computeUpcomingDemand(allRows, now),
    followUp: computeFollowUp(openRows: allRows, periodRows: period, now: now),
    bookedValueInPeriod: period
        .where(isWon)
        .fold<double>(0, (total, r) => total + (metricNum(r['totalCost']) ?? 0)),
    areas: computeAreaBreakdown(period, functions: wonFunctions),
    eventsInPeriod: wonFunctions.length,
    bookingsInPeriod: period.where(isWon).length,
    eventTypeEvents: computeEventTypeEvents(wonFunctions),
    bookedCoverage: computeAmountCoverage(period),
    moneyCoverage: computeAmountCoverage(moneyWindowRows(allRows, now)),
  );
}
