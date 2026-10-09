/// Pure helpers for the optional amounts in the Confirm booking sheet and the
/// "Amount pending" marker.
///
/// Money is never required: empty fields write nothing, and only amounts the admin
/// actually changed are written (financial fields are admin-only in the rules).
library;

import 'package:intl/intl.dart';

import '../../../core/constants/status_vocabulary.dart';

/// Canonical payment status values (see `DropdownDefaults.paymentStatuses`).
const String kPaymentStatusPaid = 'paid';
const String kPaymentStatusPartial = 'partial';

/// Amount typed in a field → number; empty or unreadable → null. Same parsing as
/// the edit form (`double.tryParse` on the trimmed text).
double? parseAmountText(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return double.tryParse(value.trim());
}

/// Payment status implied by the amounts: advance ≥ total → paid, some advance →
/// partial, otherwise null (leave the stored status as it is).
String? derivePaymentStatus({double? total, double? advance}) {
  if (total == null || total <= 0 || advance == null || advance <= 0) return null;
  return advance >= total ? kPaymentStatusPaid : kPaymentStatusPartial;
}

/// "₹1,50,000" (Indian digit grouping; decimals only when present).
String formatBookingAmount(num amount) =>
    '₹${NumberFormat.decimalPattern('en_IN').format(amount)}';

/// "Balance ₹1,50,000" once a total is entered; null otherwise. Never negative.
String? bookingBalanceText({double? total, double? advance}) {
  if (total == null || total <= 0) return null;
  final balance = total - (advance ?? 0);
  return 'Balance ${formatBookingAmount(balance < 0 ? 0 : balance)}';
}

/// The booking has a total amount (`totalCost` is a number above zero).
///
/// Multi-function bookings carry one top-level `totalCost` for the whole booking.
bool bookingHasAmount(Map<String, dynamic> data) {
  final total = data['totalCost'];
  return total is num && total > 0;
}

/// Approved or completed booking without a total amount yet — shown to admins as
/// "Amount pending" (approving never requires an amount).
bool isApprovedAmountPending(Map<String, dynamic> data) {
  final status = EnquiryStatus.fromValue(data['statusValue'] as String?);
  if (status != EnquiryStatus.approved && status != EnquiryStatus.completed) return false;
  return !bookingHasAmount(data);
}

/// Confirm booking sheet subtitle: "Ayesha Khan · Wedding · 12 Dec 2026", skipping
/// empty parts (and placeholder dates from legacy data).
String confirmBookingSubtitle({String? customerName, String? eventType, DateTime? eventDate}) {
  return [
    customerName?.trim() ?? '',
    eventType?.trim() ?? '',
    if (eventDate != null && eventDate.year > 1971) DateFormat('d MMM yyyy').format(eventDate),
  ].where((part) => part.isNotEmpty).join(' · ');
}

num? _storedAmount(Object? value) => value is num ? value : null;

/// Fields to write with the approval for the amounts typed in the sheet.
///
/// Only changed amounts are included (empty = cleared, unreadable = unchanged).
/// When something changed and the amounts imply a payment status that differs from
/// the stored one, the status value + label are included too.
Map<String, Object?> bookingAmountFields({
  required Map<String, dynamic> oldData,
  required String totalText,
  required String advanceText,
  required String Function(String value) paymentStatusLabel,
}) {
  final oldTotal = _storedAmount(oldData['totalCost']);
  final oldAdvance = _storedAmount(oldData['advancePaid']);
  final newTotal = totalText.trim().isEmpty
      ? null
      : (parseAmountText(totalText) ?? oldTotal?.toDouble());
  final newAdvance = advanceText.trim().isEmpty
      ? null
      : (parseAmountText(advanceText) ?? oldAdvance?.toDouble());
  final totalChanged = newTotal != oldTotal;
  final advanceChanged = newAdvance != oldAdvance;
  if (!totalChanged && !advanceChanged) return const {};

  final fields = <String, Object?>{
    if (totalChanged) 'totalCost': newTotal,
    if (advanceChanged) 'advancePaid': newAdvance,
  };
  final derived = derivePaymentStatus(total: newTotal, advance: newAdvance);
  final oldStatus = oldData['paymentStatusValue'] ?? oldData['paymentStatus'];
  if (derived != null && derived != oldStatus) {
    fields['paymentStatus'] = derived;
    fields['paymentStatusValue'] = derived;
    fields['paymentStatusLabel'] = paymentStatusLabel(derived);
  }
  return fields;
}

/// History entries (`{field: {old_value, new_value}}`) for the money fields in
/// [fields], in the same shape the edit form records them.
Map<String, Map<String, dynamic>> bookingAmountAuditChanges(
  Map<String, dynamic> oldData,
  Map<String, Object?> fields,
) {
  final changes = <String, Map<String, dynamic>>{};
  for (final key in const ['totalCost', 'advancePaid']) {
    if (!fields.containsKey(key)) continue;
    final oldValue = _storedAmount(oldData[key]);
    final newValue = fields[key];
    if (newValue != null && newValue is! num) continue;
    if (oldValue != newValue) {
      changes[key] = {'old_value': oldValue ?? 0, 'new_value': newValue ?? 0};
    }
  }
  if (fields.containsKey('paymentStatusValue')) {
    final oldStatus = oldData['paymentStatusValue'] ?? oldData['paymentStatus'];
    final newStatus = fields['paymentStatusValue'];
    if (oldStatus != newStatus) {
      changes['paymentStatus'] = {
        'old_value': oldStatus ?? 'Not Set',
        'new_value': newStatus ?? 'Not Set',
      };
    }
  }
  return changes;
}
