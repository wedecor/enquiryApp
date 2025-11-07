import 'package:flutter/material.dart';

Color eventAccent(String? eventType) {
  switch ((eventType ?? '').toLowerCase()) {
    case 'haldi':
      return const Color(0xFFF4B400);
    case 'engagement':
      return const Color(0xFFFF6B6B);
    case 'wedding':
      return const Color(0xFF8B5CF6);
    case 'birthday':
      return const Color(0xFF06B6D4);
    case 'babyshower':
    case 'baby_shower':
    case 'baby-shower':
      return const Color(0xFFF59E0B);
    case 'corporate':
      return const Color(0xFF22C55E);
    default:
      return const Color(0xFF7AA2FF);
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
    final chipBackground = colorScheme.surfaceContainerHighest.withOpacity(0.35);
    final chipForeground = colorScheme.onSurface;

    return EventTypeColors(
      accent: accent,
      chipBackground: chipBackground,
      chipForeground: chipForeground,
    );
  }
}
