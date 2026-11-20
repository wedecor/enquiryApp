import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/contacts/enquiry_whatsapp.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import 'enquiry_round_action.dart';

/// Contact action buttons for calling and messaging customers
///
/// Provides accessible Call and WhatsApp buttons with proper error handling,
/// audit logging, and platform-appropriate fallbacks.
class ContactButtons extends ConsumerWidget {
  const ContactButtons({
    super.key,
    required this.customerPhone,
    required this.customerName,
    this.whatsappPhone,
    this.enquiryId,
    this.enabled = true,
    this.eventType,
    this.eventDate,
    this.firstContact = true,
  });

  /// Voice / dialer number.
  final String? customerPhone;

  /// WhatsApp chat number; falls back to [customerPhone] when null/empty.
  final String? whatsappPhone;
  final String customerName;
  final String? enquiryId;
  final bool enabled;
  final String? eventType;
  final DateTime? eventDate;

  /// No prior app contact → first-touch WhatsApp copy.
  final bool firstContact;

  String? get _waPhone {
    final wa = whatsappPhone?.trim();
    if (wa != null && wa.isNotEmpty) return wa;
    final call = customerPhone?.trim();
    return (call != null && call.isNotEmpty) ? call : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    final contactLauncher = ref.read(contactLauncherProvider);
    final callPhone = customerPhone?.trim();
    final hasCall = callPhone != null && callPhone.isNotEmpty;
    final hasWa = _waPhone != null;

    // Don't show buttons if no phone number — show a subtle hint instead
    if (!hasCall && !hasWa) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: s.glassFill,
          borderRadius: AppRadius.full,
          border: Border.all(color: s.microBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4,
            vertical: AppTokens.space3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: AppTokens.iconSmall,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.space2),
              Flexible(
                child: Text(
                  'Add a phone number to enable Call and WhatsApp actions',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCall)
          EnquiryRoundAction(
            icon: Icons.call_outlined,
            label: 'Call',
            color: AppColorScheme.phoneCall,
            enabled: enabled,
            onTap: () => _handleCall(context, ref, contactLauncher, callPhone),
            semanticLabel: 'Call $customerName',
            semanticHint: 'Opens phone dialer with customer number',
          ),
        if (hasCall && hasWa) const SizedBox(width: AppTokens.space2),
        if (hasWa)
          EnquiryRoundAction(
            icon: Icons.chat,
            label: 'WhatsApp',
            color: AppColorScheme.whatsApp,
            enabled: enabled,
            onTap: () => _handleWhatsApp(context, ref, contactLauncher, _waPhone!),
            semanticLabel: 'Message $customerName on WhatsApp',
            semanticHint: 'Opens WhatsApp chat with customer',
          ),
      ],
    );
  }

  /// Handle call button tap
  Future<void> _handleCall(
    BuildContext context,
    WidgetRef ref,
    ContactLauncher contactLauncher,
    String phone,
  ) async {
    try {
      final status = await contactLauncher.callNumberWithAudit(phone, enquiryId: enquiryId);

      if (!context.mounted) return;

      switch (status) {
        case ContactLaunchStatus.opened:
          // Success - no UI feedback needed
          break;

        case ContactLaunchStatus.invalidNumber:
          _showErrorSnackBar(
            context,
            'Invalid phone number format',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, phone),
          );
          break;

        case ContactLaunchStatus.notInstalled:
          _showErrorSnackBar(
            context,
            'Phone dialer not available on this device',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, phone),
          );
          break;

        case ContactLaunchStatus.failed:
          _showErrorSnackBar(
            context,
            'Could not open phone dialer',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, phone),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error launching phone dialer',
          action: 'Copy Number',
          onAction: () => _copyToClipboard(context, phone),
        );
      }
    }
  }

  /// Handle WhatsApp button tap
  Future<void> _handleWhatsApp(
    BuildContext context,
    WidgetRef ref,
    ContactLauncher contactLauncher,
    String phone,
  ) async {
    try {
      final status = await EnquiryWhatsApp.open(
        launcher: contactLauncher,
        phone: phone,
        customerName: customerName,
        enquiryId: enquiryId,
        eventTypeLabel: eventType,
        eventDate: eventDate,
        firstContact: firstContact,
      );

      if (!context.mounted) return;

      switch (status) {
        case ContactLaunchStatus.opened:
          break;

        case ContactLaunchStatus.invalidNumber:
          _showErrorSnackBar(
            context,
            'Invalid phone number format',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, phone),
          );
          break;

        case ContactLaunchStatus.notInstalled:
          _showErrorSnackBar(
            context,
            'WhatsApp not installed. Opened in browser instead.',
            isError: false,
          );
          break;

        case ContactLaunchStatus.failed:
          _showErrorSnackBar(
            context,
            'Could not open WhatsApp',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, phone),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error launching WhatsApp',
          action: 'Copy Number',
          onAction: () => _copyToClipboard(context, phone),
        );
      }
    }
  }

  /// Show error snackbar with optional action
  void _showErrorSnackBar(
    BuildContext context,
    String message, {
    String? action,
    VoidCallback? onAction,
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        action: action != null && onAction != null
            ? SnackBarAction(
                label: action,
                textColor: isError
                    ? Theme.of(context).colorScheme.onError
                    : Theme.of(context).colorScheme.onPrimary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Copy phone number to clipboard
  Future<void> _copyToClipboard(BuildContext context, String phoneNumber) async {
    try {
      await Clipboard.setData(ClipboardData(text: phoneNumber));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone number copied to clipboard'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to copy phone number'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
