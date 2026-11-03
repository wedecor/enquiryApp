import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_reminder.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/reengagement_config.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/reengagement_templates.dart';

void main() {
  // 12 Dec 2026, 00:00 IST.
  final dec12 = IstDate.startOfDay(2026, 12, 12);

  String render(OccasionKind kind, {int nth = 1, String? person, String event = 'Wedding'}) {
    return ReengagementTemplates.render(
      ReengagementTemplates.defaults[kind]!,
      customerName: 'Ayesha Khan',
      nth: nth,
      date: dec12,
      person: person,
      eventType: event,
      business: 'We Decor Events',
    );
  }

  group('ReengagementTemplates.render', () {
    test('wedding anniversary uses first name, ordinal and IST date', () {
      expect(
        render(OccasionKind.weddingAnniversary, nth: 2),
        'Hi Ayesha, your 2nd wedding anniversary is on 12 December. Wishing you both many more '
        'happy years together. Warm wishes from We Decor Events.',
      );
    });

    test('birthday with a person', () {
      expect(
        render(OccasionKind.birthday, person: 'Aarav'),
        startsWith("Hi Ayesha, Aarav's birthday is coming up on 12 December."),
      );
    });

    test('birthday without a person reads "A birthday"', () {
      final text = render(OccasionKind.birthday);
      expect(text, startsWith('Hi Ayesha, a birthday is coming up on 12 December.'));
      expect(text, isNot(contains('{person}')));
    });

    test('wishes never sell and never use emoji', () {
      for (final kind in OccasionKind.values) {
        final text = render(kind, person: 'Aarav');
        expect(text.toLowerCase(), isNot(contains('decorat')), reason: kind.value);
        expect(text.toLowerCase(), isNot(contains('planning')), reason: kind.value);
        expect(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true).hasMatch(text),
          isFalse,
          reason: kind.value,
        );
      }
    });

    test('mid-sentence possessive becomes lower-case article', () {
      final text = ReengagementTemplates.render(
        "We loved {person}'s party.",
        customerName: 'A',
        nth: 1,
      );
      expect(text, 'We loved a party.');
    });

    test('other standalone {person} falls back to "your loved one"', () {
      final text = ReengagementTemplates.render('Wishing {person} well', customerName: 'A', nth: 1);
      expect(text, 'Wishing your loved one well');
    });

    test('event type is lower-cased; business falls back to We Decor Events', () {
      final text = ReengagementTemplates.render(
        ReengagementTemplates.defaults[OccasionKind.celebration]!,
        customerName: '',
        nth: 1,
        date: dec12,
        eventType: 'Diwali Party',
        business: ' ',
      );
      expect(text, startsWith('Hi there, thinking of you as 12 December comes round again.'));
      expect(text, endsWith('Warm wishes from We Decor Events.'));
    });

    test('nth below 1 is rendered as 1st', () {
      expect(render(OccasionKind.home, nth: 0), contains('happy 1st anniversary of your home'));
    });

    test('every default fills all placeholders', () {
      for (final kind in OccasionKind.values) {
        final text = render(kind, person: 'Aarav');
        expect(text, isNot(contains('{')), reason: kind.value);
        expect(text, endsWith('We Decor Events.'), reason: kind.value);
      }
    });
  });

  group('ReengagementConfig', () {
    test('defaults when the doc is missing', () {
      final config = ReengagementConfig.fromMap(null);
      expect(config.enabled, isTrue);
      expect(config.leadDays, 7);
      expect(
        config.templateFor(OccasionKind.birthday),
        ReengagementTemplates.defaults[OccasionKind.birthday],
      );
    });

    test('reads custom templates, ignores blanks and invalid lead days', () {
      final config = ReengagementConfig.fromMap({
        'enabled': false,
        'leadDays': 500,
        'templates': {'birthday': 'Custom {name}', 'home': '  ', 'nope': 'x'},
      });
      expect(config.enabled, isFalse);
      expect(config.leadDays, 7);
      expect(config.templateFor(OccasionKind.birthday), 'Custom {name}');
      expect(
        config.templateFor(OccasionKind.home),
        ReengagementTemplates.defaults[OccasionKind.home],
      );
      expect(config.toMap()['templates'], {'birthday': 'Custom {name}'});
    });

    test('window covers at least 30 days', () {
      expect(const ReengagementConfig(leadDays: 10).windowDays, 30);
      expect(const ReengagementConfig(leadDays: 45).windowDays, 45);
    });
  });
}
