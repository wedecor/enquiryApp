import '../../../../core/constants/firestore_schema.dart';
import '../../../reengagement/domain/occasion_reminder.dart';
import 'pipeline_metrics.dart';

/// Minimum decided enquiries (won+lost) before a win rate is shown.
const int kMinDecidedForRate = 5;

/// Minimum measured response times before a median is shown.
const int kMinSampleForMedian = 5;

const List<String> kWeekdayLabels = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

enum TimeOfDayBucket {
  morning('Morning', '06:00–11:59'),
  afternoon('Afternoon', '12:00–16:59'),
  evening('Evening', '17:00–20:59'),
  night('Night', '21:00–05:59');

  const TimeOfDayBucket(this.label, this.rangeLabel);
  final String label;
  final String rangeLabel;
}

/// IST calendar weekday index 0=Mon … 6=Sun for [instant].
int istWeekdayIndex(DateTime instant) {
  final ist = IstDate.calendar(instant);
  return (ist.weekday - 1) % 7;
}

/// IST wall-clock hour 0–23 for [instant].
int istHour(DateTime instant) => IstDate.calendar(instant).hour;

TimeOfDayBucket timeOfDayBucket(DateTime instant) {
  final h = istHour(instant);
  if (h >= 6 && h < 12) return TimeOfDayBucket.morning;
  if (h >= 12 && h < 17) return TimeOfDayBucket.afternoon;
  if (h >= 17 && h < 21) return TimeOfDayBucket.evening;
  return TimeOfDayBucket.night;
}

/// Win rate, or null when decided sample is below [kMinDecidedForRate].
double? sampleWinRate(int won, int lost) {
  final decided = won + lost;
  if (decided < kMinDecidedForRate) return null;
  return won / decided;
}

String formatWinRateOrDash(int won, int lost) {
  final r = sampleWinRate(won, lost);
  if (r == null) return '—';
  return '${(r * 100).round()}%';
}

bool isWebsiteLead(Map<String, dynamic> row) =>
    sourceOf(row) == EnquiryFields.websiteLeadSourceValue;

/// Enquiries created in [start, end) (IST-agnostic instant bounds from Analytics).
List<Map<String, dynamic>> enquiriesCreatedInPeriod(
  List<Map<String, dynamic>> rows, {
  required DateTime start,
  required DateTime end,
}) {
  return leadRows(rows).where((row) {
    final d = metricDate(row['createdAt']);
    return d != null && !d.isBefore(start) && d.isBefore(end);
  }).toList();
}

/// Approved/completed functions whose function date is in [start, end).
List<FunctionMetric> wonFunctionsDatedInPeriod(
  List<Map<String, dynamic>> rows, {
  required DateTime start,
  required DateTime end,
}) {
  bool inPeriod(DateTime? d) => d != null && !d.isBefore(start) && d.isBefore(end);
  final out = <FunctionMetric>[];
  for (final row in leadRows(rows)) {
    if (!isWon(row)) continue;
    for (final f in metricFunctionsOf(row)) {
      if (inPeriod(f.date)) out.add(f);
    }
  }
  return out;
}

// ── Section 1: Enquiries by weekday ──────────────────────────────────────────

class WeekdayEnquiryRow {
  const WeekdayEnquiryRow({
    required this.weekdayIndex,
    required this.label,
    required this.enquiries,
    required this.won,
    required this.lost,
  });

  final int weekdayIndex;
  final String label;
  final int enquiries;
  final int won;
  final int lost;

  int get decided => won + lost;
  double? get winRate => sampleWinRate(won, lost);
}

class WeekdayEnquiryReport {
  const WeekdayEnquiryReport({required this.rows, required this.summary});

  final List<WeekdayEnquiryRow> rows;
  final String summary;
  int get total => rows.fold(0, (a, b) => a + b.enquiries);
}

