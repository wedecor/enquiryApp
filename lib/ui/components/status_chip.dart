import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = status?.toLowerCase() ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    final Color accent;
    switch (normalized) {
      case 'new':
        accent = colorScheme.primary;
        break;
      case 'in_talks':
      case 'in talks':
        accent = colorScheme.secondary;
        break;
      case 'quote_sent':
      case 'quote sent':
        accent = colorScheme.tertiary;
        break;
      case 'confirmed':
      case 'completed':
        accent = colorScheme.primary;
        break;
      case 'cancelled':
        accent = colorScheme.error;
        break;
      default:
        accent = colorScheme.primary;
    }

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
