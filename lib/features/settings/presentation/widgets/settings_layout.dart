import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Space the shell's floating nav pill / FAB need under scrollable content.
const double kShellBottomClearance = 96;

/// Scrollable settings tab body: transparent, staggered sections and enough
/// bottom clearance to clear the shell's floating nav pill.
///
/// Children are built eagerly so a wrapping [Form] validates every field,
/// including ones scrolled off-screen.
class SettingsScrollBody extends StatelessWidget {
  const SettingsScrollBody({
    super.key,
    required this.children,
    this.bottomPadding = kShellBottomClearance,
  });

  final List<Widget> children;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space1,
        AppTokens.space4,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) StaggerIn(index: i, child: children[i]),
        ],
      ),
    );
  }
}

/// Section header plus one frosted panel holding a group of rows, separated
/// by inset hairlines instead of cards and dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.separated = true,
    this.dividerIndent = 66,
    this.padding,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  /// Hairlines between [children]; turn off for free-form content (forms).
  final bool separated;
  final double dividerIndent;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          eyebrow: eyebrow,
          trailing: trailing,
          padding: EdgeInsets.fromLTRB(
            AppTokens.space1,
            AppTokens.space6,
            AppTokens.space1,
            subtitle == null ? AppTokens.space3 : AppTokens.space1,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space1,
              0,
              AppTokens.space1,
              AppTokens.space3,
            ),
            child: Text(
              subtitle!,
              style: t.bodySmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        GlassPanel(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: separated ? _withDividers() : children,
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers() {
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) Divider(height: 1, indent: dividerIndent, endIndent: AppTokens.space4),
        children[i],
      ],
    ];
  }
}

/// Tab body with an unsaved-changes bar that slides in above the content's
/// bottom edge while [hasChanges] is true.
class SettingsEditableBody extends StatelessWidget {
  const SettingsEditableBody({
    super.key,
    required this.child,
    required this.hasChanges,
    required this.isSaving,
    required this.onSave,
    required this.onDiscard,
  });

  final Widget child;
  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.standard),
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: hasChanges
              ? SettingsSaveBar(
                  key: const ValueKey('save-bar'),
                  isSaving: isSaving,
                  onSave: onSave,
                  onDiscard: onDiscard,
                )
              : const SizedBox(key: ValueKey('no-save-bar'), width: double.infinity),
        ),
      ],
    );
  }
}

/// Floating glass bar with "Save Changes" / "Discard".
class SettingsSaveBar extends StatelessWidget {
  const SettingsSaveBar({
    super.key,
    required this.isSaving,
    required this.onSave,
    required this.onDiscard,
  });

  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        AppTokens.space3,
      ),
      child: GlassPanel(
        blur: true,
        strong: true,
        shadow: true,
        borderRadius: AppRadius.full,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            const SizedBox(width: AppTokens.space2),
            StatusDot(color: s.accent),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Changes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space1),
            TextButton(
              onPressed: isSaving ? null : onDiscard,
              style: TextButton.styleFrom(shape: const StadiumBorder()),
              child: const Text('Discard'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold-washed note panel: a title and optional body / bullet items.
class SettingsNote extends StatelessWidget {
  const SettingsNote({
    super.key,
    required this.title,
    this.icon = Icons.info_outline_rounded,
    this.body,
    this.items = const [],
    this.child,
  });

  final String title;
  final IconData icon;
  final String? body;
  final List<String> items;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space6),
      child: GlassPanel(
        tint: s.accent.withValues(alpha: 0.10),
        borderColor: s.accent.withValues(alpha: 0.22),
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: s.accentInk),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(color: s.accentInk, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: AppTokens.space2),
              Text(body!, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w300, height: 1.5)),
            ],
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.space2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: SizedBox.square(
                        dimension: 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Text(
                        item,
                        style: t.bodySmall?.copyWith(fontWeight: FontWeight.w300, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            if (child != null) ...[const SizedBox(height: AppTokens.space2), child!],
          ],
        ),
      ),
    );
  }
}

/// Inline spinner for a section that is still loading.
class SettingsLoadingBlock extends StatelessWidget {
  const SettingsLoadingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTokens.space6),
      child: Center(
        child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
