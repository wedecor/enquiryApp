import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/brand_mark.dart';
import '../../../../ui/primitives/primitives.dart';
import 'auth_backdrop.dart';

/// Centered auth-state layout (unprovisioned, disabled, error, completed):
/// brand mark, a glass card with a tinted icon, eyebrow, heavy title,
/// message and optional detail block, followed by full-width actions.
class AuthStatusView extends StatelessWidget {
  const AuthStatusView({
    super.key,
    required this.icon,
    required this.tone,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.details = const [],
    this.actions = const [],
  });

  final IconData icon;
  final Color tone;
  final String eyebrow;
  final String title;
  final String message;
  final List<Widget> details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return AuthBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.space6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StaggerIn(
                      index: 0,
                      child: Center(child: BrandMark(size: 40, showSubtitle: true)),
                    ),
                    const SizedBox(height: AppTokens.space6),
                    StaggerIn(
                      index: 1,
                      child: GlassPanel(
                        blur: true,
                        strong: true,
                        shadow: true,
                        borderRadius: AppRadius.xLarge,
                        padding: const EdgeInsets.all(AppTokens.space6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tone.withValues(alpha: 0.12),
                                border: Border.all(color: tone.withValues(alpha: 0.3)),
                              ),
                              child: SizedBox.square(
                                dimension: 56,
                                child: Icon(icon, size: 28, color: tone),
                              ),
                            ),
                            const SizedBox(height: AppTokens.space4),
                            Eyebrow(eyebrow, color: tone),
                            const SizedBox(height: AppTokens.space1),
                            Text(
                              title,
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: AppTokens.space3),
                            Text(
                              message,
                              style: t.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w300,
                                color: cs.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            for (final d in details) ...[
                              const SizedBox(height: AppTokens.space4),
                              d,
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.space5),
                      StaggerIn(
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppTokens.space3),
                              actions[i],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinted note inside an [AuthStatusView] card.
class AuthInfoBlock extends StatelessWidget {
  const AuthInfoBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: AppRadius.medium,
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: tone),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            Text(body, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w300, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

/// Glass outlined pill used for secondary auth actions.
class AuthOutlinedPill extends StatelessWidget {
  const AuthOutlinedPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSurface;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        foregroundColor: fg,
        backgroundColor: s.glassFill,
        side: BorderSide(color: color?.withValues(alpha: 0.4) ?? s.microBorderStrong),
      ),
    );
  }
}
