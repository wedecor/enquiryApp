import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/status_vocabulary.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../ui/components/enquiry_list_row.dart';

/// Kanban card: the shared [EnquiryListRow] (tight variant) made draggable.
/// While dragging, the card lifts — slight tilt, scale and a status-coloured
/// glow — and leaves a faint outlined ghost in its slot.
class KanbanCard extends StatelessWidget {
  const KanbanCard({
    super.key,
    required this.doc,
    required this.statusColor,
    required this.dropdownLookup,
    required this.onTap,
    required this.width,
  });

  final QueryDocumentSnapshot doc;
  final Color statusColor;
  final DropdownLookup? dropdownLookup;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final customerName = (data['customerName'] as String?) ?? 'Customer';
    final eventTypeValue = (data['eventTypeValue'] ?? data['eventType']) as String? ?? '';
    final eventTypeLabel =
        (data['eventTypeLabel'] as String?) ??
        (dropdownLookup?.labelForEventType(eventTypeValue) ?? _titleCase(eventTypeValue));
    final location = (data['eventLocation'] ?? data['location']) as String?;
    final eventDate = _ts(data['eventDate']);
    final hasEventDate = eventDate != null && eventDate.year > 1971;
    final createdAt = _ts(data['createdAt']) ?? DateTime.now();
    final countdown = _countdownLabel(eventDate);
    final ageLabel = _ageLabel(createdAt);
    final rawStatus = (data['statusValue'] as String?) ?? '';
    final statusValue = EnquiryStatus.canonicalValue(rawStatus) ?? rawStatus;

    // Same shared row used everywhere else; status chip is implied by the column.
    EnquiryListRow row({EdgeInsetsGeometry? margin}) => EnquiryListRow(
      customerName: customerName,
      statusValue: statusValue,
      statusColor: statusColor,
      eventTypeLabel: eventTypeLabel,
      eventTypeValue: eventTypeValue,
      eventDateLabel: countdown ?? '',
      eventDate: hasEventDate ? eventDate : null,
      location: (location != null && location.isNotEmpty) ? location : null,
      // With the date block showing the day, keep the countdown in the meta line.
      ageLabel: hasEventDate && countdown != null ? '$countdown · $ageLabel' : ageLabel,
      onTap: onTap,
      showStatusChip: false,
      showChevron: false,
      bordered: true,
      margin: margin,
    );

    final card = row();

    return LongPressDraggable<String>(
      data: doc.id,
      hapticFeedbackOnStart: true,
      delay: const Duration(milliseconds: 300),
      feedback: _LiftedCard(
        width: width,
        color: statusColor,
        child: row(margin: EdgeInsets.zero),
      ),
      childWhenDragging: _GhostSlot(
        color: statusColor,
        child: row(margin: EdgeInsets.zero),
      ),
      child: card,
    );
  }

  DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String? _countdownLabel(DateTime? date) {
    if (date == null || date.year <= 1971) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final days = eventDay.difference(today).inDays;
    if (days > 1) return 'In $days days';
    if (days == 1) return 'Tomorrow';
    if (days == 0) return 'Today';
    if (days == -1) return '1 day ago';
    return '${days.abs()}d ago';
  }

  String _ageLabel(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inHours < 24) return '${age.inHours}h old';
    if (age.inDays < 7) return '${age.inDays}d old';
    final weeks = age.inDays ~/ 7;
    if (weeks < 5) return '${weeks}w old';
    return '${age.inDays ~/ 30}mo old';
  }

  String _titleCase(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1).replaceAll('_', ' ');
  }
}

/// Drag feedback: springs up into a tilted, slightly enlarged card with a glow.
class _LiftedCard extends StatelessWidget {
  const _LiftedCard({required this.width, required this.color, required this.child});

  final double width;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.springOut,
      builder: (context, t, child) => Transform.rotate(
        angle: -0.035 * t,
        child: Transform.scale(scale: 1 + 0.045 * t, child: child),
      ),
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            boxShadow: [
              ...AppShadows.glow(color, strength: 0.32),
              BoxShadow(
                color: s.shadow.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// What stays behind in the lane while a card is being dragged.
class _GhostSlot extends StatelessWidget {
  const _GhostSlot({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AppRadius.medium,
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
        ),
        child: Opacity(opacity: 0.3, child: IgnorePointer(child: child)),
      ),
    );
  }
}
