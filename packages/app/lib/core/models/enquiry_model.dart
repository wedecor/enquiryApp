import 'package:freezed_annotation/freezed_annotation.dart';

part 'enquiry_model.freezed.dart';
part 'enquiry_model.g.dart';

@JsonEnum(alwaysCreate: true)
enum EnquiryStatus { enquired, inTalks, confirmed, notInterested, completed }

@freezed
class BudgetRange with _$BudgetRange {
  const factory BudgetRange({
    int? min,
    int? max,
  }) = _BudgetRange;
  factory BudgetRange.fromJson(Map<String, dynamic> json) => _$BudgetRangeFromJson(json);
}

@freezed
class Payment with _$Payment {
  const factory Payment({
    int? totalAmount,
    int? advanceAmount,
    int? balance,
    DateTime? confirmedAt,
  }) = _Payment;
  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
class Enquiry with _$Enquiry {
  const factory Enquiry({
    required String id,
    required String customerName,
    required String customerPhone,
    String? customerEmail,

    required String eventTypeId,
    required String eventTypeLabel,
    required DateTime eventDate,
    required String locationText,
    int? guestCount,
    BudgetRange? budgetRange,

    required EnquiryStatus status,
    required String createdByUid,
    String? assignedToUid,
    DateTime? assignedAt,

    Payment? payment,

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Enquiry;

  factory Enquiry.fromJson(Map<String, dynamic> json) => _$EnquiryFromJson(json);
}
