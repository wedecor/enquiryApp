import 'package:flutter/material.dart';

import '../../utils/event_colors.dart';

class EventTypeChip extends StatelessWidget {
  const EventTypeChip({super.key, required this.eventType});

  final String? eventType;

  @override
  Widget build(BuildContext context) {
    final accent = eventAccent(eventType);
    final label = (eventType ?? 'Event')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');

    return Chip(
      avatar: CircleAvatar(backgroundColor: accent, radius: 8),
      label: Text(label),
    );
  }
}
