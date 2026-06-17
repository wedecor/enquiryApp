import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/firestore_service.dart';

class DropdownLookup {
  DropdownLookup(this._firestoreService);

  final FirestoreService _firestoreService;

  Map<String, String> statusMap = <String, String>{};
  Map<String, String> eventTypeMap = <String, String>{};
  Map<String, String> paymentStatusMap = <String, String>{};
  Map<String, String> priorityMap = <String, String>{};
  Map<String, String> sourceMap = <String, String>{};

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

    statusMap = results[0];
    eventTypeMap = results[1];
    paymentStatusMap = results[2];
    priorityMap = results[3];
    sourceMap = results[4];
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
  }
}

final dropdownLookupProvider = FutureProvider<DropdownLookup>((ref) async {
  final lookup = DropdownLookup(ref.watch(firestoreServiceProvider));
  await lookup.ensureLoaded();
  ref.onDispose(lookup.reset);
  return lookup;
});
