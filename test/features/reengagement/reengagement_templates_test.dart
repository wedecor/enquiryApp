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
        'Hi Ayesha, your 2nd wedding anniversary is coming up soon. Wishing you both many '
        'more happy years together. It was lovely being part of your wedding. If you\'re '
        "planning something to celebrate, we'd love to be part of it again. Warm wishes from "
        'We Decor Events.',
      );
    });

    test('birthday with a person', () {
      expect(
        render(OccasionKind.birthday, person: 'Aarav'),
        startsWith("Hi Ayesha, Aarav's birthday is coming up soon."),
      );
    });

    test('birthday without a person reads "A birthday"', () {
      final text = render(OccasionKind.birthday);
      expect(text, startsWith('Hi Ayesha, a birthday is coming up soon.'));
      expect(text, isNot(contains('{person}')));
    });

    test('wishes stay soft: no prices, offers, "book" or emoji', () {
      for (final enquired in [false, true]) {
        for (final kind in OccasionKind.values) {
          final text = ReengagementTemplates.render(
            ReengagementTemplates.defaultFor(kind, enquired: enquired),
            customerName: 'Ayesha Khan',
            nth: 1,
            date: dec12,
            person: 'Aarav',
            eventType: 'Wedding',
            business: 'We Decor Events',
          ).toLowerCase();
          for (final word in ['₹', 'discount', 'offer', 'book', 'price', 'decorat']) {
            expect(text, isNot(contains(word)), reason: '${kind.value} enquired=$enquired');
          }
          expect(
            RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true).hasMatch(text),
            isFalse,
            reason: kind.value,
          );
        }
      }
    });

    test('default messages never name the day (dates can be a haldi or a weekend party)', () {
      for (final enquired in [false, true]) {
        for (final kind in OccasionKind.values) {
          expect(
            ReengagementTemplates.defaultFor(kind, enquired: enquired),
            isNot(contains('{date}')),
            reason: '${kind.value} enquired=$enquired',
          );
        }
      }
    });

    test('enquired-only messages never mention working together', () {
      for (final kind in OccasionKind.values) {
        final text = ReengagementTemplates.defaultFor(kind, enquired: true).toLowerCase();
        expect(text, isNot(contains('part of')), reason: kind.value);
        expect(text, isNot(contains('part of it again')), reason: kind.value);
      }
    });

    test('past-customer messages remember the event; enquired ones leave the door open', () {
      expect(
        ReengagementTemplates.defaultFor(OccasionKind.birthday),
        contains('It was lovely being part of your celebration'),
      );
      expect(
        ReengagementTemplates.defaultFor(OccasionKind.birthday, enquired: true),
        contains("we're just a message away"),
      );
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
      expect(text, startsWith('Hi there, thinking of you as this time of year comes round again.'));
      expect(text, contains('your diwali party'));
      expect(text, endsWith('Warm wishes from We Decor Events.'));
    });

    test('nth below 1 is rendered as 1st', () {
      expect(
        render(OccasionKind.home, nth: 0),
        contains('the 1st anniversary of your home is coming up soon'),
      );
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

    test('enquired templates are separate from past-customer ones', () {
      final config = ReengagementConfig.fromMap({
        'templates': {'birthday': 'Past {name}'},
        'templatesEnquired': {'birthday': 'Enquired {name}'},
      });
      expect(config.templateFor(OccasionKind.birthday), 'Past {name}');
      expect(config.templateFor(OccasionKind.birthday, enquired: true), 'Enquired {name}');
      expect(
        config.templateFor(OccasionKind.home, enquired: true),
        ReengagementTemplates.enquiredDefaults[OccasionKind.home],
      );
      expect(config.toMap()['templatesEnquired'], {'birthday': 'Enquired {name}'});
    });

    test('the list window follows lead days', () {
      expect(const ReengagementConfig(leadDays: 7).windowDays, 7);
      expect(const ReengagementConfig(leadDays: 45).windowDays, 45);
    });
  });
}
