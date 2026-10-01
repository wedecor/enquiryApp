import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/tinted_icon_badge.dart';
import '../../../../ui/primitives/primitives.dart';

/// Muted trailing chevron for rows that navigate.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant);
  }
}

/// Pressable glass row: tinted icon badge, w600 title, w300 subtitle, trailing.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.subtitleMaxLines = 3,
    this.subtitleStyle,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final int subtitleMaxLines;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              TintedIconBadge(icon: icon!, color: iconColor, enabled: enabled),
              const SizedBox(width: AppTokens.space3),
            ],
            Expanded(
              child: AnimatedOpacity(
                opacity: enabled ? 1 : 0.55,
                duration: AppMotion.of(context, AppMotion.standard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style:
                            subtitleStyle ??
                            t.bodySmall?.copyWith(
                              fontWeight: FontWeight.w300,
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppTokens.space2), trailing!],
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.large,
      pressedScale: 0.985,
      child: content,
    );
  }
}

/// [SettingsTile] whose whole row toggles a trailing switch.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool value;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return MergeSemantics(
      child: SettingsTile(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        enabled: enabled,
        onTap: enabled ? () => onChanged!(!value) : null,
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

/// Radio (single) or check (multi) row with an animated selection mark.
class SettingsChoiceTile extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.multiSelect = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool selected;
  final bool multiSelect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: !multiSelect,
        child: SettingsTile(
          title: title,
          subtitle: subtitle,
          icon: icon,
          iconColor: iconColor,
          enabled: onTap != null,
          onTap: onTap,
          trailing: _ChoiceMark(selected: selected, square: multiSelect),
        ),
      ),
    );
  }
}

class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.selected, required this.square});

  final bool selected;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    final duration = AppMotion.of(context, AppMotion.standard);
    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.standardCurve,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(7) : null,
        border: Border.all(color: selected ? cs.primary : s.microBorderStrong, width: 1.5),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: duration,
        curve: AppMotion.springOut,
        child: Icon(Icons.check_rounded, size: 16, color: cs.onPrimary),
      ),
    );
  }
}

/// Label/value pair for read-only facts (version, region...).
class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({super.key, required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
