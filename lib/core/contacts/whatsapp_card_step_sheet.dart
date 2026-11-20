import 'package:flutter/material.dart';

import '../../ui/primitives/primitives.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Glass sheet shown when staff come back from WhatsApp after the message
/// step: "Send the card". Returns true when they tap Send card.
Future<bool> showWhatsAppCardStepSheet(BuildContext context, {String? firstName}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) => _WhatsAppCardStepSheet(firstName: firstName),
  );
  return result ?? false;
}

class _WhatsAppCardStepSheet extends StatelessWidget {
  const _WhatsAppCardStepSheet({this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    const tint = AppColorScheme.whatsApp;
    final name = firstName?.trim() ?? '';
    final who = (name.isEmpty || name == 'there') ? 'the customer' : name;
    final whose = (name.isEmpty || name == 'there') ? "the customer's" : "$name's";

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space2, 0, AppTokens.space2, AppTokens.space2),
      child: GlassPanel(
        blur: true,
        strong: true,
        shadow: true,
        borderRadius: AppRadius.xxLarge,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space3,
              AppTokens.space5,
              AppTokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space5),
                const Eyebrow('Step 2 of 2', accent: true),
                const SizedBox(height: AppTokens.space1),
                Text(
                  'Send the card to $who',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  'Sent the message? Tap below and WhatsApp opens $whose chat with the card ready to send.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: AppTokens.space5),
                Pressable(
                  onTap: () => Navigator.pop(context, true),
                  borderRadius: AppRadius.large,
                  pressedScale: 0.98,
                  semanticLabel: 'Send card',
                  child: Container(
                    height: AppTokens.minTapTarget + 8,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: tint, borderRadius: AppRadius.large),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: AppTokens.space2),
                        Text(
                          'Send card',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                Pressable(
                  onTap: () => Navigator.pop(context, false),
                  borderRadius: AppRadius.large,
                  child: Container(
                    height: AppTokens.minTapTarget + 4,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.large,
                      border: Border.all(color: s.microBorder),
                    ),
                    child: Text(
                      'Skip card',
                      style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
