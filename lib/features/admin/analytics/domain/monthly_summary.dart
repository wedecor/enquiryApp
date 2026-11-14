import '../../../../core/constants/status_vocabulary.dart';
import '../../../enquiries/domain/enquiry_lifecycle.dart';
import '../../../reengagement/domain/occasion_reminder.dart';
import '../../../reengagement/domain/reengagement_stats.dart';
import 'pipeline_metrics.dart';
import 'timing_metrics.dart';

/// Fallback when a won row has no [EnquiryStageFields.approvedAt].
///
/// Pipeline metrics only treat `approvedAt` as a presence flag (no dated
/// fallback). For "bookings confirmed in the month" we need an instant, so
/// legacy won rows without `approvedAt` use `completedAt`, then `updatedAt`.
const String kApprovedAtFallback = 'completedAt, then updatedAt';

const List<String> _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// One IST calendar month as year + month (1–12).
class SummaryMonth {
  const SummaryMonth(this.year, this.month);

  final int year;
  final int month;

  /// Instant of 00:00 IST on the 1st of this month.
  DateTime get start => IstDate.startOfDay(year, month, 1);

  /// Instant of 00:00 IST on the 1st of the next month (exclusive end).
  DateTime get endExclusive {
    final next = month == 12 ? SummaryMonth(year + 1, 1) : SummaryMonth(year, month + 1);
    return next.start;
  }

  SummaryMonth get previous {
    if (month == 1) return SummaryMonth(year - 1, 12);
    return SummaryMonth(year, month - 1);
  }

  SummaryMonth get sameMonthLastYear => SummaryMonth(year - 1, month);

  SummaryMonth get next {
    if (month == 12) return SummaryMonth(year + 1, 1);
    return SummaryMonth(year, month + 1);
  }

  /// IST calendar month containing [now].
  factory SummaryMonth.containing(DateTime now) {
    final ist = IstDate.calendar(now);
    return SummaryMonth(ist.year, ist.month);
  }

  /// Last complete IST calendar month before [now]'s month.
  factory SummaryMonth.lastComplete(DateTime now) => SummaryMonth.containing(now).previous;

  String get label => '${_kMonthNames[month - 1]} $year';

  String get fileStamp => '$year-${month < 10 ? '0$month' : '$month'}';

  @override
  bool operator ==(Object other) =>
      other is SummaryMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// Diff vs a comparison month. Null [pct] when the earlier value is zero
/// (show the plain [delta] instead). Entire comparison is omitted when the
/// comparison month had no data ([hasData] false).
class MetricComparison {
  const MetricComparison({required this.hasData, this.delta, this.pct});

  final bool hasData;
  final num? delta;
  final double? pct;

  static const hidden = MetricComparison(hasData: false);

  static MetricComparison fromInts({
    required int current,
    required int prior,
    required bool priorMonthHasData,
  }) {
    if (!priorMonthHasData) return hidden;
    final delta = current - prior;
    if (prior == 0) return MetricComparison(hasData: true, delta: delta);
    return MetricComparison(hasData: true, delta: delta, pct: delta / prior);
  }

  static MetricComparison fromRates({
    required double? current,
    required double? prior,
    required bool priorMonthHasData,
  }) {
    if (!priorMonthHasData || prior == null || current == null) return hidden;
    final delta = current - prior;
    if (prior == 0) return MetricComparison(hasData: true, delta: delta);
    return MetricComparison(hasData: true, delta: delta, pct: delta / prior);
  }

  static MetricComparison fromDurations({
    required Duration? current,
    required Duration? prior,
    required bool priorMonthHasData,
  }) {
    if (!priorMonthHasData || prior == null || current == null) return hidden;
    final deltaMs = current.inMilliseconds - prior.inMilliseconds;
    if (prior.inMilliseconds == 0) {
      return MetricComparison(hasData: true, delta: deltaMs);
    }
    return MetricComparison(hasData: true, delta: deltaMs, pct: deltaMs / prior.inMilliseconds);
  }
}

class HeadlineMetric {
  const HeadlineMetric({
    required this.value,
    this.hasValue = true,
    required this.vsPreviousMonth,
    required this.vsSameMonthLastYear,
  });

