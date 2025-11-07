import 'package:flutter/material.dart';

class AgeChip extends StatelessWidget {
  const AgeChip({super.key, required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(createdAt);
    final label = _formatAge(age);

    return Chip(label: Text(label));
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m old';
    if (age.inHours < 24) return '${age.inHours}h old';
    if (age.inDays < 7) return '${age.inDays}d old';
    final weeks = age.inDays ~/ 7;
    if (weeks < 5) return '${weeks}w old';
    final months = age.inDays ~/ 30;
    if (months < 12) return '${months}mo old';
    final years = age.inDays ~/ 365;
    return '${years}y old';
  }
}
