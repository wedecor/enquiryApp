import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../filters/filters_controller.dart';

const double _kControlHeight = AppTokens.minTapTarget;

/// List / Board switch: a glass track with an ink indicator that glides
/// between the two segments.
class EnquiriesViewToggle extends StatelessWidget {
  const EnquiriesViewToggle({super.key, required this.isBoard, required this.onChanged});

  final bool isBoard;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);

    return Container(
      width: 196,
      height: _kControlHeight,
      decoration: BoxDecoration(
        color: s.glassFillStrong,
        borderRadius: AppRadius.full,
        border: Border.all(color: s.microBorderStrong),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isBoard ? Alignment.centerRight : Alignment.centerLeft,
            duration: AppMotion.of(context, AppMotion.standard),
            curve: AppMotion.springOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.onSurface,
                    borderRadius: AppRadius.full,
                    boxShadow: AppShadows.glow(s.shadow, strength: 0.16),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Segment(
                  label: 'List',
                  icon: Icons.view_agenda_outlined,
                  selected: !isBoard,
                  onTap: () => onChanged(false),
                ),
              ),
              Expanded(
                child: _Segment(
                  label: 'Board',
                  icon: Icons.view_kanban_outlined,
                  selected: isBoard,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final duration = AppMotion.of(context, AppMotion.standard);
    final fg = selected ? cs.surface : cs.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: selected ? null : onTap,
        borderRadius: AppRadius.full,
        pressedScale: 0.94,
        splash: false,
        child: SizedBox(
          height: _kControlHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: fg),
                duration: duration,
                builder: (context, color, _) => Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round 48px glass action with an optional count badge.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;

  /// Leave null when wrapped by a widget that handles the tap (menu buttons).
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;

    final circle = Container(
      width: _kControlHeight,
      height: _kControlHeight,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: s.glassFillStrong,
        border: Border.all(color: badgeCount > 0 ? s.accent : s.microBorderStrong),
      ),
      child: Badge(
        isLabelVisible: badgeCount > 0,
        label: Text('$badgeCount'),
        child: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );

    if (onTap == null) return circle;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.9,
        borderRadius: AppRadius.full,
        semanticLabel: tooltip,
        child: circle,
      ),
    );
  }
}

/// Frosted search pill bound to the enquiry filters' search query (debounced).
class EnquirySearchField extends ConsumerStatefulWidget {
  const EnquirySearchField({super.key});

  @override
  ConsumerState<EnquirySearchField> createState() => _EnquirySearchFieldState();
}

class _EnquirySearchFieldState extends ConsumerState<EnquirySearchField> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(enquiryFiltersProvider).searchQuery ?? '');
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String text) {
    _debounce?.cancel();
    final query = text.trim();
    ref.read(enquiryFiltersProvider.notifier).updateSearchQuery(query.isEmpty ? null : query);
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _commit(text));
  }

  void _clear() {
    _controller.clear();
    _commit('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(enquiryFiltersProvider.select((f) => f.searchQuery), (_, next) {
      final query = next ?? '';
      if (query != _controller.text.trim()) {
        _debounce?.cancel();
        _controller.text = query;
      }
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final focused = _focus.hasFocus;

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.standardCurve,
      height: _kControlHeight,
      decoration: BoxDecoration(
        color: s.glassFillStrong,
        borderRadius: AppRadius.full,
        border: Border.all(
          color: focused ? s.accent.withValues(alpha: 0.7) : s.microBorderStrong,
          width: focused ? 1.4 : 1,
        ),
        boxShadow: focused ? AppShadows.glow(s.accent, strength: 0.14) : const [],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onChanged: _onChanged,
        onSubmitted: _commit,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: false,
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Search name, phone or notes',
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: focused ? s.accentInk : cs.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: _clear,
                ),
        ),
      ),
    );
  }
}
