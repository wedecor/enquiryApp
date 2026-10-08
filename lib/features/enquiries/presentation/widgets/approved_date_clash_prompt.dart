import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../data/booking_clash_service.dart';

/// Warns when other APPROVED enquiries already fall on [eventDate].
///
/// Call it before approving an enquiry ([isDateChange] false) or before saving a new
/// event date on an approved one ([isDateChange] true). Returns true to go ahead:
/// also when there's no clash or the lookup failed — errors never block the change.
/// Returns false only when the user chose Cancel (or the context went away).
Future<bool> confirmApprovedDateClash(
  BuildContext context,
  WidgetRef ref, {
  required DateTime eventDate,
  String? excludeEnquiryId,
  required bool isDateChange,
}) async {
  final decision = await approvedDateClashDecision(
    context,
    ref,
    eventDate: eventDate,
    excludeEnquiryId: excludeEnquiryId,
    isDateChange: isDateChange,
  );
  return decision.proceed;
}

/// Like [confirmApprovedDateClash], but also reports whether the warning was
/// shown, so callers can skip a second generic confirmation.
Future<({bool proceed, bool shown})> approvedDateClashDecision(
  BuildContext context,
  WidgetRef ref, {
  required DateTime eventDate,
  String? excludeEnquiryId,
  required bool isDateChange,
}) async {
  final result = await ref
      .read(bookingClashServiceProvider)
      .approvedOnDateOrNull(eventDate, excludeEnquiryId: excludeEnquiryId);
  if (result == null || !result.hasClash) return (proceed: true, shown: false);
  if (!context.mounted) return (proceed: false, shown: false);
  final proceed = await ConfirmationDialog.show(
    context: context,
    title: 'Date already booked',
    message: approvedDateClashMessage(
      date: eventDate,
      count: result.count,
      areas: [for (final e in result.events) e.area],
      isDateChange: isDateChange,
    ),
    confirmText: isDateChange ? 'Move anyway' : 'Approve anyway',
    cancelText: 'Cancel',
    icon: Icons.event_busy_outlined,
  );
  return (proceed: proceed, shown: true);
}
