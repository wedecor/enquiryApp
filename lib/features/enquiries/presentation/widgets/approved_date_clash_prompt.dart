import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../data/booking_clash_service.dart';

/// Warns when other APPROVED events already fall on the booking's days.
///
/// Pass the booking's single [eventDate] and/or every function day in [eventDates]
/// (multi-function bookings: all function dates when approving; only new or moved
/// dates when editing an approved booking). Approved FUNCTIONS of other bookings are
/// counted per day, and one dialog summarises every clashing day.
///
/// Call it before approving ([isDateChange] false) or before saving new dates on an
/// approved booking ([isDateChange] true). Returns true to go ahead: also when there's
/// no clash or the lookup failed — errors never block the change. Returns false only
/// when the user chose Cancel (or the context went away).
Future<bool> confirmApprovedDateClash(
  BuildContext context,
  WidgetRef ref, {
  DateTime? eventDate,
  List<DateTime> eventDates = const [],
  String? excludeEnquiryId,
  required bool isDateChange,
}) async {
  final decision = await approvedDateClashDecision(
    context,
    ref,
    eventDate: eventDate,
    eventDates: eventDates,
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
  DateTime? eventDate,
  List<DateTime> eventDates = const [],
  String? excludeEnquiryId,
  required bool isDateChange,
}) async {
  final days = distinctBookingDays([if (eventDate != null) eventDate, ...eventDates]);
  if (days.isEmpty) return (proceed: true, shown: false);
  final clashes = await ref
      .read(bookingClashServiceProvider)
      .approvedOnDatesOrNull(days, excludeEnquiryId: excludeEnquiryId);
  if (clashes == null || !clashes.any((c) => c.hasClash)) {
    return (proceed: true, shown: false);
  }
  if (!context.mounted) return (proceed: false, shown: false);
  final proceed = await ConfirmationDialog.show(
    context: context,
    title: 'Date already booked',
    message: approvedDatesClashMessage(clashes: clashes, isDateChange: isDateChange),
    confirmText: isDateChange ? 'Save anyway' : 'Approve anyway',
    cancelText: 'Cancel',
    icon: Icons.event_busy_outlined,
  );
  return (proceed: proceed, shown: true);
}