WeekdayEnquiryReport computeEnquiriesByWeekday(List<Map<String, dynamic>> createdInPeriod) {
  final counts = List<int>.filled(7, 0);
  final won = List<int>.filled(7, 0);
  final lost = List<int>.filled(7, 0);
  for (final row in createdInPeriod) {
    final created = metricDate(row['createdAt']);
    if (created == null) continue;
    final i = istWeekdayIndex(created);
    counts[i]++;
    if (isWon(row)) won[i]++;
    if (isLostRow(row)) lost[i]++;
  }
  final rows = [
    for (var i = 0; i < 7; i++)
      WeekdayEnquiryRow(
        weekdayIndex: i,
        label: kWeekdayLabels[i],
        enquiries: counts[i],
        won: won[i],
        lost: lost[i],
      ),
  ];
  final total = counts.fold<int>(0, (a, b) => a + b);
  String summary;
  if (total == 0) {
    summary = 'No enquiries in this period.';
  } else {
    final peak = [...rows]
      ..sort((a, b) {
        final byCount = b.enquiries.compareTo(a.enquiries);
        return byCount != 0 ? byCount : a.weekdayIndex.compareTo(b.weekdayIndex);
      });
    final top = peak.first;
    final share = ((top.enquiries / total) * 100).round();
    final withRate = rows.where((r) => r.winRate != null).toList()
      ..sort((a, b) {
        final byRate = b.winRate!.compareTo(a.winRate!);
        return byRate != 0 ? byRate : a.weekdayIndex.compareTo(b.weekdayIndex);
      });
    final buf = StringBuffer('Most enquiries arrive on ${top.label} ($share%).');
    if (withRate.isNotEmpty) {
      final best = withRate.first;
      buf.write(' Best win rate: ${best.label} (${(best.winRate! * 100).round()}%).');
    }
    summary = buf.toString();
  }
  return WeekdayEnquiryReport(rows: rows, summary: summary);
}

// ── Section 2: Enquiries by time of day ──────────────────────────────────────

class TimeOfDayGrid {
  const TimeOfDayGrid({
    required this.cells,
    required this.rowTotals,
    required this.colTotals,
    required this.grandTotal,
  });

  /// [weekday][bucket] counts; weekday 0=Mon.
  final List<List<int>> cells;
  final List<int> rowTotals;
  final List<int> colTotals;
  final int grandTotal;
}

TimeOfDayGrid computeEnquiriesByTimeOfDay(List<Map<String, dynamic>> createdInPeriod) {
  final cells = List.generate(7, (_) => List<int>.filled(TimeOfDayBucket.values.length, 0));
  for (final row in createdInPeriod) {
    final created = metricDate(row['createdAt']);
    if (created == null) continue;
    final w = istWeekdayIndex(created);
    final b = timeOfDayBucket(created).index;
    cells[w][b]++;
  }
  final rowTotals = [for (final row in cells) row.fold(0, (a, b) => a + b)];
  final colTotals = List<int>.filled(TimeOfDayBucket.values.length, 0);
  for (final row in cells) {
    for (var c = 0; c < row.length; c++) {
      colTotals[c] += row[c];
    }
  }
  final grand = rowTotals.fold(0, (a, b) => a + b);
  return TimeOfDayGrid(cells: cells, rowTotals: rowTotals, colTotals: colTotals, grandTotal: grand);
}

// ── Section 3: Response time by arrival ──────────────────────────────────────

class ResponseArrivalRow {
  const ResponseArrivalRow({
    required this.label,
    required this.enquiries,
    required this.median,
    required this.within24h,
    required this.neverContacted,
    required this.won,
    required this.lost,
    required this.measuredCount,
  });

  final String label;
  final int enquiries;
  final Duration? median;
  final double? within24h;
  final int neverContacted;
  final int won;
  final int lost;
  final int measuredCount;

  double? get winRate => sampleWinRate(won, lost);
}

class ResponseArrivalReport {
  const ResponseArrivalReport({required this.byWeekday, required this.byBucket});

  final List<ResponseArrivalRow> byWeekday;
  final List<ResponseArrivalRow> byBucket;
}

ResponseArrivalRow _responseRow(String label, List<Map<String, dynamic>> rows) {
  final times = <Duration>[];
  var never = 0;
  var won = 0;
  var lost = 0;
  var within = 0;
  for (final row in rows) {
    if (isWon(row)) won++;
    if (isLostRow(row)) lost++;
    if (row['firstContactEstimated'] == true) continue;
    final rt = responseTime(row);
    if (rt != null) {
      times.add(rt);
      if (rt.inHours < 24) within++;
    } else if (metricDate(row['firstContactAt']) == null) {
      never++;
    }
  }
  final measured = times.length;
  return ResponseArrivalRow(
    label: label,
    enquiries: rows.length,
    median: measured >= kMinSampleForMedian ? percentileDuration(times, 0.5) : null,
    within24h: measured == 0 ? null : within / measured,
    neverContacted: never,
    won: won,
    lost: lost,
    measuredCount: measured,
  );
}

