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

  /// Warm, short, never pushy.
  static const Map<OccasionKind, String> defaults = {
    OccasionKind.weddingAnniversary:
        'Hi {name}! Your {nth} wedding anniversary is coming up on {date} 💐 We loved being '
        "part of your celebrations. Planning something special? We'd love to decorate it. "
        '– {business}',
    OccasionKind.birthday:
        "Hi {name}! {person}'s birthday is coming up on {date} 🎉 We loved decorating last "
        "year's celebration. Planning something this year? – {business}",
    OccasionKind.anniversary:
        "Hi {name}! {person}'s anniversary is coming up on {date} 💐 It was lovely decorating "
        "last year's celebration. If you're planning something this year, we'd be happy to "
        'help. – {business}',
    OccasionKind.baby:
        "Hi {name}! It's been almost a year since we celebrated your little one's special day "
        "🍼 Hope everyone is doing wonderfully. If you're planning a celebration around "
        "{date}, we'd love to make it beautiful. – {business}",
    OccasionKind.home:
        "Hi {name}! Your home's {nth} anniversary is on {date} 🏡 Hope it's full of happy "
        "memories. Planning a get-together this year? We'd love to help. – {business}",
    OccasionKind.corporate:
        "Hi {name}! It's almost a year since we decorated your {event} ✨ If you're planning "
        "this year's edition around {date}, we'd love to be part of it again. – {business}",
    OccasionKind.celebration:
        'Hi {name}! Same time last year we decorated your {event} ✨ Planning something '
        "around {date} this year? We'd love to make it special again. – {business}",
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
