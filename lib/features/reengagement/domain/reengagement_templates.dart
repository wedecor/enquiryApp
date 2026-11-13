import 'occasion_kind.dart';
import 'occasion_reminder.dart';

/// WhatsApp message templates for yearly re-engagement reminders.
///
/// Placeholders: `{name}` (customer's first name), `{person}` (whose occasion,
/// may be empty), `{nth}` (1st/2nd…), `{date}` ("12 December"), `{event}` (last
/// year's event type) and `{business}` (company name).
///
/// When `{person}` is empty, "{person}'s birthday" becomes "A birthday" (or
/// "a birthday" mid-sentence) and any other `{person}` becomes "your loved one".
class ReengagementTemplates {
  ReengagementTemplates._();

  static const String fallbackBusiness = 'We Decor Events';

  static const List<String> placeholders = [
    '{name}',
    '{person}',
    '{nth}',
    '{date}',
    '{event}',
    '{business}',
  ];

  /// Past customers (we decorated their event): a wish, a warm line about being
  /// part of it, and one soft open door. No prices, offers or emoji. Never says
  /// "last year" (the event may be years back) and never names the day: wishes go
  /// out about 10 days early, and the stored date may be a haldi or a weekend party.
  static const Map<OccasionKind, String> defaults = {
    OccasionKind.weddingAnniversary:
        'Hi {name}, your {nth} wedding anniversary is just around the corner. It feels like '
        'only yesterday we were part of your big day. Wishing you both a wonderful '
        'celebration and many happy years ahead. If we can help make the day special in any '
        "way, we're just a message away. Warm wishes from {business}.",
    OccasionKind.birthday:
        "Hi {name}, {person}'s birthday is just around the corner. It was a joy being part of "
        'the celebration last time. Wishing {person} a wonderful day and a happy year ahead. '
        "If we can help make it special in any way, we're just a message away. Warm wishes "
        'from {business}.',
    OccasionKind.anniversary:
        'Hi {name}, your anniversary is just around the corner. It was a joy being part of '
        'your celebration. Wishing you a wonderful day and many happy years ahead. If we can '
        "help make it special in any way, we're just a message away. Warm wishes from "
        '{business}.',
    OccasionKind.baby:
        'Hi {name}, thinking of you and the little one as this special time comes round again. '
        'It was a joy being part of that day. Wishing your family good health and happy days '
        "ahead. If we can help make the next celebration special in any way, we're just a "
        'message away. Warm wishes from {business}.',
    OccasionKind.home:
        'Hi {name}, the {nth} anniversary of your home is just around the corner. It was a joy '
        'being part of your housewarming. Wishing you many more happy years there. If we can '
        "help make a get-together special in any way, we're just a message away. Warm wishes "
        'from {business}.',
    OccasionKind.corporate: 'Hi {name}, warm wishes from all of us at {business}.',
    OccasionKind.celebration:
        'Hi {name}, thinking of you as this time of year comes round again. It was a joy being '
        'part of your {event}. Wishing you a happy year ahead. If we can help make your next '
        "celebration special in any way, we're just a message away. Warm wishes from "
        '{business}.',
  };

  /// People who only enquired (lost or open-past — not completed): warm reach-out
  /// without saying the event happened or naming an anniversary number.
  static const Map<OccasionKind, String> enquiredDefaults = {
    OccasionKind.weddingAnniversary:
        "Hi {name}, hope you're doing well. It's been a while since you got in touch with us "
        'about your wedding. Wishing you both happiness and a wonderful year ahead. If we can '
        "ever help make a day special, we're just a message away. Warm wishes from {business}.",
    OccasionKind.birthday:
        "Hi {name}, hope you're doing well. It's been a while since you got in touch with us "
        "about {person}'s birthday. Wishing {person} a happy and healthy year ahead. If we can "
        "ever help make a day special, we're just a message away. Warm wishes from {business}.",
    OccasionKind.anniversary:
        "Hi {name}, hope you're doing well. It's been a while since you got in touch with us "
        'about your anniversary celebration. Wishing you many happy years ahead. If we can '
        "ever help make a day special, we're just a message away. Warm wishes from {business}.",
    OccasionKind.baby:
        "Hi {name}, hope you're doing well. It's been a while since you got in touch with us "
        'about your celebration for the little one. Wishing your family good health and happy '
        "days ahead. If we can ever help make a day special, we're just a message away. Warm "
        'wishes from {business}.',
    OccasionKind.home:
        "Hi {name}, hope you're doing well. It's been a while since you got in touch with us "
        'about your housewarming. Wishing you many happy years in your home. If we can ever '
        "help make a day special, we're just a message away. Warm wishes from {business}.",
    OccasionKind.corporate: 'Hi {name}, warm wishes from all of us at {business}.',
    OccasionKind.celebration:
        "Hi {name}, hope you're doing well. It's been a while since you got in touch with us "
        'about your {event}. Wishing you a happy year ahead. If we can ever help make a day '
        "special, we're just a message away. Warm wishes from {business}.",
  };

  /// Default for [kind] for a past customer, or for someone who only [enquired].
  static String defaultFor(OccasionKind kind, {bool enquired = false}) =>
      (enquired ? enquiredDefaults : defaults)[kind] ?? '';

  /// First word of a customer name ("Ayesha Khan" → "Ayesha"); "there" when blank.
  static String firstName(String? fullName) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static final RegExp _possessivePerson = RegExp(r"\{person\}['’]s\s+(\S)");
  static final RegExp _sentenceStart = RegExp(r'(^|[.!?…]\s*|\n\s*)$');

  /// Fills [template]. Pure: no locale, clock or Firebase access.
  static String render(
    String template, {
    required String customerName,
    required int nth,
    DateTime? date,
    String? person,
    String eventType = '',
    String? business,
  }) {
    final who = person?.trim() ?? '';
    final businessName = (business == null || business.trim().isEmpty)
        ? fallbackBusiness
        : business.trim();
    final event = eventType.trim().isEmpty ? 'event' : eventType.trim().toLowerCase();

    var out = template;
    if (who.isEmpty) {
      out = out.replaceAllMapped(_possessivePerson, (m) {
        final next = m.group(1)!;
        final article = 'aeiouAEIOU'.contains(next[0]) ? 'an' : 'a';
        final atStart = _sentenceStart.hasMatch(m.input.substring(0, m.start));
        final word = atStart ? '${article[0].toUpperCase()}${article.substring(1)}' : article;
        return '$word $next';
      });
      out = out.replaceAll('{person}', 'your loved one');
    } else {
      out = out.replaceAll('{person}', who);
    }

    return out
        .replaceAll('{name}', firstName(customerName))
        .replaceAll('{nth}', OccasionKind.ordinal(nth < 1 ? 1 : nth))
        .replaceAll('{date}', date == null ? 'soon' : IstDate.long(date))
        .replaceAll('{event}', event)
        .replaceAll('{business}', businessName)
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }
}
