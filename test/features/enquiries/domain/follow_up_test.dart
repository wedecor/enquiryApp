import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/widgets/dashboard_enquiry_utils.dart';
import 'package:we_decor_enquiries/features/enquiries/data/follow_up_service.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/follow_up.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12);

  Map<String, dynamic> inTalks({
    required DateTime eventDate,
    String status = 'in_talks',
    List<Map<String, dynamic>>? functions,
  }) => {
    'statusValue': status,
    'eventDate': Timestamp.fromDate(eventDate),
    if (functions != null) 'functions': functions,
  };

  group('kFollowUpLeadDays', () {
    test('matches the TypeScript FOLLOW_UP_LEAD_DAYS constant (10)', () {
      expect(kFollowUpLeadDays, 10);
    });
  });

  group('FollowUpInfo.stateAt', () {
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
  });

  group('Follow Up tab (shouldShowReminder) — exactly +10 days', () {
    test('In Talks at exactly +10 days → true', () {
      expect(shouldShowReminder(inTalks(eventDate: DateTime(2026, 11, 17)), now), isTrue);
    });

    test('+9 and +11 → false', () {
      expect(shouldShowReminder(inTalks(eventDate: DateTime(2026, 11, 16)), now), isFalse);
      expect(shouldShowReminder(inTalks(eventDate: DateTime(2026, 11, 18)), now), isFalse);
    });

    test('past event → false', () {
      expect(shouldShowReminder(inTalks(eventDate: DateTime(2026, 11, 1)), now), isFalse);
    });

    test('New / Approved / lost → false even at +10', () {
      final day = DateTime(2026, 11, 17);
      for (final status in [
        'new',
        'approved',
        'completed',
        'not_interested',
        'closed_lost',
        'cancelled',
      ]) {
        expect(
          shouldShowReminder(inTalks(eventDate: day, status: status), now),
          isFalse,
          reason: status,
        );
      }
    });

    test('multi-function uses the first upcoming function', () {
      final data = inTalks(
        eventDate: DateTime(2026, 11, 30), // last function
        functions: [
          {
            'id': 'a',
            'eventType': 'haldi',
            'eventTypeLabel': 'Haldi',
            'date': Timestamp.fromDate(DateTime(2026, 11, 17)),
          },
          {
            'id': 'b',
            'eventType': 'wedding',
            'eventTypeLabel': 'Wedding',
            'date': Timestamp.fromDate(DateTime(2026, 11, 30)),
          },
        ],
      );
      expect(shouldShowReminder(data, now), isTrue);
      final nine = inTalks(
        eventDate: DateTime(2026, 11, 30),
        functions: [
          {'id': 'a', 'eventType': 'haldi', 'date': Timestamp.fromDate(DateTime(2026, 11, 16))},
          {'id': 'b', 'eventType': 'wedding', 'date': Timestamp.fromDate(DateTime(2026, 11, 30))},
        ],
      );
      expect(shouldShowReminder(nine, now), isFalse);
    });

    test('legacy In Talks aliases count', () {
      final day = DateTime(2026, 11, 17);
      for (final status in ['quote_sent', 'contacted', 'quoted', 'in_progress']) {
        expect(
          shouldShowReminder(inTalks(eventDate: day, status: status), now),
          isTrue,
          reason: status,
        );
      }
    });

    test('contacted today does not remove from the list', () {
      final data = {
        ...inTalks(eventDate: DateTime(2026, 11, 17)),
        'lastContactAt': Timestamp.fromDate(now),
        'lastReminderSentAt': Timestamp.fromDate(now),
      };
      expect(shouldShowReminder(data, now), isTrue);
      expect(isFollowUpContactedToday(data, now), isTrue);
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
