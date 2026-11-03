import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/contacts/contact_launcher.dart';
import '../../../core/logging/logger.dart';
import '../../../core/providers/role_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/reengagement_repository.dart';
import '../domain/occasion_kind.dart';
import '../domain/occasion_reminder.dart';
import '../domain/past_customer_occasion.dart';
import '../domain/reengagement_config.dart';
import '../domain/reengagement_templates.dart';
import 'reengagement_providers.dart';
import 'wish_card.dart';

/// Row actions for a yearly reminder (dashboard section and list screen).
class ReengagementActions {
  ReengagementActions._();

  /// The filled WhatsApp message for [reminder] with the current templates.
  static String messageFor(WidgetRef ref, OccasionReminder reminder) => _render(
    ref,
    kind: reminder.kind,
    customerName: reminder.customerName,
    nth: reminder.nth,
    date: reminder.occasionDate,
    person: reminder.person,
    eventType: reminder.eventTypeLabel,
  );

  /// The filled WhatsApp message for a past-customer row (next occurrence).
  static String messageForPast(WidgetRef ref, PastCustomerRow row) => _render(
    ref,
    kind: row.source.kind,
    customerName: row.source.customerName,
    nth: row.nth,
    date: row.nextDate,
    person: row.source.person,
    eventType: row.source.eventTypeLabel,
  );

  static String _render(
    WidgetRef ref, {
    required OccasionKind kind,
    required String customerName,
    required int nth,
    required DateTime? date,
    required String? person,
    required String eventType,
  }) {
    final config = ref.read(reengagementConfigProvider).valueOrNull ?? const ReengagementConfig();
    final business = ref.read(appGeneralConfigProvider).valueOrNull?.companyName;
    return ReengagementTemplates.render(
      config.templateFor(kind),
      customerName: customerName,
      nth: nth,
      date: date,
      person: person,
      eventType: eventType,
      business: business,
    );
  }

  /// Shares the wish card + wish text through the share sheet (pick WhatsApp, then
  /// the customer's chat). Falls back to opening the chat with the text only when
  /// sharing an image isn't possible (e.g. a desktop browser). Logged on the
  /// enquiry as contact type `reengagement`; marks the reminder sent.
  static Future<void> sendWhatsApp(
    BuildContext context,
    WidgetRef ref,
    OccasionReminder reminder,
  ) async {
    final sent = await _sendWish(
      context,
      ref,
      kind: reminder.kind,
      customerName: reminder.customerName,
      nth: reminder.nth,
      person: reminder.person,
      phone: reminder.customerPhone,
      enquiryId: reminder.enquiryId.isEmpty ? null : reminder.enquiryId,
      text: messageFor(ref, reminder),
    );
    if (!sent || !context.mounted) return;
    await markSent(context, ref, reminder, quiet: true);
  }

  /// Past-customer row: same as [sendWhatsApp]; if this year's reminder doc
  /// exists, marks it sent.
  static Future<void> sendPastWhatsApp(
    BuildContext context,
    WidgetRef ref,
    PastCustomerRow row,
  ) async {
    final sent = await _sendWish(
      context,
      ref,
      kind: row.source.kind,
      customerName: row.source.customerName,
      nth: row.nth,
      person: row.source.person,
      phone: row.source.customerPhone,
      enquiryId: row.source.enquiryId,
      text: messageForPast(ref, row),
    );
    if (!sent || !context.mounted) return;
    final uid = ref.read(currentUserUidProvider);
    if (uid == null || row.source.phoneNormalized.isEmpty) return;
    try {
      await ref.read(reengagementRepositoryProvider).markSentIfExists(row.reminderDocId, uid);
    } catch (e) {
      Log.w('Past-customer reminder markSent failed', data: {'error': e.toString()});
    }
  }

  static const MethodChannel _whatsAppChannel = MethodChannel('wedecor/whatsapp');

