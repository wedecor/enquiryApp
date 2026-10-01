import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';

/// Glass search pill for the dashboard enquiry list.
class DashboardSearchField extends StatelessWidget {
  const DashboardSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.onClear,
  });

  final TextEditingController? controller;
  final String query;
  final VoidCallback? onClear;

  static const double height = 46;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);

    OutlineInputBorder border(Color color, [double width = AppTokens.microBorderWidth]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.full,
          borderSide: BorderSide(color: color, width: width),
        );

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        cursorColor: s.accent,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search by name or phone…',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w300,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: AppTokens.iconMedium,
            color: cs.onSurfaceVariant,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close_rounded, size: AppTokens.iconSmall, color: cs.onSurface),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: s.glassFillStrong,
          border: border(s.microBorder),
          enabledBorder: border(s.microBorder),
          focusedBorder: border(s.accent, 1.2),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          isDense: true,
        ),
      ),
    );
  }
}
