import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/review_request_service.dart';
import '../../../enquiries/data/enquiry_repository.dart';
import '../../../enquiries/domain/enquiry.dart';
import '../../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../../enquiries/presentation/widgets/lost_reason_sheet.dart';
import '../../../settings/providers/settings_providers.dart';
import 'dashboard_action_sheets.dart';
import 'dashboard_enquiry_tab_actions.dart';
import 'dashboard_enquiry_utils.dart';

/// Row-level enquiry actions (call, WhatsApp, status, notes…) for the dashboard.
mixin DashboardActionHandlers<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  DashboardEnquiryTabActions buildTabActions() => DashboardEnquiryTabActions(
    onView: openEnquiryDetails,
    onCall: handleCall,
    onWhatsApp: handleWhatsApp,
    onReminderWhatsApp: handleReminderWhatsApp,
    onUpdateStatus: showUpdateStatusSheet,
    onShare: shareEnquiry,
    onAddNote: showNotesSheet,
    onReviewRequest: handleReviewRequest,
    onMarkNotInterested: markAsNotInterested,
  );

  Future<void> handleCall(String? phone, String customerName, String enquiryId) async {
    if (phone == null || phone.trim().isEmpty) {
      showSnack('No phone number available for $customerName');
      return;
    }

    final launcher = ref.read(contactLauncherProvider);
    final status = await launcher.callNumberWithAudit(phone, enquiryId: enquiryId);

    switch (status) {
      case ContactLaunchStatus.opened:
        showSnack('Dialer opened for $customerName');
        break;
      case ContactLaunchStatus.invalidNumber:
        showSnack('Invalid phone number for $customerName');
        break;
      case ContactLaunchStatus.notInstalled:
        showSnack('Phone dialer not available on this device');
        break;
      case ContactLaunchStatus.failed:
        showSnack('Unable to start call to $customerName');
        break;
    }
  }

  Future<void> handleWhatsApp(String? phone, String customerName, String enquiryId) async {
    if (phone == null || phone.trim().isEmpty) {
      showSnack('No phone number available for WhatsApp');
      return;
    }

    final launcher = ref.read(contactLauncherProvider);
    final prefill = 'Hi $customerName, this is from We Decor.';
    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: prefill,
      enquiryId: enquiryId,
    );

    switch (status) {
      case ContactLaunchStatus.opened:
        showSnack('WhatsApp opened for $customerName');
        break;
      case ContactLaunchStatus.invalidNumber:
        showSnack('Invalid WhatsApp number');
        break;
      case ContactLaunchStatus.notInstalled:
        showSnack('WhatsApp is not installed on this device');
        break;
      case ContactLaunchStatus.failed:
        showSnack('Unable to launch WhatsApp');
        break;
    }
  }

  Future<void> handleReviewRequest(String phone, String customerName, String enquiryId) async {
    try {
      final reviewService = ref.read(reviewRequestServiceProvider);
      final appConfigAsync = ref.read(appGeneralConfigProvider);

      final appConfig = appConfigAsync.valueOrNull;
      if (appConfig == null) {
        showSnack('Error loading app configuration');
        return;
      }

      final googleReviewLink = appConfig.googleReviewLink.isNotEmpty
          ? appConfig.googleReviewLink
          : null;
      final instagramHandle = appConfig.instagramHandle.isNotEmpty
          ? appConfig.instagramHandle
          : null;
      final websiteUrl = appConfig.websiteUrl.isNotEmpty ? appConfig.websiteUrl : null;

      final status = await reviewService.sendReviewRequest(
        customerPhone: phone,
        customerName: customerName,
        googleReviewLink: googleReviewLink,
        instagramHandle: instagramHandle,
        websiteUrl: websiteUrl,
        enquiryId: enquiryId,
      );

      if (!mounted) return;

      switch (status) {
        case ContactLaunchStatus.opened:
          showSnack('Review request sent to $customerName');
          break;
        case ContactLaunchStatus.invalidNumber:
          showSnack('Invalid phone number for review request');
          break;
        case ContactLaunchStatus.notInstalled:
          showSnack('WhatsApp not installed. Opened in browser instead.');
          break;
        case ContactLaunchStatus.failed:
          showSnack('Could not send review request');
          break;
      }
    } catch (e) {
      if (mounted) {
        showSnack('Error sending review request: $e');
      }
    }
  }

  /// Mark enquiry as "not_interested" (for past events in In Talks tab)
  Future<void> markAsNotInterested(String enquiryId, String userId) async {
    try {
      final repository = ref.read(enquiryRepositoryProvider);

      // The reason sheet doubles as the confirmation step.
      final lostPrompt = await promptLostReasonIfNeeded(context, 'not_interested');
      if (!lostPrompt.proceed || !mounted) return;

      await repository.updateStatus(
        id: enquiryId,
        nextStatus: 'not_interested',
        userId: userId,
        lostReason: lostPrompt.choice,
      );

      if (mounted) {
        showSnack('Enquiry marked as Not Interested');
      }
    } catch (e) {
      if (mounted) {
        showSnack('Failed to update status: $e');
      }
    }
  }

  Future<void> showUpdateStatusSheet(Enquiry enquiry) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => UpdateStatusSheet(enquiry: enquiry),
    );
  }

  Future<void> shareEnquiry(Enquiry enquiry) async {
    final buffer = StringBuffer()
      ..writeln('Enquiry: ${enquiry.customerName}')
      ..writeln('Event: ${enquiry.eventTypeDisplay}')
      ..writeln('Status: ${enquiry.statusDisplay}')
      ..writeln('Event date: ${formatDateLabel(enquiry.eventDate)}')
      ..writeln('Assigned to: ${enquiry.assigneeName ?? 'Unassigned'}')
      ..writeln('Phone: ${enquiry.customerPhone ?? 'N/A'}')
      ..writeln(
        'Notes: ${enquiry.notes?.trim().isNotEmpty == true ? enquiry.notes!.trim() : 'N/A'}',
      );

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      showSnack('Enquiry details copied to clipboard');
    }
  }

  Future<void> showNotesSheet(Enquiry enquiry) async {
    if (!mounted) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FollowUpNotesSheet(initialNotes: enquiry.notes),
    );

    if (!mounted || result == null) return;

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      if (result.isEmpty) {
        await firestoreService.updateEnquiry(enquiry.id, {
          'notes': FieldValue.delete(),
          'description': FieldValue.delete(),
        });
        showSnack('Notes cleared');
      } else {
        await firestoreService.updateEnquiry(enquiry.id, {'notes': result, 'description': result});
        showSnack('Notes updated');
      }
    } catch (e) {
      showSnack('Failed to update notes');
    }
  }

  void openEnquiryDetails(String enquiryId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId)),
    );
  }

  void showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Handle reminder WhatsApp click - increments count and opens WhatsApp
  Future<void> handleReminderWhatsApp(
    String phone,
    String customerName,
    String enquiryId,
    String eventType,
    DateTime createdAt,
    DateTime? eventDate,
  ) async {
    if (phone.trim().isEmpty) {
      showSnack('No phone number available for WhatsApp');
      return;
    }

    try {
      await ref.read(firestoreServiceProvider).updateEnquiry(enquiryId, {
        'reminderClickCount': FieldValue.increment(1),
        'lastReminderSentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Log.e('Failed to increment reminder count', error: e);
      // Continue even if count update fails
    }

    final launcher = ref.read(contactLauncherProvider);
    final prefill = buildReminderMessage(customerName, eventType, createdAt, eventDate);
    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: prefill,
      enquiryId: enquiryId,
      contactType: ContactType.reminder,
    );

    switch (status) {
      case ContactLaunchStatus.opened:
        showSnack('Reminder sent to $customerName via WhatsApp');
        break;
      case ContactLaunchStatus.invalidNumber:
        showSnack('Invalid WhatsApp number');
        break;
      case ContactLaunchStatus.notInstalled:
        showSnack('WhatsApp is not installed on this device');
        break;
      case ContactLaunchStatus.failed:
        showSnack('Unable to launch WhatsApp');
        break;
    }
  }
}
