import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final accent = AppColorScheme.statusColorFor(status);
    final label = status == null || status!.isEmpty
        ? 'Unknown'
        : status!
              .replaceAll('_', ' ')
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
