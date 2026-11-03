import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/widgets/calendar_event.dart';

void main() {
  Map<String, Object> fn(String id, String type, DateTime date, {String? location}) => {
    'id': id,
    'eventType': type,
    'eventTypeLabel': type[0].toUpperCase() + type.substring(1),
    'date': Timestamp.fromDate(date),
    if (location != null) 'location': location,
  };

  final booking = <String, dynamic>{
    'customerName': 'Ayesha',
    'statusValue': 'approved',
    'eventTypeValue': 'wedding',
    'eventTypeLabel': 'Wedding',
    'eventDate': Timestamp.fromDate(DateTime(2026, 12, 13)),
    'eventLocation': 'Palace Grounds',
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
    'functions': [
      fn('h', 'haldi', DateTime(2026, 12, 10), location: 'JP Nagar'),
      fn('m', 'mehendi', DateTime(2026, 12, 11)),
      fn('w', 'wedding', DateTime(2026, 12, 12), location: 'Palace Grounds'),
      fn('r', 'reception', DateTime(2026, 12, 13)),
    ],
  };

  List<CalendarEvent> expand(
    Map<String, dynamic> data, {
    DateTime? start,
    DateTime? end,
    DateTime? now,
  }) => calendarEventsForEnquiry(
    enquiryId: 'e1',
    data: data,
    windowStart: start ?? DateTime(2026, 6),
    windowEnd: end ?? DateTime(2027, 6),
    now: now ?? DateTime(2026, 10, 9),
  );

  test('one entry per function on its own day, labelled n of N', () {
    final events = expand(booking);
    expect(events.map((e) => e.eventDate), [
      DateTime(2026, 12, 10),
      DateTime(2026, 12, 11),
      DateTime(2026, 12, 12),
      DateTime(2026, 12, 13),
    ]);
    expect(events.first.eventType, 'Haldi (1/4)');
    expect(events.first.title, 'Ayesha · Haldi (1/4)');
    expect(events.first.eventLocation, 'JP Nagar');
    expect(events.last.eventType, 'Reception (4/4)');
    expect(events.every((e) => e.status == 'approved' && e.enquiryId == 'e1'), isTrue);
    expect(events.map((e) => e.functionCount).toSet(), {4});
  });

  test('only functions inside the window are returned', () {
    final events = expand(booking, start: DateTime(2026, 12, 12), end: DateTime(2027, 1));
    expect(events.map((e) => e.eventType), ['Wedding (3/4)', 'Reception (4/4)']);
    // The query reaches past the window (eventDate = last function); filtering is by day.
    expect(expand(booking, start: DateTime(2026, 6), end: DateTime(2026, 12, 11)).length, 1);
  });

  test('legacy single event: one entry with the stored label and instant', () {
    final events = expand({
      'customerName': 'Ravi',
      'statusValue': 'confirmed', // legacy alias → approved
      'eventTypeValue': 'birthday',
      'eventDate': Timestamp.fromDate(DateTime(2026, 11, 2, 10, 30)),
      'eventLocation': 'HSR',
    });
    expect(events, hasLength(1));
    expect(events.single.eventType, 'birthday');
    expect(events.single.status, 'approved');
    expect(events.single.eventDate, DateTime(2026, 11, 2, 10, 30));
    expect(events.single.eventLocation, 'HSR');
  });

  test('lost bookings and old completed functions are skipped', () {
    expect(expand({...booking, 'statusValue': 'cancelled'}), isEmpty);
    final completed = expand({...booking, 'statusValue': 'completed'}, now: DateTime(2027, 1, 11));
    // 10 & 11 Dec are more than 30 days before 11 Jan.
    expect(completed.map((e) => e.eventType), ['Wedding (3/4)', 'Reception (4/4)']);
  });
}
