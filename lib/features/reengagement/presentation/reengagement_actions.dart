import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contacts/contact_launcher.dart';
import '../../../core/logging/logger.dart';
import '../../../core/providers/role_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/reengagement_repository.dart';
import '../domain/occasion_reminder.dart';
import '../domain/reengagement_config.dart';
import '../domain/reengagement_templates.dart';
import 'reengagement_providers.dart';

/// Row actions for a yearly reminder (dashboard section and list screen).
class ReengagementActions {
  ReengagementActions._();

  /// The filled WhatsApp message for [reminder] with the current templates.
  static String messageFor(WidgetRef ref, OccasionReminder reminder) {
    final config = ref.read(reengagementConfigProvider).valueOrNull ?? const ReengagementConfig();
    final business = ref.read(appGeneralConfigProvider).valueOrNull?.companyName;
    return ReengagementTemplates.render(
      config.templateFor(reminder.kind),
      customerName: reminder.customerName,
      nth: reminder.nth,
      date: reminder.occasionDate,
      person: reminder.person,
      eventType: reminder.eventTypeLabel,
      business: business,
    );
  }

  /// Opens WhatsApp with the wish (logged on the enquiry as contact type
  /// `reengagement`), then marks the reminder sent.
  static Future<void> sendWhatsApp(
    BuildContext context,
    WidgetRef ref,
    OccasionReminder reminder,
  ) async {
    final number = reminder.customerPhone;
    if (number == null) {
      _snack(context, 'No phone number for this customer');
      return;
    }
    final status = await ref
        .read(contactLauncherProvider)
        .openWhatsAppWithAudit(
          number,
          prefillText: messageFor(ref, reminder),
          enquiryId: reminder.enquiryId.isEmpty ? null : reminder.enquiryId,
          contactType: ContactType.reengagement,
        );
    if (!context.mounted) return;
    if (status != ContactLaunchStatus.opened) {
      _snack(context, 'Could not open WhatsApp');
      return;
    }
    await markSent(context, ref, reminder, quiet: true);
  }

  /// "Mark sent": the wish went out some other way.
  static Future<void> markSent(
    BuildContext context,
    WidgetRef ref,
    OccasionReminder reminder, {
    bool quiet = false,
  }) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    try {
      await ref.read(reengagementRepositoryProvider).markSent(reminder.id, uid);
      if (!quiet && context.mounted) _snack(context, 'Marked as sent');
    } catch (e) {
      Log.w('Reminder markSent failed', data: {'error': e.toString()});
      if (context.mounted) _snack(context, 'Could not update the reminder');
    }
  }

  /// "Skip": not this year.
  static Future<void> skip(BuildContext context, WidgetRef ref, OccasionReminder reminder) async {
    try {
      await ref.read(reengagementRepositoryProvider).skip(reminder.id);
      if (context.mounted) _snack(context, 'Skipped for this year');
    } catch (e) {
      Log.w('Reminder skip failed', data: {'error': e.toString()});
      if (context.mounted) _snack(context, 'Could not update the reminder');
    }
  }

  /// "Don't remind again": opts the customer out and skips this reminder.
  static Future<void> dontRemindAgain(
    BuildContext context,
    WidgetRef ref,
    OccasionReminder reminder,
  ) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Stop yearly reminders?',
      message: "We won't remind the team about ${reminder.customerName} again.",
      confirmText: "Don't remind",
      cancelText: 'Cancel',
      icon: Icons.notifications_off_outlined,
    );
    if (!confirmed || !context.mounted) return;
    final repo = ref.read(reengagementRepositoryProvider);
    try {
      if (reminder.phoneNormalized.isNotEmpty) {
        await repo.setNoReminders(reminder.phoneNormalized, value: true, uid: uid);
      }
      await repo.skip(reminder.id, reason: OccasionReminder.skipReasonOptOut);
      if (context.mounted) _snack(context, 'Reminders turned off for ${reminder.customerName}');
    } catch (e) {
      Log.w('Reminder opt-out failed', data: {'error': e.toString()});
      if (context.mounted) _snack(context, 'Could not update the reminder');
    }
  }

  /// Staff can open only enquiries assigned to them (rules); admins can open any.
  static bool canOpenEnquiry(WidgetRef ref, OccasionReminder reminder) {
    if (reminder.enquiryId.isEmpty) return false;
    if (ref.read(roleProvider).valueOrNull == UserRole.admin) return true;
    final uid = ref.read(currentUserUidProvider);
    return uid != null && reminder.assignedTo == uid;
  }

  static void openEnquiry(BuildContext context, OccasionReminder reminder) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => EnquiryDetailsScreen(enquiryId: reminder.enquiryId)),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
