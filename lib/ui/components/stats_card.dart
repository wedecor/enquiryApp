import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.trendLabel,
    this.trendIcon,
    this.trendColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? trendLabel;
  final IconData? trendIcon;
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(height: 24),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            if (trendLabel != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (trendIcon != null)
                    Icon(
                      trendIcon,
                      size: 18,
                      color: trendColor ?? colorScheme.primary,
                    ),
                  if (trendIcon != null) const SizedBox(width: 6),
                  Text(
                    trendLabel!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: trendColor ?? colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
