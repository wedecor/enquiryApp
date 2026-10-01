import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/dropdown_item.dart';

IconData dropdownGroupIcon(DropdownGroup group) {
  switch (group) {
    case DropdownGroup.statuses:
      return Icons.flag_outlined;
    case DropdownGroup.eventTypes:
      return Icons.event_outlined;
    case DropdownGroup.priorities:
      return Icons.priority_high_rounded;
    case DropdownGroup.paymentStatuses:
      return Icons.payments_outlined;
    case DropdownGroup.sources:
      return Icons.campaign_outlined;
  }
}

/// Parses `#RRGGBB` into a colour; null when absent or malformed.
Color? parseDropdownColor(String? hex) {
  if (hex == null) return null;
  final parsed = int.tryParse(hex.replaceFirst('#', '0xFF'));
  return parsed == null ? null : Color(parsed);
}

/// Glass row for one dropdown item: drag handle (admins), colour swatch,
/// label / value, active state and the actions menu. Menu selections are
/// reported via [onAction] as `edit`, `activate`, `deactivate`, `replace`
/// or `delete`.
class DropdownItemTile extends StatelessWidget {
  const DropdownItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isAdmin,
    required this.onAction,
  });

  final DropdownItem item;
  final int index;
  final bool isAdmin;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    final swatch = parseDropdownColor(item.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: GlassPanel(
        padding: EdgeInsets.fromLTRB(
          isAdmin ? AppTokens.space1 : AppTokens.space4,
          AppTokens.space2,
          AppTokens.space1,
          AppTokens.space2,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              if (isAdmin)
                ReorderableDragStartListener(
                  index: index,
                  child: SizedBox.square(
                    dimension: AppTokens.minTapTarget,
                    child: Icon(Icons.drag_indicator_rounded, color: cs.onSurfaceVariant),
                  ),
                ),
              _Swatch(color: swatch, border: s.microBorderStrong),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.active ? null : cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w300,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              _ActiveBadge(active: item.active),
              PopupMenuButton<String>(
                enabled: isAdmin,
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: onAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [Icon(Icons.edit_outlined), SizedBox(width: 8), Text('Edit')],
                    ),
                  ),
                  PopupMenuItem(
                    value: item.active ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          item.active ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(item.active ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'replace',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded),
                        SizedBox(width: 8),
                        Text('Replace in enquiries'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: cs.error),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: cs.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.border});

  final Color? color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        border: Border.all(color: c == null ? border : c.withValues(alpha: 0.4), width: 1.5),
        boxShadow: c == null ? null : AppShadows.glow(c, strength: 0.35),
      ),
      child: c == null
          ? Icon(Icons.palette_outlined, size: 12, color: Theme.of(context).colorScheme.outline)
          : null,
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColorScheme.chartGreen : AppColorScheme.chartAmber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, size: 7),
        const SizedBox(width: 6),
        Text(
          active ? 'Active' : 'Inactive',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Hero count with an active / inactive proportion strip.
class DropdownGroupStats extends StatelessWidget {
  const DropdownGroupStats({
    super.key,
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassPanel(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Eyebrow('Total'),
              Text(
                '$total',
                style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.05),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProportionStrip(
                  segments: [
                    (active.toDouble(), AppColorScheme.chartGreen),
                    (inactive.toDouble(), AppColorScheme.chartAmber),
                  ],
                ),
                const SizedBox(height: AppTokens.space3),
                Wrap(
                  spacing: AppTokens.space4,
                  runSpacing: AppTokens.space1,
                  children: [
                    _Legend(color: AppColorScheme.chartGreen, label: 'Active', value: active),
                    _Legend(color: AppColorScheme.chartAmber, label: 'Inactive', value: inactive),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, size: 7),
        const SizedBox(width: 6),
        Text('$value', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Text(label, style: t.labelMedium?.copyWith(fontWeight: FontWeight.w300)),
      ],
    );
  }
}
