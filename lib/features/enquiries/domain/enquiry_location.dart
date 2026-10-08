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

/// `eventLocation` text for a picked venue: "{mainText}, {area}" when the area is
/// known and not already part of the name, else just the venue name.
String pickedLocationText(String mainText, String? area) {
  final name = mainText.trim();
  final a = area?.trim() ?? '';
  if (a.isEmpty || name.isEmpty) return name;
  if (name.toLowerCase().contains(a.toLowerCase())) return name;
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
