import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/dropdown_defaults.dart';
import '../core/services/firestore_service.dart';
import '../core/utils/color_parsing.dart';

class DropdownLookup {
  DropdownLookup(this._firestoreService);

  final FirestoreService _firestoreService;

  Map<String, String> statusMap = <String, String>{};
  Map<String, String> eventTypeMap = <String, String>{};
  Map<String, String> paymentStatusMap = <String, String>{};
  Map<String, String> priorityMap = <String, String>{};
  Map<String, String> sourceMap = <String, String>{};
  Map<String, Color> statusColorMap = <String, Color>{};

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final results = await Future.wait<Map<String, String>>(<Future<Map<String, String>>>[
      _firestoreService.fetchDropdownValueLabelMap('statuses'),
      _firestoreService.fetchDropdownValueLabelMap('event_types'),
      _firestoreService.fetchDropdownValueLabelMap('payment_statuses'),
      _firestoreService.fetchDropdownValueLabelMap('priorities'),
      _firestoreService.fetchDropdownValueLabelMap('sources'),
    ]);

    statusMap = DropdownDefaults.resolveMap(results[0], 'statuses');
    eventTypeMap = DropdownDefaults.resolveMap(results[1], 'event_types');
    paymentStatusMap = DropdownDefaults.resolveMap(results[2], 'payment_statuses');
    priorityMap = DropdownDefaults.resolveMap(results[3], 'priorities');
    sourceMap = DropdownDefaults.resolveMap(results[4], 'sources');

    final statusSnapshot = await _firestoreService.fetchActiveDropdownItems('statuses');
    final colors = <String, Color>{};
    for (final doc in statusSnapshot.docs) {
      final data = doc.data();
      final value = (data['value'] as String?)?.trim().toLowerCase();
      final colorHex = data['color'] as String?;
      if (value == null || value.isEmpty) continue;
      final color = parseDropdownColor(colorHex);
      if (color != null) colors[value] = color;
    }
    statusColorMap = colors;

    _loaded = true;
  }

  String labelForStatus(String value) => statusMap[value] ?? DropdownLookup.titleCase(value);

  String labelForEventType(String value) => eventTypeMap[value] ?? DropdownLookup.titleCase(value);

  String labelForPaymentStatus(String value) =>
      paymentStatusMap[value] ?? DropdownLookup.titleCase(value);

  String labelForPriority(String value) => priorityMap[value] ?? DropdownLookup.titleCase(value);

  String labelForSource(String value) => sourceMap[value] ?? DropdownLookup.titleCase(value);

  static String titleCase(String value) {
    final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (normalized.isEmpty) {
      return value;
    }
    final words = normalized.split(RegExp(r'\s+'));
    return words
        .map(
          (word) =>
              word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  void reset() {
    _loaded = false;
    statusMap = <String, String>{};
    eventTypeMap = <String, String>{};
    paymentStatusMap = <String, String>{};
    priorityMap = <String, String>{};
    sourceMap = <String, String>{};
    statusColorMap = <String, Color>{};
  }
}

final dropdownLookupProvider = FutureProvider<DropdownLookup>((ref) async {
  final lookup = DropdownLookup(ref.watch(firestoreServiceProvider));
  await lookup.ensureLoaded();
  ref.onDispose(lookup.reset);
  return lookup;
});