  /// Android only: opens [phone]'s WhatsApp chat (WhatsApp Business first) with the
  /// card attached and [text] as the caption (MainActivity.shareImageToChat).
  /// False when WhatsApp isn't installed or the hand-off failed.
  static Future<bool> _shareToChat(Uint8List png, String phone, String text) async {
    try {
      final opened = await _whatsAppChannel.invokeMethod<bool>('shareImageToChat', {
        'png': png,
        'phone': phone,
        'text': text,
      });
      return opened ?? false;
    } on PlatformException catch (e) {
      Log.w('WhatsApp direct share failed', data: {'error': e.message});
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// True when the wish went out (card shared, or WhatsApp opened with the text).
  static Future<bool> _sendWish(
    BuildContext context,
    WidgetRef ref, {
    required OccasionKind kind,
    required String customerName,
    required int nth,
    required String? person,
    required String? phone,
    required String? enquiryId,
    required String text,
  }) async {
    if (phone == null || phone.trim().isEmpty) {
      _snack(context, 'No phone number for this customer');
      return false;
    }
    final launcher = ref.read(contactLauncherProvider);
    // Image sharing works in the Android app and phone browsers; a desktop browser
    // gets the text-only WhatsApp chat.
    final canShareImage =
        !kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (canShareImage) {
      try {
        final png = await WishCardRenderer.renderPng(
          WishCardContent.forOccasion(
            kind: kind,
            customerName: customerName,
            nth: nth,
            person: person,
          ),
        );
        // Android app: straight into this customer's WhatsApp chat, card + text attached.
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          final opened = await _shareToChat(png, launcher.normalize(phone), text);
          if (opened) {
            launcher.recordContact(enquiryId: enquiryId, type: ContactType.reengagement);
            return true;
          }
        }
        if (context.mounted) {
          _snack(
            context,
            'Pick WhatsApp, then ${ReengagementTemplates.firstName(customerName)}\'s chat',
          );
        }
        final result = await Share.shareXFiles([
          XFile.fromData(png, mimeType: 'image/png', name: 'we-decor-wish.png'),
        ], text: text);
        if (result.status == ShareResultStatus.dismissed) return false;
        // success, or `unavailable` (the platform can't report the outcome): the share
        // sheet was shown and the user didn't back out, so count it as sent.
        launcher.recordContact(enquiryId: enquiryId, type: ContactType.reengagement);
        return true;
      } catch (e) {
        Log.w('Wish card share failed; opening WhatsApp with text', data: {'error': e.toString()});
      }
    }

    if (!context.mounted) return false;
    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: text,
      enquiryId: enquiryId,
      contactType: ContactType.reengagement,
    );
    if (!context.mounted) return false;
    if (status != ContactLaunchStatus.opened) {
      _snack(context, 'Could not open WhatsApp');
      return false;
    }
    return true;
  }

  /// Admin "Check now": runs the daily reminder job immediately
  /// (`runReengagementNow`, asia-south1) and refreshes the lists.
  static Future<void> checkNow(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('runReengagementNow').call<dynamic>(<String, dynamic>{});
      final data = result.data;
      final created = data is Map && data['created'] is num ? (data['created'] as num).toInt() : 0;
      final enabled = !(data is Map && data['enabled'] == false);
      if (!context.mounted) return;
      ref.invalidate(upcomingRemindersProvider);
      ref.invalidate(pastCustomerOccasionsProvider);
      if (!enabled) {
        _snack(context, 'Yearly reminders are turned off in settings');
      } else {
        _snack(context, created == 1 ? 'Created 1 reminder' : 'Created $created reminders');
      }
    } on FirebaseFunctionsException catch (e) {
      Log.w('runReengagementNow failed', data: {'code': e.code, 'error': e.message});
      if (context.mounted) _snack(context, e.message ?? 'Could not check reminders');
    } catch (e) {
      Log.w('runReengagementNow failed', data: {'error': e.toString()});
      if (context.mounted) _snack(context, 'Could not check reminders');
    }
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

  static void openEnquiry(BuildContext context, OccasionReminder reminder) =>
      openEnquiryById(context, reminder.enquiryId);

  static void openEnquiryById(BuildContext context, String enquiryId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => EnquiryDetailsScreen(enquiryId: enquiryId)),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