  /// Numeric value (counts, win-rate 0–1, or median minutes).
  final num value;

  /// False when the metric is undefined (e.g. win rate with zero decided).
  final bool hasValue;
  final MetricComparison vsPreviousMonth;
  final MetricComparison vsSameMonthLastYear;
}

class SourceSummaryRow {
  const SourceSummaryRow({
    required this.source,
    required this.enquiries,
    required this.bookings,
    required this.decided,
    required this.isBestConverting,
  });

  final String source;
  final int enquiries;
  final int bookings;
  final int decided;
  final bool isBestConverting;

  double? get conversionRate {
    if (decided < kMinDecidedForRate) return null;
    return bookings / decided;
  }
}

class CountLabelRow {
  const CountLabelRow({required this.label, required this.count});
  final String label;
  final int count;
}

class LostSummary {
  const LostSummary({
    required this.total,
    required this.topReasons,
    required this.beforeConversation,
    required this.afterTalks,
  });

  final int total;
  final List<CountLabelRow> topReasons;
  final int beforeConversation;
  final int afterTalks;
}

class EventsDeliveredSummary {
  const EventsDeliveredSummary({
    required this.total,
    this.busiestDate,
    this.busiestCount = 0,
    required this.daysWithTwoOrMore,
  });

  final int total;

  /// 00:00 IST of the busiest day, or null.
  final DateTime? busiestDate;
  final int busiestCount;
  final int daysWithTwoOrMore;
}

class TimingSummary {
  const TimingSummary({this.busiestEnquiryWeekday, this.busiestEventWeekday});

  final String? busiestEnquiryWeekday;
  final String? busiestEventWeekday;
}

class TeamMemberSummary {
  const TeamMemberSummary({
    required this.uid,
    required this.name,
    required this.enquiriesAssigned,
    required this.bookingsConfirmed,
    this.medianFirstResponse,
    required this.contactsLogged,
  });

  final String uid;
  final String name;
  final int enquiriesAssigned;
  final int bookingsConfirmed;
  final Duration? medianFirstResponse;

  /// Sum of `contactCount` on that month's assigned enquiries.
  final int contactsLogged;
}

class WishesSummary {
  const WishesSummary({required this.sent, required this.cameBack});
  final int sent;
  final int cameBack;
}

class StillOpenSummary {
  const StillOpenSummary({
    required this.openNow,
    required this.olderThan30Days,
    required this.eventDatePassed,
  });

  final int openNow;
  final int olderThan30Days;
  final int eventDatePassed;
}

class WeekAheadRow {
  const WeekAheadRow({
    required this.weekStart,
    required this.weekEnd,
    required this.confirmedEvents,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int confirmedEvents;
}

class MonthAheadSummary {
  const MonthAheadSummary({required this.weeks, required this.inTalksWithDate});

  final List<WeekAheadRow> weeks;
  final int inTalksWithDate;
}

/// Pure monthly summary — screen and PDF both render from this object.
class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.isPartialMonth,
    required this.isEmpty,
    required this.sentences,
    required this.newEnquiries,
    required this.bookingsConfirmed,
    required this.eventsCompleted,
    required this.winRate,
    required this.medianFirstResponse,
    required this.sources,
    required this.bookingsByEventType,
    required this.bookingsByArea,
    required this.returningCustomers,
    required this.newCustomers,
    required this.lost,
    required this.eventsDelivered,
    required this.timing,
    required this.team,
    required this.wishes,
    this.stillOpen,
    this.monthAhead,
  });

  final SummaryMonth month;
  final bool isPartialMonth;
  final bool isEmpty;
  final List<String> sentences;

  final HeadlineMetric newEnquiries;
  final HeadlineMetric bookingsConfirmed;
  final HeadlineMetric eventsCompleted;
  final HeadlineMetric winRate;
  final HeadlineMetric medianFirstResponse;

