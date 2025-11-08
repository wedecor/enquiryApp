import 'package:flutter/material.dart';

import '../../utils/event_colors.dart';
import 'age_chip.dart';
import 'event_type_chip.dart';
import 'status_chip.dart';

class EnquiryCard extends StatelessWidget {
  const EnquiryCard({
    super.key,
    required this.title,
    required this.eventType,
    required this.status,
    required this.createdAt,
    required this.onView,
    this.notes,
    this.eventDate,
    this.location,
    this.assignedTo,
    this.onWhatsApp,
    this.onCall,
    this.leadingBadge,
    this.onTap,
  });

  final String title;
  final String? eventType;
  final String? status;
  final DateTime createdAt;
  final DateTime? eventDate;
  final String? location;
  final String? assignedTo;
  final String? notes;
  final VoidCallback onView;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final Widget? leadingBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = eventAccent(eventType);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: InkWell(
        onTap: onTap ?? onView,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingBadge != null) ...[leadingBadge!, const SizedBox(width: 16)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            StatusChip(status: status),
                            AgeChip(createdAt: createdAt),
                            EventTypeChip(eventType: eventType),
                            if (assignedTo != null && assignedTo!.trim().isNotEmpty)
                              Chip(
                                avatar: const Icon(Icons.person, size: 18),
                                label: Text(assignedTo!),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right, color: accent),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _InfoRow(
                    icon: Icons.event,
                    label: eventDate != null ? _formatDate(eventDate!) : 'Date TBC',
                  ),
                  if (location != null && location!.isNotEmpty)
                    _InfoRow(icon: Icons.location_on_outlined, label: location!),
                ],
              ),
              if (notes != null && notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Notes',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(notes!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 20),
              OverflowBar(
                spacing: 12,
                overflowSpacing: 12,
                alignment: MainAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                  TextButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
