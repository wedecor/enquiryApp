import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:we_decor_enquiries/core/contacts/enquiry_whatsapp.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/widgets/dashboard_enquiry_utils.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/presentation/customer_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ordinals', () {
    test('1–20 are words; 21 uses digits', () {
      expect(CustomerCardContent.ordinalWord(1), 'First');
      expect(CustomerCardContent.ordinalWord(2), 'Second');
      expect(CustomerCardContent.ordinalWord(10), 'Tenth');
      expect(CustomerCardContent.ordinalWord(20), 'Twentieth');
      expect(CustomerCardContent.ordinalWord(21), '21st');
    });
  });

  group('countdown B', () {
    final event = DateTime(2026, 1, 15);
    const name = 'Priya Sharma';

    test('N=10 counting down', () {
      final c = CustomerCardContent.countdown(
        customerName: name,
        eventTypeLabel: 'Wedding',
        eventDate: event,
        now: DateTime(2026, 1, 5),
      )!;
      expect(c.eyebrow, 'COUNTING DOWN');
      expect(c.greeting, 'Dear Priya,');
      expect(c.headlineLines.first, 'Ten Days');
      expect(c.headlineLines.last, contains('Wedding'));
      expect(c.bodyLine, 'Thursday, 15 January 2026');
    });

    test('N=2, tomorrow, today', () {
      expect(
        CustomerCardContent.countdown(
          customerName: name,
          eventTypeLabel: 'Wedding',
          eventDate: event,
          now: DateTime(2026, 1, 13),
        )!.headlineLines.first,
        'Two Days',
      );
      final tomorrow = CustomerCardContent.countdown(
        customerName: name,
        eventTypeLabel: 'Wedding',
        eventDate: event,
        now: DateTime(2026, 1, 14),
      )!;
      expect(tomorrow.eyebrow, 'ALMOST TIME');
      expect(tomorrow.headlineLines, ['Tomorrow is', 'Your Wedding']);
      final today = CustomerCardContent.countdown(
        customerName: name,
        eventTypeLabel: 'Wedding',
        eventDate: event,
        now: DateTime(2026, 1, 15),
      )!;
      expect(today.eyebrow, 'THE DAY IS HERE');
      expect(today.headlineLines, ['Today is', 'Your Wedding']);
    });

    test('no usable date returns null; unknown event → Celebration', () {
      expect(
        CustomerCardContent.countdown(
          customerName: name,
          eventTypeLabel: 'Wedding',
          eventDate: null,
          now: DateTime(2026, 1, 5),
        ),
        isNull,
      );
      final c = CustomerCardContent.countdown(
        customerName: name,
        eventTypeLabel: null,
        eventDate: event,
        now: DateTime(2026, 1, 5),
      )!;
      expect(c.headlineLines, ['Ten Days', 'to Your Celebration']);
    });

    test('no name hides greeting', () {
      final c = CustomerCardContent.countdown(
        customerName: '  ',
        eventTypeLabel: 'Wedding',
        eventDate: event,
        now: DateTime(2026, 1, 5),
      )!;
      expect(c.greeting, isNull);
    });
  });

  group('tables D and E', () {
    test('past wedding / birthday person / home / corporate', () {
      expect(
        CustomerCardContent.forOccasion(
          kind: OccasionKind.weddingAnniversary,
          customerName: 'Priya',
          nth: 10,
          enquired: false,
        ).headlineLines.first,
        'Tenth Anniversary',
      );
      final bday = CustomerCardContent.forOccasion(
        kind: OccasionKind.birthday,
        customerName: 'Priya',
        nth: 1,
        enquired: false,
        person: 'Aarav',
      );
      expect(bday.greeting, 'Birthday Wishes');
      expect(bday.headlineLines, ['Aarav']);
      expect(bday.bodyLine, 'A wonderful year ahead.');
    });

    test('enquired never ordinal / Anniversary+number / it was a joy', () {
      for (final kind in OccasionKind.values) {
        final c = CustomerCardContent.forOccasion(
          kind: kind,
          customerName: 'Priya',
          nth: 10,
          enquired: true,
          person: 'Aarav',
        );
        final all = [c.eyebrow, c.greeting, ...c.headlineLines, c.bodyLine].join(' ');
        expect(all.toLowerCase(), isNot(contains('it was a joy')), reason: kind.value);
        expect(
          all,
          isNot(contains(RegExp(r'\b(First|Second|Tenth|10th|1st)\b'))),
          reason: kind.value,
        );
        expect(all, isNot(contains(RegExp(r'\d+\s*Anniversary'))), reason: kind.value);
      }
    });

    test('long name still produces content', () {
      final c = CustomerCardContent.thankYou(
        customerName: 'Priyadarshini Venkataramanan',
        eventTypeLabel: 'Wedding',
      );
      expect(c.greeting, startsWith('Dear Priyadarshini'));
      expect(c.headlineLines, ['Thank You']);
    });
  });

  group('card/message agreement', () {
    test('thank-you event word matches review-style body and message', () {
      const event = 'Wedding';
      final card = CustomerCardContent.thankYou(
        customerName: 'Priya Sharma',
        eventTypeLabel: event,
      );
      expect(card.bodyLine, contains('your wedding'));
      // Message builder lower-cases the same label.
      expect(event.toLowerCase(), 'wedding');
    });

    test('countdown body date matches reminder message date formatting', () {
      final event = DateTime(2026, 1, 15, 12);
      final now = DateTime(2026, 1, 5, 12);
      final card = CustomerCardContent.countdown(
        customerName: 'Priya Sharma',
        eventTypeLabel: 'Wedding',
        eventDate: event,
        now: now,
      )!;
      final msg = buildReminderMessage('Priya Sharma', 'Wedding', now, event, now: now);
      expect(card.bodyLine, DateFormat('EEEE, d MMMM yyyy').format(event));
      expect(msg.toLowerCase(), contains('wedding'));
      expect(msg, contains('Hi Priya'));
      expect(msg, contains('15 Jan 2026'));
      expect(card.headlineLines.first, 'Ten Days');
      // Same N the card spells out appears as digits in the message.
      expect(msg, contains('in ${eventDayOffset(event, now)} days'));
      expect(eventDayOffset(event, now), 10);
    });

    test('enquiry first-contact date bit matches card brand (no personal date)', () {
      final event = DateTime(2026, 1, 15);
      final msg = EnquiryWhatsApp.message(
        customerName: 'Priya Sharma',
        firstContact: true,
        eventTypeLabel: 'Wedding',
        eventDate: event,
      );
      expect(msg, contains('wedding enquiry for 15 Jan'));
      final card = EnquiryWhatsApp.cardFor(
        customerName: 'Priya Sharma',
        eventTypeLabel: 'Wedding',
        eventDate: event,
      );
      expect(card.layout, CustomerCardLayout.brand);
    });

    test('follow-up countdown card uses same event title case as message lowercases', () {
      final event = DateTime(2026, 1, 15);
      final card = EnquiryWhatsApp.cardFor(
        customerName: 'Priya Sharma',
        eventTypeLabel: 'Wedding',
        eventDate: event,
        countdown: true,
        now: DateTime(2026, 1, 5),
      );
      expect(card.layout, CustomerCardLayout.standard);
      expect(card.headlineLines.join(' '), contains('Wedding'));
      final msg = EnquiryWhatsApp.message(
        customerName: 'Priya Sharma',
        firstContact: false,
        eventTypeLabel: 'Wedding',
        eventDate: event,
      );
      expect(msg, contains('wedding enquiry'));
    });
  });

  group('renderer', () {
    test('returns 2160×2160 PNG with ivory pixel inside the frame', () async {
      CustomerCardRenderer.clearBrandCache();
      final png = await CustomerCardRenderer.renderPng(
        CustomerCardContent.thankYou(customerName: 'Priya', eventTypeLabel: 'Wedding'),
      );
      expect(png[0], 0x89);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
      final frame = await codec.getNextFrame();
      final image = frame.image;
      expect(image.width, 2160);
      expect(image.height, 2160);
      // Sample near centre (inside frame): expect ivory ground #FBF7EF.
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(bytes, isNotNull);
      final cx = 1080;
      final cy = 100; // top band under frame — ground fill
      final i = (cy * image.width + cx) * 4;
      final r = bytes!.getUint8(i);
      final g = bytes.getUint8(i + 1);
      final b = bytes.getUint8(i + 2);
      expect(r, closeTo(0xFB, 8));
      expect(g, closeTo(0xF7, 8));
      expect(b, closeTo(0xEF, 8));
      image.dispose();
    });
  });
}