  final List<SourceSummaryRow> sources;
  final List<CountLabelRow> bookingsByEventType;
  final List<CountLabelRow> bookingsByArea;
  final int returningCustomers;
  final int newCustomers;
  final LostSummary lost;
  final EventsDeliveredSummary eventsDelivered;
  final TimingSummary timing;
  final List<TeamMemberSummary> team;
  final WishesSummary wishes;
  final StillOpenSummary? stillOpen;
  final MonthAheadSummary? monthAhead;
}

/// Instant a booking was confirmed (moved to Approved).
///
/// Prefer `approvedAt`. Legacy won rows without it use [kApprovedAtFallback].
DateTime? bookingConfirmedAt(Map<String, dynamic> row) {
  final approved = metricDate(row[EnquiryStageFields.approvedAt]);
  if (approved != null) return approved;
  if (!isWon(row)) return null;
  return metricDate(row[EnquiryStageFields.completedAt]) ?? metricDate(row['updatedAt']);
}

/// Instant an enquiry was lost — `lostAt`, else `updatedAt` on lost rows.
DateTime? lostAtOf(Map<String, dynamic> row) {
  final lost = metricDate(row[EnquiryStageFields.lostAt]);
  if (lost != null) return lost;
  if (!isLostRow(row)) return null;
  return metricDate(row['updatedAt']);
}

bool _inMonth(DateTime? d, SummaryMonth m) =>
    d != null && !d.isBefore(m.start) && d.isBefore(m.endExclusive);

bool _monthHasEnquiryData(List<Map<String, dynamic>> leads, SummaryMonth m) {
  return leads.any((r) => _inMonth(metricDate(r['createdAt']), m));
}

String _phoneOf(Map<String, dynamic> row) {
  final p = row['phoneNormalized'];
  return p is String ? p.trim() : '';
}

List<Map<String, dynamic>> _createdIn(List<Map<String, dynamic>> leads, SummaryMonth m) =>
    leads.where((r) => _inMonth(metricDate(r['createdAt']), m)).toList();

List<Map<String, dynamic>> _bookingsIn(List<Map<String, dynamic>> leads, SummaryMonth m) =>
    leads.where((r) => _inMonth(bookingConfirmedAt(r), m)).toList();

List<Map<String, dynamic>> _lostIn(List<Map<String, dynamic>> leads, SummaryMonth m) =>
    leads.where((r) => isLostRow(r) && _inMonth(lostAtOf(r), m)).toList();

Duration? _medianResponse(List<Map<String, dynamic>> rows) {
  final times = rows.map(responseTime).whereType<Duration>().toList();
  if (times.length < kMinSampleForMedian) return null;
  return percentileDuration(times, 0.5);
}

double? _winRateValue(int won, int lost) {
  final decided = won + lost;
  if (decided == 0) return null;
  return won / decided;
}

HeadlineMetric _intHeadline({
  required int current,
  required int prior,
  required int yoy,
  required bool priorHasData,
  required bool yoyHasData,
}) {
  return HeadlineMetric(
    value: current,
    vsPreviousMonth: MetricComparison.fromInts(
      current: current,
      prior: prior,
      priorMonthHasData: priorHasData,
    ),
    vsSameMonthLastYear: MetricComparison.fromInts(
      current: current,
      prior: yoy,
      priorMonthHasData: yoyHasData,
    ),
  );
}

List<CountLabelRow> _sortedCounts(Map<String, int> map) {
  final list = map.entries.map((e) => CountLabelRow(label: e.key, count: e.value)).toList()
    ..sort((a, b) {
      final byC = b.count.compareTo(a.count);
      return byC != 0 ? byC : a.label.compareTo(b.label);
    });
  return list;
}

String? _topWeekday(List<int> counts) {
  var best = -1;
  var idx = -1;
  for (var i = 0; i < 7; i++) {
    if (counts[i] > best) {
      best = counts[i];
      idx = i;
    }
  }
  return best > 0 ? kWeekdayLabels[idx] : null;
}

