import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/providers/audit_provider.dart';
import '../../../../core/services/contact_log_service.dart';
import '../../../../core/services/firestore_service.dart';

import '../../../../core/services/review_request_service.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../enquiries/data/enquiry_repository.dart';
import '../../../enquiries/domain/enquiry.dart';
import '../../../enquiries/presentation/screens/enquiry_details_screen.dart';

import '../../../enquiries/presentation/widgets/lost_reason_sheet.dart';
import '../../../enquiries/presentation/widgets/review_request_button.dart';
import '../../../reengagement/presentation/occasion_card_share.dart';
import '../../../reengagement/presentation/wish_card.dart';
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

  bool _reviewRequestBusy = false;

  Future<void> handleReviewRequest(
    String phone,
    String customerName,
    String enquiryId, {
    String? eventTypeLabel,
    String phoneNormalized = '',
  }) async {
    if (_reviewRequestBusy) return;
    _reviewRequestBusy = true;
    try {
      final reviewService = ref.read(reviewRequestServiceProvider);
      final launcher = ref.read(contactLauncherProvider);
      final contactLog = ref.read(contactLogServiceProvider);

      // Prefer loaded config; fall back to service defaults while config streams in.
      final appConfig = ref.read(appGeneralConfigProvider).valueOrNull;
      final googleReviewLink = (appConfig != null && appConfig.googleReviewLink.isNotEmpty)
          ? appConfig.googleReviewLink
          : null;
      final businessName = (appConfig != null && appConfig.companyName.isNotEmpty)
          ? appConfig.companyName
          : null;

      final previouslySentAt = await contactLog.latestAt(
        enquiryId: enquiryId,
        type: ContactType.reviewRequest,
      );
      if (!mounted) return;
      if (previouslySentAt != null) {
        final confirmed = await ConfirmationDialog.show(
          context: context,
          title: 'Send again?',
          message: ReviewRequestButton.alreadySentMessage(previouslySentAt),
          confirmText: 'Send again',
          icon: Icons.star_rate_rounded,
        );
        if (!confirmed || !mounted) return;
      }

      final text = reviewService.generateReviewMessage(
        customerName: customerName,
        eventTypeLabel: eventTypeLabel,
        googleReviewLink: googleReviewLink,
        businessName: businessName,
      );

      final result = await OccasionCardShare.share(
        context: context,
        launcher: launcher,
        content: WishCardContent.thankYou(
          customerName: customerName,
          eventTypeLabel: eventTypeLabel,
        ),
        text: text,
        customerPhone: phone,
        phoneNormalized: phoneNormalized,
        customerName: customerName,
        enquiryId: enquiryId,
        contactType: ContactType.reviewRequest,
        imageFileName: 'we-decor-thank-you.png',
        cardAttachFailedMessage: "Couldn't attach the thank-you card — sending text only",
      );

      if (!mounted || result != OccasionShareResult.sent) return;
      showSnack('Thank-you marked sent to $customerName');
    } catch (e) {
      if (mounted) {
        showSnack('Error sending thank-you: $e');
      }
    } finally {
      _reviewRequestBusy = false;
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

    final firestoreService = ref.read(firestoreServiceProvider);
    final auditService = ref.read(auditServiceProvider);
    final newNotes = result.trim();
    final oldNotes = enquiry.notes?.trim() ?? '';
    try {
      // Re-read so the search index is rebuilt from the current name/phone/email.
      final current = await firestoreService.getEnquiry(enquiry.id) ?? const <String, dynamic>{};
      final customerName = (current['customerName'] as String?) ?? enquiry.customerName;
      final customerPhone = (current['customerPhone'] as String?) ?? enquiry.customerPhone;
      final customerEmail = (current['customerEmail'] as String?) ?? enquiry.customerEmail;
      final emailOrNull = (customerEmail?.trim().isNotEmpty ?? false)
          ? customerEmail!.trim()
          : null;
      final indexFields = FirestoreService.searchIndexFieldsFor(
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: emailOrNull,
        notes: newNotes,
      );

      if (newNotes.isEmpty) {
        await firestoreService.updateEnquiry(enquiry.id, {
          'notes': FieldValue.delete(),
          'description': FieldValue.delete(),
          ...indexFields,
        });
      } else {
        await firestoreService.updateEnquiry(enquiry.id, {
          'notes': newNotes,
          'description': newNotes,
          ...indexFields,
        });
      }

      if (oldNotes != newNotes) {
        // Non-fatal: logs (does not throw) if the history entry can't be written.
        await auditService.recordChange(
          enquiryId: enquiry.id,
          fieldChanged: 'notes',
          oldValue: oldNotes.isEmpty ? 'Not Set' : oldNotes,
          newValue: newNotes.isEmpty ? 'Not Set' : newNotes,
        );
      }
      showSnack(newNotes.isEmpty ? 'Notes cleared' : 'Notes updated');
    } catch (e) {
      Log.e('Failed to update notes', error: e);
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

  /// Follow-up WhatsApp from the Follow Up tab. Logs contact; the row stays on
  /// the list for the day and shows as done via [isFollowUpContactedToday].
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

    final launcher = ref.read(contactLauncherProvider);
    final prefill = buildReminderMessage(customerName, eventType, createdAt, eventDate);
    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: prefill,
      enquiryId: enquiryId,
      contactType: ContactType.reminder,
    );

    if (status == ContactLaunchStatus.opened) {
      final firestore = ref.read(firestoreServiceProvider);
      try {
        await firestore.updateEnquiry(enquiryId, {
          'reminderClickCount': FieldValue.increment(1),
          'lastReminderSentAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        Log.e('Failed to stamp follow-up WhatsApp', error: e);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Follow-up sent to $customerName')));
      return;
    }

    switch (status) {
      case ContactLaunchStatus.opened:
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