ResponseArrivalReport computeResponseByArrival(List<Map<String, dynamic>> createdInPeriod) {
  final byWd = List.generate(7, (_) => <Map<String, dynamic>>[]);
  final byBucket = {for (final b in TimeOfDayBucket.values) b: <Map<String, dynamic>>[]};
  for (final row in createdInPeriod) {
    final created = metricDate(row['createdAt']);
    if (created == null) continue;
    byWd[istWeekdayIndex(created)].add(row);
    byBucket[timeOfDayBucket(created)]!.add(row);
  }
  return ResponseArrivalReport(
    byWeekday: [for (var i = 0; i < 7; i++) _responseRow(kWeekdayLabels[i], byWd[i])],
    byBucket: [for (final b in TimeOfDayBucket.values) _responseRow(b.label, byBucket[b]!)],
  );
}

// ── Section 4: Events by weekday ─────────────────────────────────────────────

class WeekdayEventRow {
  const WeekdayEventRow({
    required this.weekdayIndex,
    required this.label,
    required this.events,
    required this.byType,
  });

  final int weekdayIndex;
  final String label;
  final int events;

  /// Top types + Other for this weekday (ordered).
  final Map<String, int> byType;
}

class WeekdayEventReport {
  const WeekdayEventReport({
    required this.rows,
    required this.typeColumns,
    required this.weekendShare,
    required this.summary,
  });

  final List<WeekdayEventRow> rows;
  final List<String> typeColumns;
  final double? weekendShare;
  final String summary;
  int get total => rows.fold(0, (a, b) => a + b.events);
}

WeekdayEventReport computeEventsByWeekday(List<FunctionMetric> functions) {
  final counts = List<int>.filled(7, 0);
  final typeCounts = List.generate(7, (_) => <String, int>{});
  final globalTypes = <String, int>{};
  for (final f in functions) {
    final d = f.date;
    if (d == null) continue;
    final i = istWeekdayIndex(d);
    counts[i]++;
    typeCounts[i][f.eventType] = (typeCounts[i][f.eventType] ?? 0) + 1;
    globalTypes[f.eventType] = (globalTypes[f.eventType] ?? 0) + 1;
  }
  final topTypes = globalTypes.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  final typeColumns = topTypes.take(4).map((e) => e.key).toList();
  final total = counts.fold(0, (a, b) => a + b);
  final weekend = counts[5] + counts[6];
  final weekendShare = total == 0 ? null : weekend / total;

  final rows = <WeekdayEventRow>[];
  for (var i = 0; i < 7; i++) {
    final byType = <String, int>{for (final t in typeColumns) t: typeCounts[i][t] ?? 0};
    var other = 0;
    for (final e in typeCounts[i].entries) {
      if (!typeColumns.contains(e.key)) other += e.value;
    }
    byType['Other'] = other;
    rows.add(
      WeekdayEventRow(weekdayIndex: i, label: kWeekdayLabels[i], events: counts[i], byType: byType),
    );
  }

  final summary = weekendShare == null
      ? 'No events in this period.'
      : 'Weekend (Sat–Sun): ${(weekendShare * 100).round()}% of events.';

  return WeekdayEventReport(
    rows: rows,
    typeColumns: [...typeColumns, 'Other'],
    weekendShare: weekendShare,
    summary: summary,
  );
}

// ── Section 5: Busiest dates ─────────────────────────────────────────────────

class BusyDateRow {
  const BusyDateRow({required this.dayStart, required this.events, required this.eventTypes});

  /// IST calendar day at noon IST (stable for labels).
  final DateTime dayStart;
  final int events;
  final List<String> eventTypes;
}

class BusiestDatesReport {
  const BusiestDatesReport({
    required this.maxOnSingleDay,
    required this.daysWith2Plus,
    required this.daysWith3Plus,
    required this.topDates,
  });

  final int maxOnSingleDay;
  final int daysWith2Plus;
  final int daysWith3Plus;
  final List<BusyDateRow> topDates;
}

