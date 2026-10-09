import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'enquiry_location.dart';

/// One function of a booking (Haldi, Mehendi, Wedding, Reception…) on its own day.
///
/// Stored in the enquiry's `functions` array. Customer, status, quote, payments,
/// assignee and history stay on the booking (the enquiry document).
///
/// Absent / empty `functions` = a legacy single-event enquiry: [functionsOf]
/// synthesizes one function from the top-level event fields. When functions are
/// saved, [functionSyncFields] keeps the top-level fields in sync so all existing
/// code (queries, auto-expire, rules, analytics) keeps working.
///
/// Mirrored by functions/src/eventFunctions.ts — keep both in sync.
class EventFunction {
  const EventFunction({
    required this.id,
    required this.eventType,
    required this.date,
    this.eventTypeLabel,
    this.time,
    this.location,
    this.locationArea,
    this.locationPlaceId,
    this.locationAddress,
    this.notes,
  });

  /// Id of the function synthesized from a legacy single-event enquiry.
  static const String legacyId = 'main';

  /// Short random id (stable across edits of the same function).
  final String id;

  /// Event type dropdown value, e.g. `haldi`.
  final String eventType;
  final String? eventTypeLabel;

  /// Calendar day (local midnight, like `eventDate`).
  final DateTime date;

  /// Optional start time, `HH:mm`.
  final String? time;
  final String? location;
  final String? locationArea;
  final String? locationPlaceId;
  final String? locationAddress;
  final String? notes;

  /// [date] at local midnight.
  DateTime get day => DateTime(date.year, date.month, date.day);

  /// "Haldi" — the stored label, else the title-cased value.
  String get label {
    final stored = eventTypeLabel?.trim() ?? '';
    if (stored.isNotEmpty) return stored;
    return _titleCase(eventType);
  }

  /// Area if known, else the location text; null when neither is set.
  String? get place => locationArea ?? location;

  bool get hasLocation => (location?.trim().isNotEmpty ?? false);

  /// This function with a different [id] (e.g. a real id for the synthesized legacy one).
  EventFunction withId(String id) => EventFunction(
    id: id,
    eventType: eventType,
    eventTypeLabel: eventTypeLabel,
    date: date,
    time: time,
    location: location,
    locationArea: locationArea,
    locationPlaceId: locationPlaceId,
    locationAddress: locationAddress,
    notes: notes,
  );

  /// Parses one `functions` entry; null when it has no type or date.
  static EventFunction? tryFromMap(Map<String, dynamic> map, {int index = 0}) {
    final date = _date(map['date']);
    final type = _text(map['eventType']);
    if (date == null || type == null) return null;
    return EventFunction(
      id: _text(map['id']) ?? 'f$index',
      eventType: type,
      eventTypeLabel: _text(map['eventTypeLabel']),
      date: DateTime(date.year, date.month, date.day),
      time: _text(map['time']),
      location: _text(map['location']),
      locationArea: _text(map['locationArea']),
      locationPlaceId: _text(map['locationPlaceId']),
      locationAddress: _text(map['locationAddress']),
      notes: _text(map['notes']),
    );
  }

  /// Like [tryFromMap] but throws [FormatException] for an invalid entry.
  factory EventFunction.fromMap(Map<String, dynamic> map) {
    final parsed = tryFromMap(map);
    if (parsed == null) throw const FormatException('Function needs eventType and date');
    return parsed;
  }

