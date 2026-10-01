/// Pure helpers for the edit-enquiry flow, moved unchanged out of
/// `EnquiryFormScreen._updateEnquiry` so the screen holds layout, not logic.
library;

/// Confirmation text shown before saving a change to total cost / advance paid.
String buildFinancialChangeMessage({
  required num? oldTotalCost,
  required double? newTotalCost,
  required num? oldAdvancePaid,
  required double? newAdvancePaid,
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
}) {
  final changes = <String, Map<String, dynamic>>{};

  // Track status change (store VALUES, not labels)
  // Only use statusValue - standard field
  final oldStatusValue = (oldEnquiryData['statusValue'] as String?) ?? 'new';
  if (oldStatusValue != statusValue) {
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

  return changes;
}
