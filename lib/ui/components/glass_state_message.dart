import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';

/// Centered glass card for empty, error and access-denied states.
class GlassStateMessage extends StatelessWidget {
  const GlassStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.color,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final tone = color ?? cs.onSurfaceVariant;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassPanel(
            padding: const EdgeInsets.all(AppTokens.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: 0.10),
                    border: Border.all(color: tone.withValues(alpha: 0.2)),
                  ),
                  child: SizedBox.square(dimension: 64, child: Icon(icon, size: 30, color: tone)),
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: AppTokens.space5), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Spinner with an optional whisper-weight caption.
class GlassLoadingState extends StatelessWidget {
  const GlassLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.4)),
          if (message != null) ...[
            const SizedBox(height: AppTokens.space4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w300),
            ),
          ],
        ],
      ),
    );
  }
}
