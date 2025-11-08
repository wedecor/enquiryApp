import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'enquiry.freezed.dart';
part 'enquiry.g.dart';

/// Enquiry domain model
@freezed
class Enquiry with _$Enquiry {
  const Enquiry._();

  const factory Enquiry({
    required String id,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    @JsonKey(name: 'eventTypeValue') required String eventType,
    String? eventTypeLabel,
    required DateTime eventDate,
    String? eventLocation,
    int? guestCount,
    String? budgetRange,
    String? description,
    @JsonKey(name: 'statusValue') @Default('new') String status,
    String? statusLabel,
    @JsonKey(name: 'paymentStatusValue') String? paymentStatus,
    String? paymentStatusLabel,
    double? totalCost,
    double? advancePaid,
    String? assignedTo,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(name: 'priorityValue') String? priority,
    String? priorityLabel,
    @JsonKey(name: 'sourceValue') String? source,
    String? sourceLabel,
    String? notes,
    // New denormalized and search fields (optional for back-compat)
    String? customerNameLower,
    String? phoneNormalized,
    String? assigneeName,
    String? createdByName,
    DateTime? statusUpdatedAt,
    String? statusUpdatedBy,
    String? textIndex,
  }) = _Enquiry;

  factory Enquiry.fromJson(Map<String, dynamic> json) => _$EnquiryFromJson(json);

  factory Enquiry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Enquiry(
      id: doc.id,
      customerName: data['customerName'] as String? ?? '',
      customerEmail: data['customerEmail'] as String?,
      customerPhone: data['customerPhone'] as String?,
      eventType: (data['eventTypeValue'] as String?) ?? (data['eventType'] as String?) ?? '',
      eventTypeLabel: data['eventTypeLabel'] as String?,
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventLocation: data['eventLocation'] as String?,
      guestCount: data['guestCount'] as int?,
      budgetRange: data['budgetRange'] as String?,
      description: data['description'] as String?,
      status:
          (data['statusValue'] ?? data['eventStatus'] ?? data['status'] ?? data['status_slug'])
              as String? ??
          'new',
      statusLabel: data['statusLabel'] as String?,
      paymentStatus: (data['paymentStatusValue'] ?? data['paymentStatus']) as String?,
      paymentStatusLabel: data['paymentStatusLabel'] as String?,
      totalCost: (data['totalCost'] as num?)?.toDouble(),
      advancePaid: (data['advancePaid'] as num?)?.toDouble(),
      assignedTo: data['assignedTo'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
      priority: (data['priorityValue'] ?? data['priority']) as String?,
      priorityLabel: data['priorityLabel'] as String?,
      source: (data['sourceValue'] ?? data['source']) as String?,
      sourceLabel: data['sourceLabel'] as String?,
      notes: data['notes'] as String?,
      customerNameLower:
          (data['customerNameLower'] as String?) ??
          (data['customerName'] as String? ?? '').toLowerCase(),
      phoneNormalized: data['phoneNormalized'] as String?,
      assigneeName: data['assigneeName'] as String?,
      createdByName: data['createdByName'] as String?,
      statusUpdatedAt: (data['statusUpdatedAt'] as Timestamp?)?.toDate(),
      statusUpdatedBy: data['statusUpdatedBy'] as String?,
      textIndex: (data['textIndex'] as String?) ?? '',
    );
  }

  String get statusDisplay => statusLabel ?? status;
  String get eventTypeDisplay => eventTypeLabel ?? eventType;
  String? get paymentStatusDisplay => paymentStatusLabel ?? paymentStatus;
  String? get priorityDisplay => priorityLabel ?? priority;
  String? get sourceDisplay => sourceLabel ?? source;
}
