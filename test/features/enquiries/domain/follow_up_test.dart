import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/widgets/dashboard_enquiry_utils.dart';
import 'package:we_decor_enquiries/features/enquiries/data/follow_up_service.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/follow_up.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12);
  Map<String, dynamic> tracked({
    String status = 'in_talks',
    DateTime? dueAt,
    String reason = 'auto',
    int seq = 2,
  }) => {
    'statusValue': status,
    'followUpSeq': seq,
    'followUpDueAt': dueAt == null ? null : Timestamp.fromDate(dueAt),
    'followUpReason': reason,
  };

  group('FollowUpInfo.stateAt', () {
    test('scheduled → due → overdue after 24 h', () {
      final due = DateTime(2026, 11, 7, 10);
      final info = FollowUpInfo.fromData(tracked(dueAt: due));
      expect(info.stateAt(due.subtract(const Duration(minutes: 1))), FollowUpState.scheduled);
      expect(info.stateAt(due), FollowUpState.due);
      expect(info.stateAt(due.add(const Duration(hours: 23))), FollowUpState.due);
      expect(info.stateAt(due.add(const Duration(hours: 24))), FollowUpState.overdue);
    });

    test('no due time → none; legacy docs are not tracked', () {
      expect(FollowUpInfo.fromData(tracked()).stateAt(now), FollowUpState.none);
      expect(FollowUpInfo.fromData({'statusValue': 'in_talks'}).tracked, isFalse);
    });

    test('past-event and callback flags', () {
      expect(FollowUpInfo.fromData(tracked(reason: 'past_event')).isPastEvent, isTrue);
      expect(FollowUpInfo.fromData({'pastEventReviewAt': Timestamp.now()}).isPastEvent, isTrue);
      expect(FollowUpInfo.fromData(tracked(reason: 'callback')).isCallback, isTrue);
    });
  });

  group('followUpDueLabel', () {
    test('relative labels', () {
      String label(DateTime due) =>
          followUpDueLabel(FollowUpInfo.fromData(tracked(dueAt: due)), now);
      expect(label(DateTime(2026, 11, 8, 10)), 'Due tomorrow');
      expect(label(DateTime(2026, 11, 10, 10)), 'Due in 3 days');
      expect(label(DateTime(2026, 11, 7, 15)), 'Due in 3 hours');
      expect(label(DateTime(2026, 11, 7, 11)), 'Due now');
      expect(label(DateTime(2026, 11, 4, 10)), 'Overdue by 3 days');
    });
  });

  group('Follow Up tab (shouldShowReminder)', () {
    test('tracked enquiries show only while the follow-up is due or overdue', () {
      expect(shouldShowReminder(tracked(dueAt: DateTime(2026, 11, 7, 10)), now), isTrue);
      expect(shouldShowReminder(tracked(dueAt: DateTime(2026, 11, 1, 10)), now), isTrue);
      expect(shouldShowReminder(tracked(dueAt: DateTime(2026, 11, 9, 10)), now), isFalse);
      // Completed: no open follow-up until the next one is due.
      expect(shouldShowReminder(tracked(), now), isFalse);
    });

    test('New enquiries are included; booked / terminal ones never', () {
      final due = DateTime(2026, 11, 7, 10);
      expect(shouldShowReminder(tracked(status: 'new', dueAt: due), now), isTrue);
      for (final status in [
        'approved',
        'completed',
        'not_interested',
        'closed_lost',
        'cancelled',
      ]) {
        expect(
          shouldShowReminder(tracked(status: status, dueAt: due), now),
          isFalse,
          reason: status,
        );
      }
    });

    test('a past event date does not hide a due follow-up (needs review)', () {
      final data = {
        ...tracked(dueAt: DateTime(2026, 11, 6, 10), reason: 'past_event'),
        'eventDate': Timestamp.fromDate(DateTime(2026, 11, 1)),
      };
      expect(shouldShowReminder(data, now), isTrue);
    });

    test('legacy docs keep the old rule', () {
      final legacy = {
        'statusValue': 'in_talks',
        'eventDate': Timestamp.fromDate(DateTime(2026, 11, 20)),
      };
      expect(shouldShowReminder(legacy, now), isTrue);
      expect(shouldShowReminder({...legacy, 'lastReminderSentAt': Timestamp.now()}, now), isFalse);
    });
  });

  group('FollowUpService field sets (must match firestore.rules)', () {
    test('completion clears the due time and the sent stage, attributed to the user', () {
      final f = FollowUpService.completionFields('staff1');
      expect(f['followUpDueAt'], isNull);
      expect(f['followUpNotifiedStage'], isNull);
      expect(f['followUpLastCompletedBy'], 'staff1');
      expect(f['followUpSeq'], isA<FieldValue>());
      expect(f['followUpLastCompletedAt'], isA<FieldValue>());
    });

    test('reschedule sets a callback by the user and caps the note', () {
      final f = FollowUpService.rescheduleFields(
        userId: 'staff1',
        dueAt: DateTime(2026, 11, 9, 18, 30),
        note: '  ${'x' * 400}  ',
      );
      expect(f['followUpReason'], 'callback');
      expect(f['followUpScheduledBy'], 'staff1');
      expect(f['followUpNotifiedStage'], isNull);
      expect((f['followUpNote'] as String).length, FollowUpService.maxNoteLength);
      expect((f['followUpDueAt'] as Timestamp).toDate(), DateTime(2026, 11, 9, 18, 30));
      expect(f.containsKey('followUpLastCompletedAt'), isFalse);
    });

    test('blank notes are stored as null', () {
      expect(FollowUpService.cleanNote('   '), isNull);
      expect(FollowUpService.cleanNote(null), isNull);
    });
  });
}
