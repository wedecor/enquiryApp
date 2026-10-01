import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
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
    this.enquiryId,
    this.enabled = true,
    this.eventType,
    this.eventDate,
  });

  final String? customerPhone;
  final String customerName;
  final String? enquiryId;
  final bool enabled;
  final String? eventType;
  final DateTime? eventDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    final contactLauncher = ref.read(contactLauncherProvider);

    // Don't show buttons if no phone number — show a subtle hint instead
    if (customerPhone == null || customerPhone!.trim().isEmpty) {
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
        EnquiryRoundAction(
          icon: Icons.call_outlined,
          label: 'Call',
          color: AppColorScheme.phoneCall,
          enabled: enabled,
          onTap: () => _handleCall(context, ref, contactLauncher),
          semanticLabel: 'Call $customerName',
          semanticHint: 'Opens phone dialer with customer number',
        ),
        const SizedBox(width: AppTokens.space2),
        EnquiryRoundAction(
          icon: Icons.chat,
          label: 'WhatsApp',
          color: AppColorScheme.whatsApp,
          enabled: enabled,
          onTap: () => _handleWhatsApp(context, ref, contactLauncher),
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
  ) async {
    try {
      final status = await contactLauncher.callNumberWithAudit(
        customerPhone!,
        enquiryId: enquiryId,
      );

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
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;

        case ContactLaunchStatus.notInstalled:
          _showErrorSnackBar(
            context,
            'Phone dialer not available on this device',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;

        case ContactLaunchStatus.failed:
          _showErrorSnackBar(
            context,
            'Could not open phone dialer',
            action: 'Copy Number',
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error launching phone dialer',
          action: 'Copy Number',
          onAction: () => _copyToClipboard(context, customerPhone!),
        );
      }
    }
  }

  /// Format date as DD MMM YYYY (e.g., "15 Jan 2026")
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    if (date.year <= 1971) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    return '$day $month $year';
  }

  /// Handle WhatsApp button tap
  Future<void> _handleWhatsApp(
    BuildContext context,
    WidgetRef ref,
    ContactLauncher contactLauncher,
  ) async {
    try {
      // Build message with event type and date if available
      String prefillText;
      if (eventType != null && eventDate != null) {
        final formattedDate = _formatDate(eventDate);
        prefillText =
            'Hi $customerName, I\'m following up on your $eventType enquiry for $formattedDate with We Decor. We\'re excited to help make your special day memorable! How can I help you today?';
      } else if (eventType != null) {
        prefillText =
            'Hi $customerName, I\'m following up on your $eventType enquiry with We Decor. We\'re excited to help make your special day memorable! How can I help you today?';
      } else {
        prefillText =
            'Hi $customerName, I\'m following up on your enquiry with We Decor. How can I help you today?';
      }

      final status = await contactLauncher.openWhatsAppWithAudit(
        customerPhone!,
        prefillText: prefillText,
        enquiryId: enquiryId,
      );

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
            onAction: () => _copyToClipboard(context, customerPhone!),
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
            onAction: () => _copyToClipboard(context, customerPhone!),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error launching WhatsApp',
          action: 'Copy Number',
          onAction: () => _copyToClipboard(context, customerPhone!),
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
