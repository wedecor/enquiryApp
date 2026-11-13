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
  /// out a few days early, and the stored date may be a haldi or a weekend party.
  static const Map<OccasionKind, String> defaults = {
    OccasionKind.weddingAnniversary:
        'Hi {name}, your {nth} wedding anniversary is coming up soon. Wishing you both many '
        'more happy years together. It was lovely being part of your wedding. If you\'re '
        "planning something to celebrate, we'd love to be part of it again. Warm wishes from "
        '{business}.',
    OccasionKind.birthday:
        "Hi {name}, {person}'s birthday is coming up soon. Wishing {person} a happy year ahead. "
        "It was lovely being part of your celebration. If you're planning something this year, "
        "we'd love to be part of it again. Warm wishes from {business}.",
    OccasionKind.anniversary:
        'Hi {name}, your anniversary is coming up soon. Wishing you a very happy one. It was '
        "lovely being part of your celebration. If you're planning something this year, we'd "
        'love to be part of it again. Warm wishes from {business}.',
    OccasionKind.baby:
        'Hi {name}, thinking of you and the little one as this special time comes round again. '
        "It was lovely being part of that day. If you're planning a celebration, we'd love to "
        'be part of it again. Warm wishes from {business}.',
    OccasionKind.home:
        'Hi {name}, the {nth} anniversary of your home is coming up soon. It was lovely being '
        "part of your housewarming. If you're planning a get-together, we'd love to be part of "
        'it again. Warm wishes from {business}.',
    OccasionKind.corporate: 'Hi {name}, warm wishes from all of us at {business}.',
    OccasionKind.celebration:
        'Hi {name}, thinking of you as this time of year comes round again. It was lovely being '
        "part of your {event}. If you're planning something this year, we'd love to be part of "
        'it again. Warm wishes from {business}.',
  };

  /// People who only enquired (lost or open-past — not completed): a wish and
  /// one soft open door. Never mentions working together; never names the day.
  static const Map<OccasionKind, String> enquiredDefaults = {
    OccasionKind.weddingAnniversary:
        'Hi {name}, your {nth} wedding anniversary is coming up soon. Wishing you both many '
        "more happy years together. If you're planning something to celebrate, we're just a "
        'message away. Warm wishes from {business}.',
    OccasionKind.birthday:
        "Hi {name}, {person}'s birthday is coming up soon. Wishing {person} a happy year ahead, "
        "full of good moments. If you're planning something, we're just a message away. Warm "
        'wishes from {business}.',
    OccasionKind.anniversary:
        "Hi {name}, your anniversary is coming up soon. Wishing you a very happy one. If you're "
        "planning something, we're just a message away. Warm wishes from {business}.",
    OccasionKind.baby:
        'Hi {name}, thinking of you and the little one as this special time comes round again. '
        "Hope you're all keeping well. If you're planning a celebration, we're just a message "
        'away. Warm wishes from {business}.',
    OccasionKind.home:
        'Hi {name}, the {nth} anniversary of your home is coming up soon. Wishing you many more '
        "happy years there. If you're planning a get-together, we're just a message away. Warm "
        'wishes from {business}.',
    OccasionKind.corporate: 'Hi {name}, warm wishes from all of us at {business}.',
    OccasionKind.celebration:
        "Hi {name}, thinking of you as this time of year comes round again. Hope it's a lovely "
        "one. If you're planning something, we're just a message away. Warm wishes from "
        '{business}.',
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
