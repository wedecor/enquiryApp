import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

Color eventAccent(String? eventType) {
  switch ((eventType ?? '').toLowerCase()) {
    case 'haldi':
      return AppColorScheme.eventHaldi;
    case 'engagement':
      return AppColorScheme.eventEngagement;
    case 'wedding':
      return AppColorScheme.eventWedding;
    case 'birthday':
      return AppColorScheme.eventBirthday;
    case 'babyshower':
    case 'baby_shower':
    case 'baby-shower':
      return AppColorScheme.chartAmber;
    case 'corporate':
      return AppColorScheme.chartEmerald;
    default:
      return AppColorScheme.chartIndigo;
  }
}

class EventTypeColors {
  const EventTypeColors({
    required this.accent,
    required this.chipBackground,
    required this.chipForeground,
  });

  final Color accent;
  final Color chipBackground;
  final Color chipForeground;
}

class EventColors {
  EventColors._();

  static Color accentFor(String? rawType, {Color? fallback}) {
    return eventAccent(rawType);
  }

  static EventTypeColors resolve(BuildContext context, String? rawType) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentFor(rawType, fallback: colorScheme.primary);
    final chipBackground = colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final chipForeground = colorScheme.onSurface;

    return EventTypeColors(
      accent: accent,
      chipBackground: chipBackground,
      chipForeground: chipForeground,
    );
  }
}
