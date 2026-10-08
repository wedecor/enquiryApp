/// Pure helpers for the edit-enquiry flow, moved unchanged out of
/// `EnquiryFormScreen._updateEnquiry` so the screen holds layout, not logic.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/status_vocabulary.dart';

/// Confirmation text shown before saving a change to total cost / advance paid.
String buildFinancialChangeMessage({
  required num? oldTotalCost,
  required double? newTotalCost,
  required num? oldAdvancePaid,
  required double? newAdvancePaid,
  // Optional extra fields (omitted = not tracked by this caller).
  DateTime? newEventDate,
  String? eventTypeValue,
  int? newGuestCount,
  String? newBudgetRange,
  String? newCustomerEmail,
  String? newNotes,
  String? sourceValue,
  Map<String, Object?>? quoteFields,
  int? oldImageCount,
  int? newImageCount,
}) {
  final costChanged = oldTotalCost != newTotalCost;
  final advanceChanged = oldAdvancePaid != newAdvancePaid;

  String message = 'You are about to update financial information:\n\n';
  if (costChanged) {
    final oldCostStr = oldTotalCost != null ? '₹${oldTotalCost.toStringAsFixed(0)}' : 'Not set';
    final newCostStr = newTotalCost != null ? '₹${newTotalCost.toStringAsFixed(0)}' : 'Not set';
    message += '• Total Cost: $oldCostStr → $newCostStr\n';
  }
  if (advanceChanged) {
    final oldAdvanceStr = oldAdvancePaid != null
        ? '₹${oldAdvancePaid.toStringAsFixed(0)}'
        : 'Not set';
    final newAdvanceStr = newAdvancePaid != null
        ? '₹${newAdvancePaid.toStringAsFixed(0)}'
        : 'Not set';
    message += '• Advance Paid: $oldAdvanceStr → $newAdvanceStr\n';
  }
  message += '\nContinue with this change?';
  return message;
}