  /// Firestore map (only non-empty optional fields).
  Map<String, Object> toMap() => {
    'id': id,
    'eventType': eventType,
    'eventTypeLabel': label,
    'date': Timestamp.fromDate(day),
    if (_text(time) != null) 'time': time!.trim(),
    if (_text(location) != null) 'location': location!.trim(),
    if (_text(locationArea) != null) 'locationArea': locationArea!.trim(),
    if (_text(locationPlaceId) != null) 'locationPlaceId': locationPlaceId!.trim(),
    if (_text(locationAddress) != null) 'locationAddress': locationAddress!.trim(),
    if (_text(notes) != null) 'notes': notes!.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is EventFunction &&
      other.id == id &&
      other.eventType == eventType &&
      other.label == label &&
      other.day == day &&
      _text(other.time) == _text(time) &&
      _text(other.location) == _text(location) &&
      _text(other.locationArea) == _text(locationArea) &&
      _text(other.locationPlaceId) == _text(locationPlaceId) &&
      _text(other.locationAddress) == _text(locationAddress) &&
      _text(other.notes) == _text(notes);

  @override
  int get hashCode => Object.hash(id, eventType, day, time, location, notes);

  @override
  String toString() => 'EventFunction($id, $eventType, $day)';
}

String? _text(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _date(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

String _titleCase(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

Map<String, dynamic>? _stringKeyed(Object? raw) {
  if (raw is! Map) return null;
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

/// Orders by day, then time (untimed first).
int compareEventFunctions(EventFunction a, EventFunction b) {
  final byDay = a.day.compareTo(b.day);
  if (byDay != 0) return byDay;
  return (a.time ?? '').compareTo(b.time ?? '');
}

/// A sorted copy of [functions] (stable for equal keys).
List<EventFunction> sortEventFunctions(Iterable<EventFunction> functions) {
  final indexed = functions.toList().asMap().entries.toList()
    ..sort((a, b) {
      final c = compareEventFunctions(a.value, b.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// The booking's functions, ordered by date then time.
///
/// Legacy enquiries (no / empty `functions`) give ONE function synthesized from
/// `eventType(Value)` / `eventTypeLabel` / `eventDate` / `eventLocation` /
/// location fields, with id [EventFunction.legacyId]. A legacy enquiry without an
/// event date (or the 1970 placeholder) gives none.
List<EventFunction> functionsOf(Map<String, dynamic> data) {
  final raw = data['functions'];
  if (raw is List && raw.isNotEmpty) {
    final parsed = <EventFunction>[];
    for (var i = 0; i < raw.length; i++) {
      final map = _stringKeyed(raw[i]);
      final f = map == null ? null : EventFunction.tryFromMap(map, index: i);
      if (f != null) parsed.add(f);
    }
    if (parsed.isNotEmpty) return sortEventFunctions(parsed);
  }
  final date = _date(data['eventDate']);
  if (date == null || date.year <= 1971) return const [];
  return [
    EventFunction(
      id: EventFunction.legacyId,
      eventType: _text(data['eventTypeValue']) ?? _text(data['eventType']) ?? 'event',
      eventTypeLabel: _text(data['eventTypeLabel']),
      date: DateTime(date.year, date.month, date.day),
      location: _text(data['eventLocation']) ?? _text(data['location']),
      locationArea: _text(data[EnquiryPlace.areaField]),
      locationPlaceId: _text(data[EnquiryPlace.placeIdField]),
      locationAddress: _text(data[EnquiryPlace.addressField]),
    ),
  ];
}

/// True when the booking has two or more functions.
bool hasMultipleFunctions(Map<String, dynamic> data) => functionsOf(data).length > 1;

/// Wedding-family types that ARE the wedding. Mirrors `WEDDING_ANCHOR_KEYWORDS` /
/// `isWeddingAnchor` in functions/src/reengagementLogic.ts.
const List<String> weddingAnchorKeywords = [
  'wedding',
  'marriage',
  'nikah',
  'nikkah',
  'shaadi',
  'muhurtham',
  'muhurtam',
];

/// True for the wedding itself (not haldi / reception / pre-wedding shoot).
bool isWeddingAnchorType(String? value, [String? label]) {
  final text = [value, label]
      .whereType<String>()
      .join(' ')
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '')
      .replaceAll('prewedding', '');
  return weddingAnchorKeywords.any(text.contains);
}

/// The booking's main function: the first wedding-anchor function, else the first.
EventFunction? mainFunctionOf(List<EventFunction> functions) {
  if (functions.isEmpty) return null;
  final sorted = sortEventFunctions(functions);
  for (final f in sorted) {
    if (isWeddingAnchorType(f.eventType, f.eventTypeLabel)) return f;
  }
  return sorted.first;
}

/// First function on or after [now]'s day, else the last one; null when empty.
EventFunction? nextFunctionOf(List<EventFunction> functions, DateTime now) {
  if (functions.isEmpty) return null;
  final sorted = sortEventFunctions(functions);
  final today = DateTime(now.year, now.month, now.day);
  for (final f in sorted) {
    if (!f.day.isBefore(today)) return f;
  }
  return sorted.last;
}

/// Date to sort a booking by in client-side lists: the next upcoming function
/// (else the last). Legacy enquiries: their `eventDate`.
DateTime? listSortDateOf(Map<String, dynamic> data, DateTime now) {
  final functions = functionsOf(data);
  if (functions.length <= 1) return _date(data['eventDate']);
  return nextFunctionOf(functions, now)?.day;
}

/// Distinct function days of a booking, ascending.
List<DateTime> functionDaysOf(Map<String, dynamic> data) {
  final days = <DateTime>{for (final f in functionsOf(data)) f.day}.toList()..sort();
  return days;
}

/// Fields to write when [functions] are saved. A `null` value means "delete the field".
///
/// * `functions`: sorted maps; `functionCount`; `eventStartDate` = first day.
/// * `eventDate` = LAST day, so auto-expire / completion waits for the last function.
/// * `eventType` / `eventTypeValue` / `eventTypeLabel` = main function ([mainFunctionOf]).
/// * `eventLocation` + place fields = the main function's location if it has one,
///   else the first function with a location, else left as they are (absent from
///   the result). Lat / lng / city are kept only when the place id is unchanged.
Map<String, Object?> functionSyncFields(
  List<EventFunction> functions, {
  Map<String, dynamic> existing = const {},
}) {
  if (functions.isEmpty) {
    throw ArgumentError.value(functions, 'functions', 'At least one function is required');
  }
  // The synthesized legacy function gets a real id once it is stored in the array.
  final sorted = sortEventFunctions(
    functions.map((f) => f.id == EventFunction.legacyId ? f.withId(newEventFunctionId()) : f),
  );
  final main = mainFunctionOf(sorted)!;
  final fields = <String, Object?>{
    'functions': [for (final f in sorted) f.toMap()],
    'functionCount': sorted.length,
    'eventStartDate': Timestamp.fromDate(sorted.first.day),
    'eventDate': Timestamp.fromDate(sorted.last.day),
    'eventType': main.eventType,
    'eventTypeValue': main.eventType,
    'eventTypeLabel': main.label,
  };
  EventFunction? located;
  if (main.hasLocation) {
    located = main;
  } else {
    for (final f in sorted) {
      if (f.hasLocation) {
        located = f;
        break;
      }
    }
  }
  if (located != null) {
    final placeId = _text(located.locationPlaceId);
    final samePlace = placeId != null && placeId == _text(existing[EnquiryPlace.placeIdField]);
    fields['eventLocation'] = located.location!.trim();
    fields[EnquiryPlace.areaField] = _text(located.locationArea);
    fields[EnquiryPlace.placeIdField] = placeId;
    fields[EnquiryPlace.addressField] = _text(located.locationAddress);
    if (!samePlace) {
      fields[EnquiryPlace.latField] = null;
      fields[EnquiryPlace.lngField] = null;
      fields[EnquiryPlace.cityField] = null;
    }
  }
  return fields;
}

/// Fields that clear the multi-function data (back to a single legacy event).
const Map<String, Object?> clearFunctionFields = {
  'functions': null,
  'functionCount': null,
  'eventStartDate': null,
};

/// Whether a single remaining function carries data the legacy fields can't hold.
bool needsFunctionArray(List<EventFunction> functions) =>
    functions.length > 1 ||
    functions.any((f) => _text(f.time) != null || _text(f.notes) != null);

/// Everything to write when a booking's functions are saved (null = delete):
/// [functionSyncFields] for 2+ functions (or one with a time / notes); a single plain
/// function goes back to the legacy single-event shape (`functions`,
/// `functionCount`, `eventStartDate` removed when [existing] has them).
Map<String, Object?> functionsWriteFields(
  List<EventFunction> functions, {
  Map<String, dynamic> existing = const {},
}) {
  final fields = functionSyncFields(functions, existing: existing);
  if (needsFunctionArray(functions)) return fields;
  for (final key in clearFunctionFields.keys) {
    fields.remove(key);
    if (existing.containsKey(key)) fields[key] = null;
  }
  return fields;
}

final DateFormat _dayMonth = DateFormat('d MMM');

/// "Haldi 10 Dec; Mehendi 11 Dec; Wedding 12 Dec 7:00 PM" — CSV / history text.
String functionsSummary(List<EventFunction> functions) {
  return sortEventFunctions(functions)
      .map((f) {
        final time = formatFunctionTime(f.time);
        return '${f.label} ${_dayMonth.format(f.day)}${time == null ? '' : ' $time'}';
      })
      .join('; ');
}

/// "10–13 Dec", "30 Dec – 2 Jan", or "12 Dec" for a single day.
String functionDateRangeLabel(List<EventFunction> functions) {
  if (functions.isEmpty) return '';
  final sorted = sortEventFunctions(functions);
  final first = sorted.first.day;
  final last = sorted.last.day;
  if (first == last) return _dayMonth.format(first);
  if (first.year == last.year && first.month == last.month) {
    return '${first.day}–${_dayMonth.format(last)}';
  }
  return '${_dayMonth.format(first)} – ${_dayMonth.format(last)}';
}

/// List-row subtitle for a multi-function booking:
/// "4 functions · 10–13 Dec · Next: Haldi, 10 Dec (JP Nagar)". Null for 0–1 functions.
String? functionsListSubtitle(List<EventFunction> functions, DateTime now) {
  if (functions.length <= 1) return null;
  final next = nextFunctionOf(functions, now)!;
  final place = next.place?.trim() ?? '';
  final where = place.isEmpty ? '' : ' ($place)';
  return '${functions.length} functions · ${functionDateRangeLabel(functions)} · '
      'Next: ${next.label}, ${_dayMonth.format(next.day)}$where';
}

/// "7:00 PM" for `19:00`; null when blank or malformed.
String? formatFunctionTime(String? time) {
  final parsed = parseFunctionTime(time);
  if (parsed == null) return null;
  return DateFormat('h:mm a').format(DateTime(2000, 1, 1, parsed.$1, parsed.$2));
}

/// (hour, minute) of an `HH:mm` string; null when blank or malformed.
(int, int)? parseFunctionTime(String? time) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time?.trim() ?? '');
  if (match == null) return null;
  final h = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  if (h > 23 || m > 59) return null;
  return (h, m);
}

/// `HH:mm` for an hour and minute.
String functionTimeText(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Event type labels of every function, for the search index (`textIndex`).
List<String> functionTypeLabels(List<EventFunction> functions) =>
    {for (final f in functions) f.label}.toList();

final Random _idRandom = Random();
const String _idAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// Short random function id, e.g. `k3f9x2ab`.
String newEventFunctionId({Random? random}) {
  final r = random ?? _idRandom;
  return String.fromCharCodes(
    List.generate(8, (_) => _idAlphabet.codeUnitAt(r.nextInt(_idAlphabet.length))),
  );
}
