// ignore_for_file: avoid_print
/// Test-only preview renderer: writes every customer-card variant to docs/cards/.
///
/// Run: `flutter test tool/render_customer_cards.dart`
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/presentation/customer_card.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const name = 'Priya Sharma';
  const person = 'Aarav';
  const event = 'Wedding';
  final date = DateTime(2026, 1, 15);
  final outDir = Directory('docs/cards');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  Future<void> write(String fileName, CustomerCardContent content) async {
    CustomerCardRenderer.clearBrandCache();
    final png = await CustomerCardRenderer.renderPng(content);
    final path = '${outDir.path}/$fileName';
    File(path).writeAsBytesSync(png);
    final shrink = CustomerCardRenderer.lastHeadlineSize;
    print(
      'wrote $path'
      '${shrink != null && shrink < 90 ? ' (headline shrunk to ${shrink.toStringAsFixed(0)}px)' : ''}',
    );
  }

  test('render all customer card previews to docs/cards', () async {
    await write(
      'brand.png',
      CustomerCardContent.brand(
        websiteUrl: 'https://www.wedecorevents.com/',
        instagramHandle: '@wedecorbangalore',
      ),
    );

    await write(
      'countdown_10.png',
      CustomerCardContent.countdown(
        customerName: name,
        eventTypeLabel: event,
        eventDate: date,
        now: DateTime(2026, 1, 5),
      )!,
    );
    await write(
      'countdown_tomorrow.png',
      CustomerCardContent.countdown(
        customerName: name,
        eventTypeLabel: event,
        eventDate: date,
        now: DateTime(2026, 1, 14),
      )!,
    );
    await write(
      'countdown_today.png',
      CustomerCardContent.countdown(
        customerName: name,
        eventTypeLabel: event,
        eventDate: date,
        now: DateTime(2026, 1, 15),
      )!,
    );

    await write(
      'thank_you.png',
      CustomerCardContent.thankYou(customerName: name, eventTypeLabel: event),
    );

    for (final kind in OccasionKind.values) {
      await write(
        'wish_past_${kind.value}.png',
        CustomerCardContent.forOccasion(
          kind: kind,
          customerName: name,
          nth: 10,
          enquired: false,
          person: kind == OccasionKind.birthday ? person : null,
        ),
      );
      await write(
        'wish_enquired_${kind.value}.png',
        CustomerCardContent.forOccasion(
          kind: kind,
          customerName: name,
          nth: 10,
          enquired: true,
          person: kind == OccasionKind.birthday ? person : null,
        ),
      );
    }

    // Birthday without person (past).
    await write(
      'wish_past_birthday_no_person.png',
      CustomerCardContent.forOccasion(
        kind: OccasionKind.birthday,
        customerName: name,
        nth: 1,
        enquired: false,
      ),
    );
  });
}
