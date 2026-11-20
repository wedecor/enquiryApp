import 'package:flutter/material.dart';

import '../../ui/primitives/primitives.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Glass bottom sheet: pick WhatsApp or WhatsApp Business.
///
/// Returns the Android package name, or null if cancelled.
Future<String?> showWhatsAppPackageSheet(
  BuildContext context, {
  required List<String> packages,
  String? preferredPackage,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) => _WhatsAppPackageSheet(packages: packages, preferredPackage: preferredPackage),
  );
}

class _WhatsAppPackageSheet extends StatelessWidget {
  const _WhatsAppPackageSheet({required this.packages, this.preferredPackage});

  final List<String> packages;
  final String? preferredPackage;

  static String _label(String pkg) => switch (pkg) {
    'com.whatsapp.w4b' => 'WhatsApp Business',
    _ => 'WhatsApp',
  };

  static String _subtitle(String pkg) => switch (pkg) {
    'com.whatsapp.w4b' => 'Business chats and catalogue',
    _ => 'Personal WhatsApp',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    const tint = AppColorScheme.whatsApp;

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
                const Eyebrow('Send with', accent: true),
                const SizedBox(height: AppTokens.space1),
                Text(
                  'Choose WhatsApp',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.space5),
                for (var i = 0; i < packages.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppTokens.space3),
                  StaggerIn(
                    index: i,
                    child: _PackageTile(
                      label: _label(packages[i]),
                      subtitle: _subtitle(packages[i]),
                      tint: tint,
                      selected: packages[i] == preferredPackage,
                      onTap: () => Navigator.pop(context, packages[i]),
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.space3),
                Pressable(
                  onTap: () => Navigator.pop(context),
                  borderRadius: AppRadius.large,
                  child: Container(
                    height: AppTokens.minTapTarget + 4,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.large,
                      border: Border.all(color: s.microBorder),
                    ),
                    child: Text(
                      'Cancel',
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

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.label,
    required this.subtitle,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.large,
      pressedScale: 0.98,
      semanticLabel: label,
      child: GlassPanel(
        borderRadius: AppRadius.large,
        tint: tint.withValues(alpha: selected ? 0.12 : 0.06),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space4,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.14),
                border: Border.all(color: tint.withValues(alpha: 0.28)),
              ),
              child: Icon(Icons.chat_bubble_outline, size: 22, color: tint),
            ),
            const SizedBox(width: AppTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: tint, size: 22)
            else
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