/// Builds the monthly summary from analytics rows + wish reminders.
///
/// [teamNames] maps uid → display name (team names only; never customer PII).
/// When non-empty, only uids present in the map (active members) are listed.
MonthlySummary buildMonthlySummary({
  required List<Map<String, dynamic>> rows,
  required SummaryMonth month,
  required DateTime now,
  required List<SentReminder> wishReminders,
  Map<String, String> teamNames = const {},
}) {
  final leads = leadRows(rows);
  final currentMonth = SummaryMonth.containing(now);
  final lastComplete = SummaryMonth.lastComplete(now);
  final isPartial = month == currentMonth;
  final showForwardLooking = month == currentMonth || month == lastComplete;

  final prior = month.previous;
  final yoy = month.sameMonthLastYear;
  final priorHasData = _monthHasEnquiryData(leads, prior);
  final yoyHasData = _monthHasEnquiryData(leads, yoy);

  final created = _createdIn(leads, month);
  final bookings = _bookingsIn(leads, month);
  final lostRows = _lostIn(leads, month);
  final events = wonFunctionsDatedInPeriod(leads, start: month.start, end: month.endExclusive);

  final createdPrior = _createdIn(leads, prior).length;
  final createdYoy = _createdIn(leads, yoy).length;
  final bookingsPriorN = _bookingsIn(leads, prior).length;
  final bookingsYoyN = _bookingsIn(leads, yoy).length;
  final eventsPrior = wonFunctionsDatedInPeriod(
    leads,
    start: prior.start,
    end: prior.endExclusive,
  ).length;
  final eventsYoy = wonFunctionsDatedInPeriod(
    leads,
    start: yoy.start,
    end: yoy.endExclusive,
  ).length;

  final lostPriorN = _lostIn(leads, prior).length;
  final lostYoyN = _lostIn(leads, yoy).length;
  final winCurrent = _winRateValue(bookings.length, lostRows.length);
  final winPrior = _winRateValue(bookingsPriorN, lostPriorN);
  final winYoy = _winRateValue(bookingsYoyN, lostYoyN);

  final medianCurrent = _medianResponse(created);
  final medianPrior = _medianResponse(_createdIn(leads, prior));
  final medianYoy = _medianResponse(_createdIn(leads, yoy));

  final isEmpty = created.isEmpty && bookings.isEmpty && events.isEmpty && lostRows.isEmpty;

  // Sources
  final sourceEnquiries = <String, int>{};
  final sourceBookings = <String, int>{};
  final sourceLost = <String, int>{};
  for (final r in created) {
    final s = sourceOf(r);
    sourceEnquiries[s] = (sourceEnquiries[s] ?? 0) + 1;
  }
  for (final r in bookings) {
    final s = sourceOf(r);
    sourceBookings[s] = (sourceBookings[s] ?? 0) + 1;
  }
  for (final r in lostRows) {
    final s = sourceOf(r);
    sourceLost[s] = (sourceLost[s] ?? 0) + 1;
  }
  final allSources = {...sourceEnquiries.keys, ...sourceBookings.keys, ...sourceLost.keys};
  String? bestSource;
  var bestRate = -1.0;
  for (final s in allSources) {
    final won = sourceBookings[s] ?? 0;
    final lost = sourceLost[s] ?? 0;
    final decided = won + lost;
    if (decided < kMinDecidedForRate) continue;
    final rate = won / decided;
    if (rate > bestRate) {
      bestRate = rate;
      bestSource = s;
    }
  }
  final sources =
      allSources.map((s) {
        final won = sourceBookings[s] ?? 0;
        final lost = sourceLost[s] ?? 0;
        return SourceSummaryRow(
          source: s,
          enquiries: sourceEnquiries[s] ?? 0,
          bookings: won,
          decided: won + lost,
          isBestConverting: s == bestSource,
        );
      }).toList()..sort((a, b) {
        final byEnq = b.enquiries.compareTo(a.enquiries);
        return byEnq != 0 ? byEnq : a.source.compareTo(b.source);
      });

  // What was booked
  final byType = <String, int>{};
  final byArea = <String, int>{};
  for (final r in bookings) {
    byType[eventTypeOf(r)] = (byType[eventTypeOf(r)] ?? 0) + 1;
    final area = areaKeyOf(r);
    final label = area.isEmpty
        ? 'Not specified'
        : areaDisplayLabel((r['locationArea'] as String?) ?? area);
    byArea[label] = (byArea[label] ?? 0) + 1;
  }

  var returning = 0;
  var newCust = 0;
  for (final r in bookings) {
    final phone = _phoneOf(r);
    final confirmed = bookingConfirmedAt(r) ?? metricDate(r['createdAt']);
    if (phone.isEmpty || confirmed == null) {
      newCust++;
      continue;
    }
    final earlierCompleted = leads.any((other) {
      if (other['id'] == r['id']) return false;
      if (_phoneOf(other) != phone) return false;
      final st = metricStatus(other);
      final completedAt = metricDate(other[EnquiryStageFields.completedAt]);
      final isCompleted = st == EnquiryStatus.completed || completedAt != null;
      if (!isCompleted) return false;
      final when = completedAt ?? metricDate(other['createdAt']);
      return when != null && when.isBefore(confirmed);
    });
    if (earlierCompleted) {
      returning++;
    } else {
      newCust++;
    }
  }

  // Lost
  final reasonCounts = <String, int>{};
  var beforeConv = 0;
  var afterTalks = 0;
  for (final r in lostRows) {
    final raw = (r['lostReason'] as String?)?.trim();
    final label = LostReason.labelOf(raw);
    reasonCounts[label] = (reasonCounts[label] ?? 0) + 1;
    if (furthestStage(r) >= 1) {
      afterTalks++;
    } else {
      beforeConv++;
    }
  }
  final topReasons = _sortedCounts(reasonCounts).take(3).toList();

  // Events delivered
  final byDay = <String, int>{};
  final dayInstants = <String, DateTime>{};
  for (final f in events) {
    final d = f.date;
    if (d == null) continue;
    final ist = IstDate.calendar(d);
    final key = '${ist.year}-${ist.month}-${ist.day}';
    byDay[key] = (byDay[key] ?? 0) + 1;
    dayInstants.putIfAbsent(key, () => IstDate.startOfDay(ist.year, ist.month, ist.day));
  }
  String? busiestKey;
  var busiestCount = 0;
  var daysTwoPlus = 0;
  for (final e in byDay.entries) {
    if (e.value >= 2) daysTwoPlus++;
    if (e.value > busiestCount) {
      busiestCount = e.value;
      busiestKey = e.key;
    }
  }

  // Timing
  final enqWd = List<int>.filled(7, 0);
  for (final r in created) {
    final c = metricDate(r['createdAt']);
    if (c != null) enqWd[istWeekdayIndex(c)]++;
  }
  final evtWd = List<int>.filled(7, 0);
  for (final f in events) {
    if (f.date != null) evtWd[istWeekdayIndex(f.date!)]++;
  }

  // Team — active members only when [teamNames] is supplied
  final byAssignee = <String, List<Map<String, dynamic>>>{};
  final workUids = <String>{};
  for (final r in created) {
    final uid = (r['assignedTo'] as String?)?.trim() ?? '';
    if (uid.isEmpty) continue;
    workUids.add(uid);
    (byAssignee[uid] ??= []).add(r);
  }
  final bookingsByAssignee = <String, int>{};
  for (final r in bookings) {
    final uid = (r['assignedTo'] as String?)?.trim() ?? '';
    if (uid.isEmpty) continue;
    workUids.add(uid);
    bookingsByAssignee[uid] = (bookingsByAssignee[uid] ?? 0) + 1;
  }
  final Iterable<String> teamUids = teamNames.isEmpty
      ? workUids
      : workUids.where(teamNames.containsKey);
  final team = <TeamMemberSummary>[];
  for (final uid in teamUids) {
    final assigned = byAssignee[uid] ?? const <Map<String, dynamic>>[];
    final contacts = assigned.fold<int>(
      0,
      (sum, r) => sum + (metricNum(r['contactCount'])?.toInt() ?? 0),
    );
    team.add(
      TeamMemberSummary(
        uid: uid,
        name: teamNames[uid] ?? uid,
        enquiriesAssigned: assigned.length,
        bookingsConfirmed: bookingsByAssignee[uid] ?? 0,
        medianFirstResponse: _medianResponse(assigned),
        contactsLogged: contacts,
      ),
    );
  }
  team.sort((a, b) {
    final byE = b.enquiriesAssigned.compareTo(a.enquiriesAssigned);
    return byE != 0 ? byE : a.name.compareTo(b.name);
  });

  // Wishes
  final wishesInMonth = wishReminders
      .where((w) => !w.sentAt.isBefore(month.start) && w.sentAt.isBefore(month.endExclusive))
      .toList();
  final arrivals = <EnquiryArrival>[];
  for (final r in leads) {
    final phone = _phoneOf(r);
    final createdAt = metricDate(r['createdAt']);
    if (phone.isEmpty || createdAt == null) continue;
    arrivals.add(EnquiryArrival(phoneNormalized: phone, createdAt: createdAt));
  }
  final wishStats = ReengagementStats.compute(sent: wishesInMonth, enquiries: arrivals);

  // Still open / month ahead
  StillOpenSummary? stillOpen;
  MonthAheadSummary? monthAhead;
  if (showForwardLooking) {
    final openRows = leads.where(isOpen).toList();
    var older30 = 0;
    var pastEvent = 0;
    for (final r in openRows) {
      final createdAt = metricDate(r['createdAt']);
      if (createdAt != null && now.difference(createdAt).inDays > 30) older30++;
      final eventDate = metricDate(r['eventDate']);
      if (eventDate != null && eventDate.isBefore(now)) pastEvent++;
    }
    stillOpen = StillOpenSummary(
      openNow: openRows.length,
      olderThan30Days: older30,
      eventDatePassed: pastEvent,
    );

    final next = month.next;
    final nextEvents = wonFunctionsDatedInPeriod(leads, start: next.start, end: next.endExclusive);
    final firstIst = IstDate.calendar(next.start);
    final mondayOffset = (firstIst.weekday - 1) % 7;
    var cursor = next.start.subtract(Duration(days: mondayOffset));
    final weeks = <WeekAheadRow>[];
    while (cursor.isBefore(next.endExclusive)) {
      final weekEnd = cursor.add(const Duration(days: 7));
      final count = nextEvents.where((f) {
        final d = f.date;
        return d != null && !d.isBefore(cursor) && d.isBefore(weekEnd);
      }).length;
      weeks.add(WeekAheadRow(weekStart: cursor, weekEnd: weekEnd, confirmedEvents: count));
      cursor = weekEnd;
    }
    var inTalksNext = 0;
    for (final r in leads) {
      if (metricStatus(r) != EnquiryStatus.inTalks) continue;
      if (_inMonth(metricDate(r['eventDate']), next)) inTalksNext++;
    }
    monthAhead = MonthAheadSummary(weeks: weeks, inTalksWithDate: inTalksNext);
  }

  // Sentences
  final sentences = <String>[];
  final vsPrevBookings = MetricComparison.fromInts(
    current: bookings.length,
    prior: bookingsPriorN,
    priorMonthHasData: priorHasData,
  );
  if (vsPrevBookings.hasData) {
    final d = vsPrevBookings.delta! as int;
    final priorLabel = _kMonthNames[prior.month - 1];
    if (d == 0) {
      sentences.add('Bookings confirmed matched $priorLabel ($bookingsPriorN).');
    } else if (d > 0) {
      sentences.add(
        'Bookings confirmed were $d more than $priorLabel ($bookingsPriorN → ${bookings.length}).',
      );
    } else {
      sentences.add(
        'Bookings confirmed were ${-d} fewer than $priorLabel ($bookingsPriorN → ${bookings.length}).',
      );
    }
  }

  if (sources.isNotEmpty) {
    final mostEnq = sources.first;
    final best = sources.where((s) => s.isBestConverting).toList();
    if (best.isNotEmpty && best.first.source != mostEnq.source) {
      sentences.add(
        'Most enquiries came from ${mostEnq.source} (${mostEnq.enquiries}); '
        'best conversion was ${best.first.source}.',
      );
    } else if (best.isNotEmpty) {
      sentences.add(
        'Most enquiries and best conversion were both ${mostEnq.source} (${mostEnq.enquiries} enquiries).',
      );
    } else {
      sentences.add('Most enquiries came from ${mostEnq.source} (${mostEnq.enquiries}).');
    }
  }

  if (topReasons.isNotEmpty && lostRows.isNotEmpty) {
    final top = topReasons.first;
    sentences.add('Largest lost reason was ${top.label} (${top.count} of ${lostRows.length}).');
  }

  return MonthlySummary(
    month: month,
    isPartialMonth: isPartial,
    isEmpty: isEmpty,
    sentences: sentences,
    newEnquiries: _intHeadline(
      current: created.length,
      prior: createdPrior,
      yoy: createdYoy,
      priorHasData: priorHasData,
      yoyHasData: yoyHasData,
    ),
    bookingsConfirmed: _intHeadline(
      current: bookings.length,
      prior: bookingsPriorN,
      yoy: bookingsYoyN,
      priorHasData: priorHasData,
      yoyHasData: yoyHasData,
    ),
    eventsCompleted: _intHeadline(
      current: events.length,
      prior: eventsPrior,
      yoy: eventsYoy,
      priorHasData: priorHasData,
      yoyHasData: yoyHasData,
    ),
    winRate: HeadlineMetric(
      value: winCurrent ?? 0,
      hasValue: winCurrent != null,
      vsPreviousMonth: MetricComparison.fromRates(
        current: winCurrent,
        prior: winPrior,
        priorMonthHasData: priorHasData && winPrior != null,
      ),
      vsSameMonthLastYear: MetricComparison.fromRates(
        current: winCurrent,
        prior: winYoy,
        priorMonthHasData: yoyHasData && winYoy != null,
      ),
    ),
    medianFirstResponse: HeadlineMetric(
      value: medianCurrent?.inMinutes ?? 0,
      hasValue: medianCurrent != null,
      vsPreviousMonth: MetricComparison.fromDurations(
        current: medianCurrent,
        prior: medianPrior,
        priorMonthHasData: priorHasData && medianPrior != null,
      ),
      vsSameMonthLastYear: MetricComparison.fromDurations(
        current: medianCurrent,
        prior: medianYoy,
        priorMonthHasData: yoyHasData && medianYoy != null,
      ),
    ),
    sources: sources,
    bookingsByEventType: _sortedCounts(byType),
    bookingsByArea: _sortedCounts(byArea),
    returningCustomers: returning,
    newCustomers: newCust,
    lost: LostSummary(
      total: lostRows.length,
      topReasons: topReasons,
      beforeConversation: beforeConv,
      afterTalks: afterTalks,
    ),
    eventsDelivered: EventsDeliveredSummary(
      total: events.length,
      busiestDate: busiestKey == null ? null : dayInstants[busiestKey],
      busiestCount: busiestCount,
      daysWithTwoOrMore: daysTwoPlus,
    ),
    timing: TimingSummary(
      busiestEnquiryWeekday: _topWeekday(enqWd),
      busiestEventWeekday: _topWeekday(evtWd),
    ),
    team: team,
    wishes: WishesSummary(sent: wishStats.sent, cameBack: wishStats.cameBack),
    stillOpen: stillOpen,
    monthAhead: monthAhead,
  );
}
