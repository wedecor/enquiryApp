import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../ui/components/brand_mark.dart';
import '../../ui/primitives/primitives.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// One primary destination in [AppShell].
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.eyebrow,
    required this.icon,
    required this.selectedIcon,
    required this.body,
  });

  final String label;

  /// Tracked micro-label shown above the title in the top bar.
  final String eyebrow;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;
}

/// Frosted top bar: brand seal, eyebrow + heavy title (cross-fades between
/// destinations) and round glass actions.
class ShellTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellTopBar({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.actions,
    this.showBrand = true,
  });

  final String eyebrow;
  final String title;
  final List<Widget> actions;
  final bool showBrand;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.glassFill,
            border: Border(bottom: BorderSide(color: s.microBorder)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppTokens.space5, topInset, AppTokens.space4, 0),
            child: SizedBox(
              height: preferredSize.height,
              child: Row(
                children: [
                  if (showBrand) ...[
                    const BrandMark(compact: true, size: 26),
                    const SizedBox(width: AppTokens.space3),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.standard),
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exit,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, if (current != null) current],
                      ),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(title),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(eyebrow, accent: true),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round glass icon button with an optional gold count badge.
class ShellIconButton extends StatelessWidget {
  const ShellIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.9,
        borderRadius: AppRadius.full,
        semanticLabel: tooltip,
        child: SizedBox.square(
          dimension: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.glassFillStrong,
              border: Border.all(color: s.microBorder),
            ),
            child: Center(
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                child: Icon(icon, size: 20, color: cs.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating glass pill navigation for phones, with a sliding ink indicator.
class ShellNavPill extends StatelessWidget {
  const ShellNavPill({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _height = 66;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final duration = AppMotion.of(context, AppMotion.gentle);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        bottomInset + AppTokens.space3,
      ),
      child: GlassPanel(
        blur: true,
        strong: true,
        shadow: true,
        borderRadius: AppRadius.full,
        child: SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (context, box) {
              final itemWidth = box.maxWidth / destinations.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: AppMotion.springOut,
                    left: itemWidth * selectedIndex + 6,
                    top: 6,
                    bottom: 6,
                    width: itemWidth - 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: s.inkGradient,
                        borderRadius: AppRadius.full,
                        boxShadow: AppShadows.glow(s.shadow, strength: 0.18),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        SizedBox(
                          width: itemWidth,
                          child: _PillItem(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            onTap: () => onSelected(i),
                            selectedColor: cs.onPrimary,
                            idleColor: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.idleColor,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = selected ? selectedColor : idleColor;
    final duration = AppMotion.of(context, AppMotion.standard);
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.9,
        splash: false,
        borderRadius: AppRadius.full,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: duration,
              curve: AppMotion.springOut,
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: (t.labelSmall ?? const TextStyle()).copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: selected ? 0.2 : 0.1,
              ),
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass side rail for tablets/desktop. [extended] adds labels and the wordmark.
class ShellRail extends StatelessWidget {
  const ShellRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.extended,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final width = extended ? 232.0 : 88.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space3, AppTokens.space3, 0, AppTokens.space3),
      child: GlassPanel(
        blur: true,
        strong: true,
        borderRadius: AppRadius.xLarge,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: extended ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  AppTokens.space5,
                  AppTokens.space4,
                  AppTokens.space6,
                ),
                child: BrandMark(compact: !extended, showSubtitle: extended, size: 28),
              ),
              for (var i = 0; i < destinations.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: 3),
                  child: _RailItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    extended: extended,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = selected ? cs.onPrimary : cs.onSurfaceVariant;
    final duration = AppMotion.of(context, AppMotion.standard);

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.95,
        splash: false,
        borderRadius: AppRadius.medium,
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.standardCurve,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: extended ? AppTokens.space4 : 0),
          decoration: BoxDecoration(
            gradient: selected ? s.inkGradient : null,
            borderRadius: AppRadius.medium,
          ),
          child: Row(
            mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(selected ? destination.selectedIcon : destination.icon, size: 22, color: color),
              if (extended) ...[
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold-sheen primary action with a soft coloured glow.
class AccentFab extends StatelessWidget {
  const AccentFab({super.key, required this.onTap, required this.tooltip, this.label});

  final VoidCallback onTap;
  final String tooltip;

  /// Shown beside the icon on wide layouts.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    const ink = AppColorScheme.brandCharcoal;
    final t = Theme.of(context).textTheme;

    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.92,
        borderRadius: AppRadius.large,
        semanticLabel: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: s.accentGradient,
            borderRadius: AppRadius.large,
            boxShadow: AppShadows.glow(s.accent, strength: 0.38),
            border: Border.all(color: s.edgeHighlight),
          ),
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 18 : AppTokens.space5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: ink, size: 26),
                  if (label != null) ...[
                    const SizedBox(width: AppTokens.space2),
                    Text(
                      label!,
                      style: t.labelLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
