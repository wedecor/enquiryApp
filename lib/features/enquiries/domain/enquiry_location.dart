/// Google Maps place attached to an enquiry's Location (picked from the venue
/// search). `eventLocation` stays the human-readable text used everywhere else;
/// these fields are optional extras and are absent for free-text locations.
class EnquiryPlace {
  const EnquiryPlace({
    required this.placeId,
    this.address,
    this.lat,
    this.lng,
    this.area,
    this.city,
  });

  static const String placeIdField = 'locationPlaceId';
  static const String addressField = 'locationAddress';
  static const String latField = 'locationLat';
  static const String lngField = 'locationLng';
  static const String areaField = 'locationArea';
  static const String cityField = 'locationCity';

  /// Every Firestore field owned by the place (cleared together).
  static const List<String> fieldKeys = [
    placeIdField,
    addressField,
    latField,
    lngField,
    areaField,
    cityField,
  ];

  final String placeId;

  /// Google's formatted address, e.g. "Jayamahal Main Rd, Vasanth Nagar, Bengaluru…".
  final String? address;
  final double? lat;
  final double? lng;

  /// Neighbourhood / sublocality, e.g. "Indiranagar".
  final String? area;
  final String? city;

  /// The stored place on an enquiry document, or null when none is attached.
  static EnquiryPlace? fromData(Map<String, dynamic> data) {
    final placeId = _text(data[placeIdField]);
    if (placeId == null) return null;
    return EnquiryPlace(
      placeId: placeId,
      address: _text(data[addressField]),
      lat: _number(data[latField]),
      lng: _number(data[lngField]),
      area: _text(data[areaField]),
      city: _text(data[cityField]),
    );
  }

  /// Non-null fields to write (used on create).
  Map<String, Object> toFields() => {
    placeIdField: placeId,
    if (address != null) addressField: address!,
    if (lat != null) latField: lat!,
    if (lng != null) lngField: lng!,
    if (area != null) areaField: area!,
    if (city != null) cityField: city!,
  };
}

String? _text(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _number(Object? raw) {
  if (raw is! num) return null;
  final value = raw.toDouble();
  return value.isFinite ? value : null;
}

/// Lower-cased [text] with every run of spaces / punctuation / symbols collapsed
/// to one space, e.g. " Bangalore,  Karnataka. " → "bangalore karnataka".
String _normalizedLocation(String text) =>
    text.toLowerCase().replaceAll(_locationSeparators, ' ').trim();

String _compactLocation(String text) => text.toLowerCase().replaceAll(_locationSeparators, '');

/// Whitespace, separators, punctuation and symbols. Mirrored in firestore.rules
/// (`vagueLocationRegex`) — keep both in sync.
final RegExp _locationSeparators = RegExp(r'[\s\p{Z}\p{P}\p{S}]+', unicode: true);

/// Names that only say "Bangalore" — not where the event actually is. Mirrored in
/// firestore.rules (`vagueLocationRegex`) — keep both in sync.
const List<String> vagueLocationNames = [
  'bangalore',
  'bengaluru',
  'banglore',
  'bangaluru',
  'blr',
  'bangalore city',
  'bengaluru city',
  'bangalore urban',
  'bengaluru urban',
  'karnataka',
  'india',
  'bangalore karnataka',
  'bengaluru karnataka',
];

/// True when [text] doesn't tell us where in the city the event is: empty, only
/// punctuation, or just the city / state / country name ("Bangalore", "BLR.",
/// "Bengaluru, Karnataka").
bool isVagueLocation(String? text) {
  final normalized = _normalizedLocation(text ?? '');
  return normalized.isEmpty || vagueLocationNames.contains(normalized);
}

/// The approval rule (mirrored in firestore.rules): the location is known when an
/// area is stored (from a Maps pick, or typed in the approve sheet) or the
/// location text is more specific than the city name.
bool isLocationKnown({String? area, String? eventLocation}) =>
    !isVagueLocation(area) || !isVagueLocation(eventLocation);

/// [isLocationKnown] for a raw enquiry document.
bool isLocationKnownInData(Map<String, dynamic> data) {
  final area = data[EnquiryPlace.areaField];
  final location = data['eventLocation'] ?? data['location'];
  return isLocationKnown(
    area: area is String ? area : null,
    eventLocation: location is String ? location : null,
  );
}

/// Whether an enquiry in [statusIsApproved] state should show "Location pending".
bool isApprovedLocationPending({
  required bool statusIsApproved,
  required Map<String, dynamic> data,
}) => statusIsApproved && !isLocationKnownInData(data);

/// Approve in the Confirm booking sheet: enabled once the typed text
/// (or the place attached to it) passes [isLocationKnown].
bool canSaveApprovalLocation({required String text, EnquiryPlace? place}) =>
    isLocationKnown(area: place?.area, eventLocation: text);

/// Location fields the Confirm booking sheet writes together with the approval.
///
/// With a picked [place]: the text plus every place field it has. Typed only: the
/// text, and the same text as `locationArea` so area analytics still groups it.
/// Place keys absent from the result should be cleared by the caller.
Map<String, Object> approvalLocationFields({required String text, EnquiryPlace? place}) {
  final location = text.trim();
  if (place != null) return {'eventLocation': location, ...place.toFields()};
  return {'eventLocation': location, EnquiryPlace.areaField: location};
}

/// `eventLocation` text for a picked place.
///
/// An area pick ([isArea], e.g. "JP Nagar") is just its name. A venue is
/// "{mainText}, {area}" when the area is known and not already part of the name,
/// else just the venue name.
String pickedLocationText(String mainText, String? area, {bool isArea = false}) {
  final name = mainText.trim();
  final a = area?.trim() ?? '';
  if (isArea) return name.isNotEmpty ? name : a;
  if (a.isEmpty || name.isEmpty) return name;
  // Compare without spaces / punctuation so "J. P. Nagar" matches "JP Nagar".
  if (_compactLocation(name).contains(_compactLocation(a))) return name;
  return '$name, $a';
}

/// Google Maps search link for an enquiry's location (free — no API key).
///
/// With a place id the link opens that exact place; otherwise it searches the
/// typed location text. Null when there is nothing to search for.
Uri? mapsSearchUri({String? eventLocation, String? address, String? placeId}) {
  final location = eventLocation?.trim() ?? '';
  final query = location.isNotEmpty ? location : (address?.trim() ?? '');
  if (query.isEmpty) return null;
  final id = placeId?.trim() ?? '';
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
    if (id.isNotEmpty) 'query_place_id': id,
  });
}