/// Field-level audit entries (`{field: {old_value, new_value}}`) for an edit.
/// Stores VALUES, not labels, exactly as before the extraction.
Map<String, Map<String, dynamic>> buildEnquiryAuditChanges({
  required Map<String, dynamic> oldEnquiryData,
  required String statusValue,
  required String? assignedTo,
  required String? priorityValue,
  required String? paymentStatusValue,
  required String newCustomerName,
  required String newCustomerPhone,
  required String newEventLocation,
  required num? oldTotalCost,
  required double? newTotalCost,
  required num? oldAdvancePaid,
  required double? newAdvancePaid,
  // Optional extra fields (omitted = not tracked by this caller).
  DateTime? newEventDate,
  String? eventTypeValue,
  int? newGuestCount,
  String? newBudgetRange,
  String? newCustomerEmail,
  String? newNotes,
  String? sourceValue,
  Map<String, Object?>? quoteFields,
  int? oldImageCount,
  int? newImageCount,
}) {
  final changes = <String, Map<String, dynamic>>{};

  // Track status change (store canonical VALUES, not labels). A legacy alias
  // that resolves to the same canonical status is not a change.
  final oldRaw = oldEnquiryData['statusValue'] as String?;
  final oldStatusValue = EnquiryStatus.canonicalValue(oldRaw) ?? oldRaw ?? 'new';
  if (oldStatusValue != (EnquiryStatus.canonicalValue(statusValue) ?? statusValue)) {
    changes['statusValue'] = {'old_value': oldStatusValue, 'new_value': statusValue};
  }

  // Track assignment change
  final oldAssignedTo = oldEnquiryData['assignedTo'] as String?;
  if (oldAssignedTo != assignedTo) {
    changes['assignedTo'] = {
      'old_value': oldAssignedTo, // null = previously unassigned; display layer shows "Unassigned"
      'new_value': assignedTo, // null = clearing the assignment
    };
  }

  // Track priority change
  final oldPriorityValue = oldEnquiryData['priorityValue'] ?? oldEnquiryData['priority'];
  if (oldPriorityValue != priorityValue) {
    changes['priority'] = {
      'old_value': oldPriorityValue ?? 'Not Set',
      'new_value': priorityValue ?? 'Not Set',
    };
  }

  // Track payment status change
  final oldPaymentStatusValue =
      oldEnquiryData['paymentStatusValue'] ?? oldEnquiryData['paymentStatus'];
  if (oldPaymentStatusValue != paymentStatusValue) {
    changes['paymentStatus'] = {
      'old_value': oldPaymentStatusValue ?? 'Not Set',
      'new_value': paymentStatusValue ?? 'Not Set',
    };
  }

  // Track customer name change
  final oldCustomerName = oldEnquiryData['customerName'] as String? ?? '';
  if (oldCustomerName != newCustomerName) {
    changes['customerName'] = {
      'old_value': oldCustomerName.isEmpty ? 'Not Set' : oldCustomerName,
      'new_value': newCustomerName.isEmpty ? 'Not Set' : newCustomerName,
    };
  }

  // Track customer phone change
  final oldCustomerPhone = oldEnquiryData['customerPhone'] as String? ?? '';
  if (oldCustomerPhone != newCustomerPhone) {
    changes['customerPhone'] = {
      'old_value': oldCustomerPhone.isEmpty ? 'Not Set' : oldCustomerPhone,
      'new_value': newCustomerPhone.isEmpty ? 'Not Set' : newCustomerPhone,
    };
  }

  // Track event location change
  final oldEventLocation = oldEnquiryData['eventLocation'] as String? ?? '';
  if (oldEventLocation != newEventLocation) {
    changes['eventLocation'] = {
      'old_value': oldEventLocation.isEmpty ? 'Not Set' : oldEventLocation,
      'new_value': newEventLocation.isEmpty ? 'Not Set' : newEventLocation,
    };
  }

  // Track total cost change
  if (oldTotalCost != newTotalCost) {
    changes['totalCost'] = {'old_value': oldTotalCost ?? 0, 'new_value': newTotalCost ?? 0};
  }

  // Track advance paid change
  if (oldAdvancePaid != newAdvancePaid) {
    changes['advancePaid'] = {'old_value': oldAdvancePaid ?? 0, 'new_value': newAdvancePaid ?? 0};
  }

  // Track event date change (calendar day; stored as Timestamp so history formats it as a date)
  if (newEventDate != null) {
    final oldEventDate = _asDateTime(oldEnquiryData['eventDate']);
    if (oldEventDate == null || !_sameDay(oldEventDate, newEventDate)) {
      changes['eventDate'] = {
        'old_value': oldEventDate != null ? Timestamp.fromDate(oldEventDate) : 'Not Set',
        'new_value': Timestamp.fromDate(newEventDate),
      };
    }
  }

  // Track event type change (VALUES, like status)
  if (eventTypeValue != null) {
    final oldEventType = (oldEnquiryData['eventTypeValue'] ?? oldEnquiryData['eventType']) as String?;
    if (oldEventType != eventTypeValue) {
      changes['eventType'] = {
        'old_value': oldEventType ?? 'Not Set',
        'new_value': eventTypeValue,
      };
    }
  }

  // Track guest count change (null = cleared / not set)
  final oldGuestRaw = oldEnquiryData['guestCount'];
  final oldGuestCount = oldGuestRaw is num ? oldGuestRaw.toInt() : int.tryParse('${oldGuestRaw ?? ''}');
  final guestTracked = newGuestCount != null || oldGuestCount != null;
  if (guestTracked && oldGuestCount != newGuestCount && !(newGuestCount == null && oldGuestCount == 0)) {
    changes['guestCount'] = {
      'old_value': oldGuestCount ?? 'Not Set',
      'new_value': newGuestCount ?? 'Not Set',
    };
  }

  _trackText(changes, oldEnquiryData, 'budgetRange', newBudgetRange);
  if (newCustomerEmail != null) {
    final oldEmail = (oldEnquiryData['customerEmail'] as String? ?? '').trim().toLowerCase();
    final newEmail = newCustomerEmail.trim().toLowerCase();
    if (oldEmail != newEmail) {
      changes['customerEmail'] = {
        'old_value': oldEmail.isEmpty ? 'Not Set' : oldEmail,
        'new_value': newEmail.isEmpty ? 'Not Set' : newEmail,
      };
    }
  }

  // Track notes change (notes, falling back to legacy description)
  if (newNotes != null) {
    final oldNotesRaw = oldEnquiryData['notes'] as String?;
    final oldNotes = (oldNotesRaw != null && oldNotesRaw.trim().isNotEmpty)
        ? oldNotesRaw.trim()
        : (oldEnquiryData['description'] as String? ?? '').trim();
    final notes = newNotes.trim();
    if (oldNotes != notes) {
      changes['notes'] = {
        'old_value': oldNotes.isEmpty ? 'Not Set' : oldNotes,
        'new_value': notes.isEmpty ? 'Not Set' : notes,
      };
    }
  }

  // Track source change (VALUES)
  if (sourceValue != null) {
    final oldSource = (oldEnquiryData['sourceValue'] ?? oldEnquiryData['source']) as String?;
    if (oldSource != sourceValue) {
      changes['source'] = {'old_value': oldSource ?? 'Not Set', 'new_value': sourceValue};
    }
  }

  // Track quote changes — [quoteFields] holds only the quote fields that differ.
  if (quoteFields != null) {
    if (quoteFields.containsKey('quotedAmount')) {
      changes['quotedAmount'] = {
        'old_value': oldEnquiryData['quotedAmount'] ?? 0,
        'new_value': quoteFields['quotedAmount'] ?? 0,
      };
    }
    if (quoteFields.containsKey('quotedAt')) {
      changes['quotedAt'] = {
        'old_value': oldEnquiryData['quotedAt'] ?? 'Not Set',
        'new_value': quoteFields['quotedAt'] ?? 'Not Set',
      };
    }
  }

  // Track reference images as a count change
  if (oldImageCount != null && newImageCount != null && oldImageCount != newImageCount) {
    changes['images'] = {'old_value': oldImageCount, 'new_value': newImageCount};
  }

  return changes;
}

void _trackText(
  Map<String, Map<String, dynamic>> changes,
  Map<String, dynamic> oldData,
  String field,
  String? newValue,
) {
  if (newValue == null) return;
  final oldValue = (oldData[field] as String? ?? '').trim();
  final value = newValue.trim();
  if (oldValue != value) {
    changes[field] = {
      'old_value': oldValue.isEmpty ? 'Not Set' : oldValue,
      'new_value': value.isEmpty ? 'Not Set' : value,
    };
  }
}

DateTime? _asDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
