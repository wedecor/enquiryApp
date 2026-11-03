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

  /// Wishes only: no sales line, no emoji. Sent with the wish card, and to past
  /// customers and wish-eligible lost enquiries alike, so they never mention last
  /// year's decor. Corporate occasions get no yearly wish (the server skips them).
  static const Map<OccasionKind, String> defaults = {
    OccasionKind.weddingAnniversary:
        'Hi {name}, your {nth} wedding anniversary is on {date}. Wishing you both many more '
        'happy years together. Warm wishes from {business}.',
    OccasionKind.birthday:
        "Hi {name}, {person}'s birthday is coming up on {date}. Wishing {person} a happy year "
        'ahead, full of good moments. Warm wishes from all of us at {business}.',
    OccasionKind.anniversary:
        'Hi {name}, wishing you a very happy anniversary on {date}. May the year ahead be full '
        'of happiness. Warm wishes from {business}.',
    OccasionKind.baby:
        'Hi {name}, thinking of you and the little one as {date} comes round again. Hope '
        "you're all keeping well and happy. Warm wishes from {business}.",
    OccasionKind.home:
        'Hi {name}, happy {nth} anniversary of your home on {date}. Wishing you many more '
        'happy years there. Warm wishes from {business}.',
    OccasionKind.corporate: 'Hi {name}, warm wishes from all of us at {business}.',
    OccasionKind.celebration:
        "Hi {name}, thinking of you as {date} comes round again. Hope it's a lovely one. "
        'Warm wishes from {business}.',
  };

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
