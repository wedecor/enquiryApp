import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'enquiry.freezed.dart';
part 'enquiry.g.dart';

/// Enquiry domain model
@freezed
class Enquiry with _$Enquiry {
  const factory Enquiry({
    required String id,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    required String eventType,
    required DateTime eventDate,
    String? eventLocation,
    int? guestCount,
    String? budgetRange,
    String? description,
    @Default('new') String status,
    String? paymentStatus,
    double? totalCost,
    double? advancePaid,
    String? assignedTo,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? priority,
    String? source,
    String? notes,
  }) = _Enquiry;

  factory Enquiry.fromJson(Map<String, dynamic> json) => _$EnquiryFromJson(json);

  factory Enquiry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Enquiry(
      id: doc.id,
      customerName: data['customerName'] as String? ?? '',
      customerEmail: data['customerEmail'] as String?,
      customerPhone: data['customerPhone'] as String?,
      eventType: data['eventType'] as String? ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventLocation: data['eventLocation'] as String?,
      guestCount: data['guestCount'] as int?,
      budgetRange: data['budgetRange'] as String?,
      description: data['description'] as String?,
      status: data['eventStatus'] as String? ?? 'new',
      paymentStatus: data['paymentStatus'] as String?,
      totalCost: (data['totalCost'] as num?)?.toDouble(),
      advancePaid: (data['advancePaid'] as num?)?.toDouble(),
      assignedTo: data['assignedTo'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
      priority: data['priority'] as String?,
      source: data['source'] as String?,
      notes: data['notes'] as String?,
    );
  }
}
