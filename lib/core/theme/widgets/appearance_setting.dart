import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/primitives/primitives.dart';
import '../app_theme.dart';
import '../appearance_controller.dart';
import '../tokens.dart';

/// Appearance setting widget for selecting light/dark/system theme
///
/// Three pressable miniature previews with an animated selection ring; the
/// choice applies immediately and persists across app restarts.
class AppearanceSetting extends ConsumerWidget {
  const AppearanceSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appearanceControllerProvider);
    final theme = Theme.of(context);

    void onChanged(AppearanceMode? m) {
      if (m != null) {
        ref.read(appearanceControllerProvider.notifier).set(m);
      }
    }

    return GlassPanel(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Theme', accent: true),
          const SizedBox(height: AppTokens.space1),
          Text(
            'Appearance',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Choose how the app looks on your device',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, option) in _options.indexed) ...[
                if (i > 0) const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: _AppearanceSwatch(
                    option: option,
                    selected: mode == option.mode,
                    onTap: () => onChanged(option.mode),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              Icon(
                _getModeIcon(mode),
                size: AppTokens.iconSmall,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.standard),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Text(
                    _getModeDescription(mode),
                    key: ValueKey(mode),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _options = [
    _AppearanceOption(AppearanceMode.light, 'Light', 'Always use light theme'),
    _AppearanceOption(AppearanceMode.dark, 'Dark', 'Always use dark theme'),
    _AppearanceOption(AppearanceMode.system, 'System', 'Follow system setting'),
  ];

  IconData _getModeIcon(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.system:
        return Icons.brightness_auto;
      case AppearanceMode.light:
        return Icons.light_mode;
      case AppearanceMode.dark:
        return Icons.dark_mode;
    }
  }

  String _getModeDescription(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.system:
        return 'Theme changes automatically based on your device settings';
      case AppearanceMode.light:
        return 'App will always use the light theme';
      case AppearanceMode.dark:
        return 'App will always use the dark theme';
    }
  }
}

class _AppearanceOption {
  const _AppearanceOption(this.mode, this.label, this.tooltip);

  final AppearanceMode mode;
  final String label;
  final String tooltip;
}

class _AppearanceSwatch extends StatelessWidget {
  const _AppearanceSwatch({required this.option, required this.selected, required this.onTap});

  final _AppearanceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final duration = AppMotion.of(context, AppMotion.standard);

    return Tooltip(
      message: option.tooltip,
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Pressable(
          onTap: onTap,
          borderRadius: AppRadius.large,
          pressedScale: 0.95,
          semanticLabel: option.label,
          child: Column(
            children: [
              AnimatedContainer(
                duration: duration,
                curve: AppMotion.standardCurve,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(
                    color: selected ? s.accent : s.microBorderStrong,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected ? AppShadows.glow(s.accent, strength: 0.22) : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge - 5),
                  child: AspectRatio(
                    aspectRatio: 0.82,
                    child: CustomPaint(painter: _ThemePreviewPainter(option.mode)),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: duration,
                      curve: AppMotion.springOut,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.check_rounded, size: 12, color: cs.surface),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelLarge?.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniature of the app chrome (ground, aurora, glass card, ink pill) in the
/// light or dark palette; "system" splits the two along a diagonal.
class _ThemePreviewPainter extends CustomPainter {
  const _ThemePreviewPainter(this.mode);

  final AppearanceMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final light = (AppSurfaces.light, AppColorScheme.light.onSurface);
    final dark = (AppSurfaces.dark, AppColorScheme.dark.onSurface);
    switch (mode) {
      case AppearanceMode.light:
        _paintScene(canvas, size, light.$1, light.$2);
      case AppearanceMode.dark:
        _paintScene(canvas, size, dark.$1, dark.$2);
      case AppearanceMode.system:
        _paintScene(canvas, size, light.$1, light.$2);
        canvas.save();
        canvas.clipPath(
          Path()
            ..moveTo(size.width, 0)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close(),
        );
        _paintScene(canvas, size, dark.$1, dark.$2);
        canvas.restore();
    }
  }

  void _paintScene(Canvas canvas, Size size, AppSurfaces s, Color ink) {
    final rect = Offset.zero & size;
    final u = size.width / 10;
    canvas.drawRect(rect, Paint()..shader = s.ground.createShader(rect));

    final blobCenter = Offset(size.width * 0.9, size.height * 0.08);
    final blobRadius = size.width * 0.7;
    canvas.drawCircle(
      blobCenter,
      blobRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [s.aurora.first, s.aurora.first.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: blobCenter, radius: blobRadius)),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(u, u * 1.2, u * 3.8, u * 0.75), Radius.circular(u)),
      Paint()..color = ink.withValues(alpha: 0.85),
    );
    canvas.drawCircle(Offset(size.width - u * 1.6, u * 1.55), u * 0.5, Paint()..color = s.accent);

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(u, u * 2.8, size.width - u * 2, size.height * 0.4),
      Radius.circular(u * 1.2),
    );
    canvas.drawRRect(card, Paint()..color = s.glassFillStrong);
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = s.microBorderStrong,
    );
    final lineTop = card.top + u * 1.1;
    for (var i = 0; i < 3; i++) {
      final width = (card.width - u * 2) * (i == 0 ? 0.7 : (i == 1 ? 0.95 : 0.5));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(card.left + u, lineTop + i * u * 1.1, width, u * 0.45),
          Radius.circular(u),
        ),
        Paint()..color = ink.withValues(alpha: i == 0 ? 0.7 : 0.22),
      );
    }

    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(u * 2, size.height - u * 2.4, size.width - u * 4, u * 1.3),
      Radius.circular(u),
    );
    canvas.drawRRect(pill, Paint()..shader = s.inkGradient.createShader(pill.outerRect));
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter old) => old.mode != mode;
}
