import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger.dart';
import '../domain/enquiry_location.dart';

/// One venue suggestion from the `placesAutocomplete` callable.
class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.mainText, this.secondaryText = ''});

  final String placeId;

  /// Venue name, e.g. "Palace Grounds".
  final String mainText;

  /// Rest of the address, e.g. "Jayamahal, Bengaluru, Karnataka, India".
  final String secondaryText;

  /// Null when the entry has no place id or name.
  static PlaceSuggestion? fromMap(Map<String, dynamic> map) {
    final placeId = _string(map['placeId']);
    final mainText = _string(map['mainText']);
    if (placeId == null || mainText == null) return null;
    return PlaceSuggestion(
      placeId: placeId,
      mainText: mainText,
      secondaryText: _string(map['secondaryText']) ?? '',
    );
  }

  /// Parses the callable's response. Android returns `Map<Object?, Object?>`
  /// (nested maps too), so every level is converted before reading.
  static List<PlaceSuggestion> listFromResponse(Object? data) {
    final map = _map(data);
    final raw = map?['suggestions'];
    if (raw is! List) return const [];
    return raw
        .map(_map)
        .whereType<Map<String, dynamic>>()
        .map(PlaceSuggestion.fromMap)
        .whereType<PlaceSuggestion>()
        .take(PlacesService.maxSuggestions)
        .toList();
  }
}

/// Result of the `placeDetails` callable (Essentials fields only).
class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    this.address,
    this.lat,
    this.lng,
    this.area,
    this.city,
  });

  final String placeId;
  final String? address;
  final double? lat;
  final double? lng;
  final String? area;
  final String? city;

  /// Null when the response has no place id.
  static PlaceDetails? fromResponse(Object? data) {
    final map = _map(data);
    if (map == null) return null;
    final placeId = _string(map['placeId']);
    if (placeId == null) return null;
    return PlaceDetails(
      placeId: placeId,
      address: _string(map['address']),
      lat: _number(map['lat']),
      lng: _number(map['lng']),
      area: _string(map['area']),
      city: _string(map['city']),
    );
  }

  EnquiryPlace toEnquiryPlace() => EnquiryPlace(
    placeId: placeId,
    address: address,
    lat: lat,
    lng: lng,
    area: area,
    city: city,
  );
}

Map<String, dynamic>? _map(Object? raw) {
  if (raw is! Map) return null;
  return Map<String, dynamic>.from(raw.map((key, value) => MapEntry(key.toString(), value)));
}

String? _string(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _number(Object? raw) {
  if (raw is! num) return null;
  final value = raw.toDouble();
  return value.isFinite ? value : null;
}

final Random _secureRandom = Random.secure();

/// Random RFC 4122 version-4 UUID string for a Places autocomplete session.
///
/// One token covers a run of autocomplete requests plus the details call for
/// the picked place, so Google bills them as one session.
String newPlacesSessionToken({Random? random}) {
  final rng = random ?? _secureRandom;
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Venue search for the enquiry Location field via the `placesAutocomplete` /
/// `placeDetails` callables (asia-south1). The Maps API key stays on the server.
class PlacesService {
  const PlacesService();

  /// Characters typed before a search is worth making.
  static const int minQueryLength = 3;
  static const int maxQueryLength = 100;
  static const int maxSuggestions = 5;

  /// Up to [maxSuggestions] venues for [input]. Never throws: failures (including
  /// "Maps search isn't set up yet") are logged and return an empty list, so the
  /// field keeps working as plain free text.
  Future<List<PlaceSuggestion>> autocomplete(String input, {required String sessionToken}) async {
    final query = input.trim();
    if (query.length < minQueryLength) return const [];
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('placesAutocomplete');
      final response = await callable.call<dynamic>(<String, dynamic>{
        'input': query.length > maxQueryLength ? query.substring(0, maxQueryLength) : query,
        'sessionToken': sessionToken,
      });
      return PlaceSuggestion.listFromResponse(response.data);
    } catch (e, st) {
      Log.w('PlacesService: autocomplete failed', data: {'error': e.toString()});
      Log.e('PlacesService: autocomplete error', error: e, stackTrace: st);
      return const [];
    }
  }

  /// Address, coordinates and area for a picked suggestion, or null on failure.
  Future<PlaceDetails?> details(String placeId, {required String sessionToken}) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('placeDetails');
      final response = await callable.call<dynamic>(<String, dynamic>{
        'placeId': placeId,
        'sessionToken': sessionToken,
      });
      return PlaceDetails.fromResponse(response.data);
    } catch (e, st) {
      Log.w('PlacesService: details failed', data: {'error': e.toString()});
      Log.e('PlacesService: details error', error: e, stackTrace: st);
      return null;
    }
  }
}

final placesServiceProvider = Provider<PlacesService>((ref) => const PlacesService());
