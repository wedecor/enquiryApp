/// What a completed event becomes for yearly re-engagement reminders
/// ("same time next year"). Every completed event gets one.
///
/// The keyword table, matching rule and [OccasionKind.describe] MUST stay
/// identical to `OCCASION_KIND_KEYWORDS`, `occasionKindFor` and `occasionLabel`
/// in functions/src/reengagementLogic.ts (the server stamps `occasionKind`).
enum OccasionKind {
  weddingAnniversary('wedding_anniversary', 'Wedding anniversary'),
  birthday('birthday', 'Birthday'),
  anniversary('anniversary', 'Anniversary'),
  baby('baby', 'Little one'),
  home('home', 'Housewarming'),
  corporate('corporate', 'Corporate'),
  celebration('celebration', 'Celebration');

  const OccasionKind(this.value, this.label);

  /// Value stored in `enquiries.occasionKind` / `reminders.occasionKind`.
  final String value;

  /// Short human label (kind picker, admin template headings).
  final String label;

  static OccasionKind? fromValue(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    for (final kind in OccasionKind.values) {
      if (kind.value == v) return kind;
    }
    return null;
  }

  /// Checked in order against the compacted event type text; first match wins,
  /// no match → [celebration]. Corporate first so "Corporate cocktail" or
  /// "Office birthday" stay corporate.
  static const List<(OccasionKind, List<String>)> keywords = [
    (OccasionKind.corporate, ['corporate', 'office', 'launch', 'conference']),
    (
      OccasionKind.weddingAnniversary,
      [
        'wedding',
        'marriage',
        'reception',
        'haldi',
        'mehendi',
        'mehndi',
        'mehandi',
        'sangeet',
        'engagement',
        'bride',
        'bridal',
        'groom',
        'bachelor',
        'nikah',
        'nikkah',
        'walima',
        'roka',
        'cocktail',
        'muhurtham',
        'muhurtam',
        'muhurat',
        'shaadi',
      ],
    ),
    (OccasionKind.birthday, ['birthday', 'bday']),
    (OccasionKind.anniversary, ['anniversary']),
    (
      OccasionKind.baby,
      [
        'babyshower',
        'godhbharai',
        'godbharai',
        'seemantham',
        'seemantam',
        'valaikappu',
        'naming',
        'namkaran',
        'namakaran',
        'cradle',
      ],
    ),
    (
      OccasionKind.home,
      ['housewarming', 'grihapravesh', 'grihapravesam', 'gruhapravesh', 'gruhapravesam'],
    ),
  ];

  /// Lower-cased value + label with every non-alphanumeric character removed
  /// ("Bride-to-be" → "bridetobe").
  static String compactEventTypeText(String? value, [String? label]) {
    final parts = [value, label].whereType<String>();
    return parts.join(' ').toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '');
  }

  /// Kind for an event type (dropdown value and/or label, case-insensitive).
  static OccasionKind forEventType(String? value, [String? label]) {
    final text = compactEventTypeText(value, label);
    if (text.isEmpty) return OccasionKind.celebration;
    for (final (kind, words) in keywords) {
      if (words.any((w) => text.contains(w))) return kind;
    }
    return OccasionKind.celebration;
  }

  /// 1 → 1st, 2 → 2nd, 3 → 3rd, 11 → 11th, 21 → 21st, 112 → 112th.
  static String ordinal(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  /// "2nd wedding anniversary", "Aarav's birthday", "1 year since Baby Shower".
  String describe({required int nth, String? person, String eventTypeLabel = ''}) {
    final n = nth < 1 ? 1 : nth;
    final who = person?.trim() ?? '';
    final years = '$n year${n == 1 ? '' : 's'}';
    final event = eventTypeLabel.trim().isEmpty ? 'the event' : eventTypeLabel.trim();
    switch (this) {
      case OccasionKind.weddingAnniversary:
        return '${ordinal(n)} wedding anniversary';
      case OccasionKind.birthday:
        return who.isEmpty ? 'Birthday' : "$who's birthday";
      case OccasionKind.anniversary:
        return who.isEmpty ? 'Anniversary' : "$who's anniversary";
      case OccasionKind.home:
        return '${ordinal(n)} housewarming anniversary';
      case OccasionKind.baby:
      case OccasionKind.corporate:
      case OccasionKind.celebration:
        return '$years since $event';
    }
  }
}