BusiestDatesReport computeBusiestDates(List<FunctionMetric> functions) {
  final byDay = <String, List<FunctionMetric>>{};
  for (final f in functions) {
    final d = f.date;
    if (d == null) continue;
    final ist = IstDate.calendar(d);
    final key =
        '${ist.year.toString().padLeft(4, '0')}-'
        '${ist.month.toString().padLeft(2, '0')}-'
        '${ist.day.toString().padLeft(2, '0')}';
    (byDay[key] ??= []).add(f);
  }
  var max = 0;
  var d2 = 0;
  var d3 = 0;
  final rows = <BusyDateRow>[];
  for (final e in byDay.entries) {
    final n = e.value.length;
    if (n > max) max = n;
    if (n >= 2) d2++;
    if (n >= 3) d3++;
    final parts = e.key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final dayStart = IstDate.startOfDay(y, m, day).add(const Duration(hours: 12));
    final types = e.value.map((f) => f.eventType).toSet().toList()..sort();
    rows.add(BusyDateRow(dayStart: dayStart, events: n, eventTypes: types));
  }
  rows.sort((a, b) {
    final byCount = b.events.compareTo(a.events);
    if (byCount != 0) return byCount;
    return b.dayStart.compareTo(a.dayStart);
  });
  return BusiestDatesReport(
    maxOnSingleDay: max,
    daysWith2Plus: d2,
    daysWith3Plus: d3,
    topDates: rows.take(10).toList(),
  );
}

// ── Section 6: Season YoY ────────────────────────────────────────────────────

class SeasonMonthRow {
  const SeasonMonthRow({
    required this.monthStart,
    required this.byType,
    required this.other,
    required this.total,
    this.priorTotal,
    this.change,
  });

  final DateTime monthStart;
  final Map<String, int> byType;
  final int other;
  final int total;
  final int? priorTotal;
  final int? change;
}

class SeasonReport {
  const SeasonReport({
    required this.rows,
    required this.typeColumns,
    required this.hasYearEarlier,
    required this.note,
  });

  final List<SeasonMonthRow> rows;
  final List<String> typeColumns;
  final bool hasYearEarlier;
  final String? note;
}

/// Last 12 full months (ending [lastFullMonth]) vs the 12 before, by function date.
SeasonReport computeSeasonByEventType(List<Map<String, dynamic>> allRows, {required DateTime now}) {
  final istNow = IstDate.calendar(now);
  // Last full month = previous calendar month in IST.
  final lastFull = DateTime.utc(istNow.year, istNow.month - 1, 1);
  final months = <DateTime>[
    for (var i = 11; i >= 0; i--) DateTime.utc(lastFull.year, lastFull.month - i, 1),
  ];

  final wonFns = <FunctionMetric>[];
  for (final row in leadRows(allRows)) {
    if (!isWon(row)) continue;
    wonFns.addAll(metricFunctionsOf(row));
  }

  // Span covering current 12 + prior 12 for top types.
  final spanStart = DateTime.utc(lastFull.year, lastFull.month - 23, 1);
  final spanEnd = DateTime.utc(lastFull.year, lastFull.month + 1, 1);
  final spanStartIst = IstDate.startOfDay(spanStart.year, spanStart.month, 1);
  final spanEndIst = IstDate.startOfDay(spanEnd.year, spanEnd.month, 1);

  final typeTotals = <String, int>{};
  final monthMaps = <String, Map<String, int>>{};
  DateTime? earliest;
  for (final f in wonFns) {
    final d = f.date;
    if (d == null) continue;
    if (earliest == null || d.isBefore(earliest)) earliest = d;
    if (d.isBefore(spanStartIst) || !d.isBefore(spanEndIst)) continue;
    final ist = IstDate.calendar(d);
    final key = '${ist.year}-${ist.month.toString().padLeft(2, '0')}';
    final map = monthMaps.putIfAbsent(key, () => {});
    map[f.eventType] = (map[f.eventType] ?? 0) + 1;
    typeTotals[f.eventType] = (typeTotals[f.eventType] ?? 0) + 1;
  }

  final topTypes = typeTotals.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  final typeColumns = topTypes.take(5).map((e) => e.key).toList();

  // Need ≥13 months of data from earliest function to lastFull.
  var hasYearEarlier = false;
  String? note;
  if (earliest != null) {
    final eIst = IstDate.calendar(earliest);
    final monthsSpan = (lastFull.year - eIst.year) * 12 + (lastFull.month - eIst.month) + 1;
    hasYearEarlier = monthsSpan >= 13;
  }
  if (!hasYearEarlier) {
    note = 'Fewer than 13 months of event history — year-earlier comparison hidden.';
  }

  final rows = <SeasonMonthRow>[];
  for (final m in months) {
    final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
    final map = monthMaps[key] ?? {};
    final byType = <String, int>{for (final t in typeColumns) t: map[t] ?? 0};
    var other = 0;
    for (final e in map.entries) {
      if (!typeColumns.contains(e.key)) other += e.value;
    }
    final total = byType.values.fold(0, (a, b) => a + b) + other;
    int? prior;
    int? change;
    if (hasYearEarlier) {
      final priorKey = '${m.year - 1}-${m.month.toString().padLeft(2, '0')}';
      final priorMap = monthMaps[priorKey] ?? <String, int>{};
      prior = priorMap.values.fold<int>(0, (a, b) => a + b);
      change = total - prior;
    }
    rows.add(
      SeasonMonthRow(
        monthStart: m,
        byType: byType,
        other: other,
        total: total,
        priorTotal: prior,
        change: change,
      ),
    );
  }

  return SeasonReport(
    rows: rows,
    typeColumns: typeColumns,
    hasYearEarlier: hasYearEarlier,
    note: note,
  );
}

