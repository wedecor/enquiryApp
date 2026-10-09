import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger.dart';
import '../../../core/utils/phone_normalizer.dart';

/// Contact basics of a customer, taken from their most recent enquiry.
class CustomerSummary {
  const CustomerSummary({required this.name, this.email, this.whatsappNumber, this.phone});

  final String name;
  final String? email;
  final String? whatsappNumber;
  final String? phone;

  factory CustomerSummary.fromMap(Map<String, dynamic> map) => CustomerSummary(
    name: _string(map['name']) ?? 'Customer',
    email: _string(map['email']),
    whatsappNumber: _string(map['whatsappNumber']),
    phone: _string(map['phone']),
  );
}

/// One of a customer's enquiries (minimal fields — no money or notes).
class CustomerEvent {
  const CustomerEvent({
    required this.id,
    required this.eventType,
    required this.statusLabel,
    required this.isOpen,
    this.eventDate,
    this.status,
    this.assignedToName,
    this.assignedToMe = false,
    this.createdAt,
  });

  final String id;

  /// Event type label, e.g. "Birthday".
  final String eventType;
  final DateTime? eventDate;

  /// Canonical status value (null when the stored status is unknown).
  final String? status;
  final String statusLabel;

  /// Assignee's display name, or null when unassigned.
  final String? assignedToName;

  /// True when the signed-in user is the assignee.
  final bool assignedToMe;
  final DateTime? createdAt;

  /// New, In Talks or Approved.
  final bool isOpen;

  bool get isAssigned => assignedToName != null;

  /// Admins open any enquiry; staff only the ones assigned to them (rules).
  bool canOpen({required bool isAdmin}) => isAdmin || assignedToMe;

  factory CustomerEvent.fromMap(Map<String, dynamic> map) => CustomerEvent(
    id: _string(map['id']) ?? '',
    eventType: _string(map['eventType']) ?? 'Event',
    eventDate: _date(map['eventDate']),
    status: _string(map['status']),
    statusLabel: _string(map['statusLabel']) ?? 'Unknown',
    assignedToName: _string(map['assignedToName']),
    assignedToMe: map['assignedToMe'] == true,
    createdAt: _date(map['createdAt']),
    isOpen: map['isOpen'] == true,
  );
}

/// Result of the `lookupCustomer` callable.
class CustomerLookupResult {
  const CustomerLookupResult({
    required this.customer,
    required this.events,
    required this.totalEvents,
    required this.openEvents,
  });

  static const empty = CustomerLookupResult(
    customer: null,
    events: [],
    totalEvents: 0,
    openEvents: 0,
  );

  /// Null when no enquiry has this phone number.
  final CustomerSummary? customer;

  /// Newest first; excludes the enquiry passed as `excludeEnquiryId`.
  final List<CustomerEvent> events;
  final int totalEvents;
  final int openEvents;

  bool get isKnownCustomer => customer != null;

  List<CustomerEvent> get openEventList => events.where((e) => e.isOpen).toList();

  /// Parses the callable's response. Android returns `Map<Object?, Object?>`
  /// (nested maps too), so every level is converted before reading.
  factory CustomerLookupResult.fromResponse(Object? data) {
    final map = _map(data);
    if (map == null) return empty;
    final customerMap = _map(map['customer']);
    final rawEvents = map['events'];
    final events = rawEvents is List
        ? rawEvents
              .map(_map)
              .whereType<Map<String, dynamic>>()
              .map(CustomerEvent.fromMap)
              .where((e) => e.id.isNotEmpty)
              .toList()
        : <CustomerEvent>[];
    return CustomerLookupResult(
      customer: customerMap == null ? null : CustomerSummary.fromMap(customerMap),
      events: events,
      totalEvents: (map['totalEvents'] as num?)?.toInt() ?? events.length,
      openEvents: (map['openEvents'] as num?)?.toInt() ?? events.where((e) => e.isOpen).length,
    );
  }
}

Map<String, dynamic>? _map(Object? raw) {
  if (raw is! Map) return null;
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

String? _string(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _date(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

/// Looks up a customer's enquiries by phone via the `lookupCustomer` callable
/// (asia-south1). Server-side because staff can only read their own enquiries.
class CustomerLookupService {
  const CustomerLookupService();

  /// Minimum digits before a lookup is worth making.
  static const int minDigits = 10;

  /// Throws [FirebaseFunctionsException] on failure; see [lookupOrNull].
  Future<CustomerLookupResult> lookup(String phone, {String? excludeEnquiryId}) async {
    if (normalizePhone(phone).length < 7) return CustomerLookupResult.empty;
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).httpsCallable('lookupCustomer');
    final response = await callable.call<dynamic>(<String, dynamic>{
      'phone': phone,
      if (excludeEnquiryId != null) 'excludeEnquiryId': excludeEnquiryId,
    });
    return CustomerLookupResult.fromResponse(response.data);
  }

  /// Like [lookup] but never throws: failures are logged and return null, so a
  /// lookup problem can never block creating or viewing an enquiry.
  Future<CustomerLookupResult?> lookupOrNull(String phone, {String? excludeEnquiryId}) async {
    try {
      return await lookup(phone, excludeEnquiryId: excludeEnquiryId);
    } catch (e, st) {
      Log.w('CustomerLookupService: lookup failed', data: {'error': e.toString()});
      Log.e('CustomerLookupService: lookup error', error: e, stackTrace: st);
      return null;
    }
  }
}

final customerLookupServiceProvider = Provider<CustomerLookupService>(
  (ref) => const CustomerLookupService(),
);

/// Other enquiries of the customer with [phone], excluding [excludeEnquiryId].
/// Resolves to null when the lookup failed (callers hide their UI).
final customerOtherEventsProvider = FutureProvider.autoDispose
    .family<CustomerLookupResult?, ({String phone, String? excludeEnquiryId})>((ref, query) {
      // Keep the result for a couple of minutes so rebuilds don't re-call the Cloud
      // Function; it refreshes after that (e.g. after adding another event).
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 2), link.close);
      ref.onDispose(timer.cancel);
      return ref
          .watch(customerLookupServiceProvider)
          .lookupOrNull(query.phone, excludeEnquiryId: query.excludeEnquiryId);
    });
