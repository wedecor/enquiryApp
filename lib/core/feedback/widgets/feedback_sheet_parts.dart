import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../ui/primitives/primitives.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// Frosted bottom-sheet surface with a grab handle and a top edge highlight.
class FeedbackGlassSheet extends StatelessWidget {
  const FeedbackGlassSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    const radius = BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXXLarge));
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(s.glassFillStrong, cs.surface.withValues(alpha: 0.82)),
            borderRadius: radius,
            border: Border(top: BorderSide(color: s.edgeHighlight)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.space3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: s.microBorderStrong,
                    borderRadius: AppRadius.full,
                  ),
                  child: const SizedBox(width: 40, height: 4),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet header: tinted icon, eyebrow, heavy title and a round close button.
class FeedbackSheetHeader extends StatelessWidget {
  const FeedbackSheetHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space4,
        AppTokens.space3,
        AppTokens.space2,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.accent.withValues(alpha: 0.14),
              border: Border.all(color: s.accent.withValues(alpha: 0.3)),
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Icon(Icons.feedback_outlined, size: 20, color: s.accentInk),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Help us improve', accent: true),
                Text(
                  'Send Feedback',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// Monospace device-info preview in a glass well.
class FeedbackDevicePreview extends StatelessWidget {
  const FeedbackDevicePreview({super.key, required this.deviceInfo});

  final String deviceInfo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassPanel(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Information (Preview)',
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(deviceInfo, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

/// Accent-tinted privacy reassurance note.
class FeedbackPrivacyNote extends StatelessWidget {
  const FeedbackPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    return GlassPanel(
      tint: s.accent.withValues(alpha: 0.08),
      borderColor: s.accent.withValues(alpha: 0.24),
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: s.accentInk, size: 20),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              'No personal information is collected. Device info helps us reproduce and fix issues.',
              style: t.bodySmall?.copyWith(fontWeight: FontWeight.w300, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
