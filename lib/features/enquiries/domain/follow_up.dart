import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/status_vocabulary.dart';

/// Automatic follow-up state stored on an enquiry document.
///
/// Scheduled follow-up system is switched off (Nov 2026: Follow Up tab uses the
/// 10-day rule in `shouldShowReminder` instead). Kept for existing fields / tests.
///
/// Formerly: Cloud Functions (`functions/src/followUps*.ts`) + `FollowUpService`.
/// docs/IMPLEMENTATION_PLAN_2026-11.md.
enum FollowUpState {
  /// No open follow-up (terminal / booked enquiry, or not scheduled yet).
  none,

  /// Open, not yet due.
  scheduled,

  /// Due now.
  due,

  /// Still open [FollowUpInfo.defaultOverdueHours] after the due time.
  overdue,
}

class FollowUpInfo {
  const FollowUpInfo({
    required this.tracked,
    this.dueAt,
    this.reason,
    this.note,
    this.seq = 0,
    this.lastCompletedAt,
    this.pastEventReview = false,
  });

  factory FollowUpInfo.fromData(Map<String, dynamic> data) {
    final seq = data['followUpSeq'];
    return FollowUpInfo(
      tracked: seq is num,
      dueAt: _date(data['followUpDueAt']),
      reason: data['followUpReason'] as String?,
      note: data['followUpNote'] as String?,
      seq: seq is num ? seq.toInt() : 0,
      lastCompletedAt: _date(data['followUpLastCompletedAt']),
      pastEventReview: data['pastEventReviewAt'] != null,
    );
  }

  /// Mirrors the server default (`followUpOverdueHours`).
  static const int defaultOverdueHours = 24;

  /// Statuses that get automatic follow-ups (server default `followUpEligibleStatuses`).
  static bool isEligibleStatus(String? statusValue) {
    final status = EnquiryStatus.fromValue(statusValue);
    return status == EnquiryStatus.newEnquiry || status == EnquiryStatus.inTalks;
  }

  /// True once the server has managed this enquiry's follow-ups (has `followUpSeq`).
  /// Older documents fall back to the legacy Follow Up tab rule until backfilled.
  final bool tracked;
  final DateTime? dueAt;

  /// `auto` | `callback` | `manual` | `past_event`.
  final String? reason;
  final String? note;
  final int seq;
  final DateTime? lastCompletedAt;

  /// Every event day has passed while the enquiry is still open (needs review).
  final bool pastEventReview;

  bool get isCallback => reason == 'callback';
  bool get isPastEvent => reason == 'past_event' || pastEventReview;

  FollowUpState stateAt(DateTime now, {int overdueHours = defaultOverdueHours}) {
    final due = dueAt;
    if (due == null) return FollowUpState.none;
    if (now.isBefore(due)) return FollowUpState.scheduled;
    if (!now.isBefore(due.add(Duration(hours: overdueHours)))) return FollowUpState.overdue;
    return FollowUpState.due;
  }

  /// Due or overdue now.
  bool isActionableAt(DateTime now) {
    final state = stateAt(now);
    return state == FollowUpState.due || state == FollowUpState.overdue;
  }

  static DateTime? _date(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}

/// "Due in 2 days", "Due today", "Overdue by 3 days" — relative to [now].
String followUpDueLabel(FollowUpInfo info, DateTime now) {
  final due = info.dueAt;
  if (due == null) return 'No follow-up scheduled';
  final state = info.stateAt(now);
  final dueDay = DateTime(due.year, due.month, due.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = dueDay.difference(today).inDays;
  String plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';
  switch (state) {
    case FollowUpState.none:
      return 'No follow-up scheduled';
    case FollowUpState.scheduled:
      if (days <= 0) {
        final hours = due.difference(now).inHours;
        return hours <= 0 ? 'Due within the hour' : 'Due in ${plural(hours, 'hour')}';
      }
      if (days == 1) return 'Due tomorrow';
      return 'Due in ${plural(days, 'day')}';
    case FollowUpState.due:
      return 'Due now';
    case FollowUpState.overdue:
      final late = -days;
      return late <= 0 ? 'Overdue' : 'Overdue by ${plural(late, 'day')}';
  }
}