// ── Section 7: Lead time + win rate ──────────────────────────────────────────

class LeadTimeWinRow {
  const LeadTimeWinRow({
    required this.key,
    required this.label,
    required this.count,
    required this.won,
    required this.lost,
  });

  final String key;
  final String label;
  final int count;
  final int won;
  final int lost;

  double? get winRate => sampleWinRate(won, lost);
}

class LeadTimeWinReport {
  const LeadTimeWinReport({required this.rows, required this.summary});

  final List<LeadTimeWinRow> rows;
  final String summary;
  int get total => rows.fold(0, (a, b) => a + b.count);
}

LeadTimeWinReport computeLeadTimeWithWinRates(
  List<Map<String, dynamic>> createdInPeriod, {
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
  final won = List<int>.filled(labels.length, 0);
  final lost = List<int>.filled(labels.length, 0);

  // Match computeLeadTime: per function of period bookings (created in period).
  final fns = functions ?? [for (final row in createdInPeriod) ...metricFunctionsOf(row)];

  for (final f in fns) {
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
    if (isWon(f.row)) won[i]++;
    if (isLostRow(f.row)) lost[i]++;
  }

  final rows = [
    for (var i = 0; i < labels.length; i++)
      LeadTimeWinRow(
        key: labels[i].$1,
        label: labels[i].$2,
        count: counts[i],
        won: won[i],
        lost: lost[i],
      ),
  ];

  final withRate = rows.where((r) => r.winRate != null).toList()
    ..sort((a, b) {
      final byRate = b.winRate!.compareTo(a.winRate!);
      return byRate != 0 ? byRate : a.key.compareTo(b.key);
    });
  final summary = withRate.isEmpty
      ? 'Not enough decided enquiries to name a best lead-time bucket.'
      : 'Best win rate: ${withRate.first.label} '
            '(${(withRate.first.winRate! * 100).round()}%).';

  return LeadTimeWinReport(rows: rows, summary: summary);
}

// ── Aggregate TimingReport ───────────────────────────────────────────────────

class TimingReport {
  const TimingReport({
    required this.weekdayEnquiries,
    required this.timeOfDay,
    required this.timeOfDayWebsiteOnly,
    required this.responseArrival,
    required this.eventsByWeekday,
    required this.busiestDates,
    required this.season,
    required this.leadTime,
  });

  final WeekdayEnquiryReport weekdayEnquiries;
  final TimeOfDayGrid timeOfDay;
  final TimeOfDayGrid timeOfDayWebsiteOnly;
  final ResponseArrivalReport responseArrival;
  final WeekdayEventReport eventsByWeekday;
  final BusiestDatesReport busiestDates;
  final SeasonReport season;
  final LeadTimeWinReport leadTime;
}

TimingReport buildTimingReport({
  required List<Map<String, dynamic>> allRows,
  required DateTime start,
  required DateTime end,
  required DateTime now,
}) {
  final created = enquiriesCreatedInPeriod(allRows, start: start, end: end);
  final websiteOnly = created.where(isWebsiteLead).toList();
  final functions = wonFunctionsDatedInPeriod(allRows, start: start, end: end);
  // Lead-time uses functions of bookings created in the period (same as old
  // computeLeadTime on period rows with enquiry attribution).
  final periodFns = [for (final row in created) ...metricFunctionsOf(row)];

  return TimingReport(
    weekdayEnquiries: computeEnquiriesByWeekday(created),
    timeOfDay: computeEnquiriesByTimeOfDay(created),
    timeOfDayWebsiteOnly: computeEnquiriesByTimeOfDay(websiteOnly),
    responseArrival: computeResponseByArrival(created),
    eventsByWeekday: computeEventsByWeekday(functions),
    busiestDates: computeBusiestDates(functions),
    season: computeSeasonByEventType(allRows, now: now),
    leadTime: computeLeadTimeWithWinRates(created, functions: periodFns),
  );
}
