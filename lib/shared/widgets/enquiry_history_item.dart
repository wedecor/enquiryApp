import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../features/admin/users/presentation/users_providers.dart' as users_providers;
import '../../services/dropdown_lookup.dart';
import '../../ui/primitives/primitives.dart';
import 'enquiry_history_widget.dart';

const double _railX = 6.5;
const double _dotSize = 9;
const double _dotTop = 4;

/// One audit entry on the history timeline: a [StatusDot] node on a thin
/// painted rail, the field as an eyebrow, and the from → to values as pills.
class EnquiryHistoryTimelineItem extends StatelessWidget {
  const EnquiryHistoryTimelineItem({
    super.key,
    required this.change,
    required this.dropdownLookup,
    required this.isFirst,
    required this.isLast,
  });

  final Map<String, dynamic> change;
  final DropdownLookup? dropdownLookup;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);

    final fieldChanged = change['field_changed'] as String? ?? 'Unknown Field';
    final oldValue = change['old_value'];
    final newValue = change['new_value'];
    final userEmail = change['user_email'] as String? ?? 'Unknown User';
    final timestamp = change['timestamp'] as Timestamp?;
    final fieldKey = fieldChanged.toLowerCase();
    final isStatus = fieldKey == 'status' || fieldKey == 'statusvalue';
    final nodeColor = isStatus && newValue is String
        ? AppColorScheme.statusColorFor(newValue)
        : _fieldColor(context, fieldKey);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RailPainter(color: s.microBorderStrong, isFirst: isFirst, isLast: isLast),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 28, bottom: isLast ? 0 : AppTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_fieldIcon(fieldKey), size: 14, color: nodeColor),
                  const SizedBox(width: 6),
                  Expanded(child: Eyebrow(_fieldDisplayName(fieldChanged), color: cs.onSurface)),
                  if (timestamp != null)
                    Text(
                      _formatTimestamp(timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.space2),
              Wrap(
                spacing: AppTokens.space2,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ValuePill(
                    value: oldValue,
                    fieldKey: fieldKey,
                    dropdownLookup: dropdownLookup,
                    accent: nodeColor,
                    isNew: false,
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: cs.onSurfaceVariant),
                  _ValuePill(
                    value: newValue,
                    fieldKey: fieldKey,
                    dropdownLookup: dropdownLookup,
                    accent: nodeColor,
                    isNew: true,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space2),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Changed by: $userEmail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: _railX - _dotSize / 2,
          top: _dotTop,
          child: StatusDot(color: nodeColor, size: _dotSize),
        ),
      ],
    );
  }

  IconData _fieldIcon(String fieldKey) {
    switch (fieldKey) {
      case 'status':
      case 'statusvalue': // stored as 'statusValue' in audit trail
        return Icons.flag;
      case 'assignedto':
        return Icons.person_add;
      case 'eventstatus':
        return Icons.timeline;
      case 'priority':
      case 'priorityvalue':
        return Icons.priority_high;
      case 'totalcost':
        return Icons.attach_money;
      case 'advancepaid':
        return Icons.payment;
      case 'paymentstatus':
      case 'paymentstatusvalue':
        return Icons.account_balance_wallet;
      case 'customername':
        return Icons.person;
      case 'customerphone':
        return Icons.phone;
      case 'eventtype':
      case 'eventtypevalue':
        return Icons.event;
      case 'eventdate':
        return Icons.calendar_today;
      case 'eventlocation':
        return Icons.location_on;
      case 'description':
        return Icons.description;
      default:
        return Icons.edit;
    }
  }

  Color _fieldColor(BuildContext context, String fieldKey) {
    final cs = Theme.of(context).colorScheme;
    switch (fieldKey) {
      case 'status':
      case 'statusvalue':
      case 'assignedto':
        return cs.primary;
      case 'priority':
      case 'priorityvalue':
        return AppColorScheme.warning;
      case 'totalcost':
      case 'advancepaid':
      case 'paymentstatus':
      case 'paymentstatusvalue':
        return AppColorScheme.chartGreen;
      case 'customername':
      case 'customerphone':
        return AppColorScheme.chartIndigo;
      case 'eventtype':
      case 'eventtypevalue':
      case 'eventdate':
      case 'eventlocation':
        return cs.secondary;
      case 'description':
        return cs.tertiary;
      default:
        return AppColorScheme.neutralGrey;
    }
  }

  String _fieldDisplayName(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'status':
      case 'statusvalue': // stored as 'statusValue' in audit trail
        return 'Status';
      case 'assignedto':
        return 'Assignment';
      case 'eventstatus':
        return 'Event Status';
      case 'priority':
      case 'priorityvalue':
        return 'Priority';
      case 'totalcost':
        return 'Total Cost';
      case 'advancepaid':
        return 'Advance Paid';
      case 'paymentstatus':
      case 'paymentstatusvalue':
        return 'Payment Status';
      case 'customername':
        return 'Customer Name';
      case 'customerphone':
        return 'Customer Phone';
      case 'eventtype':
      case 'eventtypevalue':
        return 'Event Type';
      case 'eventdate':
        return 'Event Date';
      case 'eventlocation':
        return 'Event Location';
      case 'description':
        return 'Description';
      default:
        // Strip trailing 'Value' suffix from camelCase field names (e.g. "eventTypeValue" → "Event Type")
        final cleaned = fieldName.replaceAll(RegExp(r'Value$'), '');
        return cleaned
            .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
            .replaceAll('_', ' ')
            .trim()
            .toTitleCase();
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({required this.color, required this.isFirst, required this.isLast});

  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    if (isFirst && isLast) return;
    const node = _dotTop + _dotSize / 2;
    final top = isFirst ? node : 0.0;
    final bottom = isLast ? node : size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(_railX, top), Offset(_railX, bottom), paint);
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.color != color || old.isFirst != isFirst || old.isLast != isLast;
}

/// Previous value: muted and struck through. New value: soft tinted pill.
class _ValuePill extends StatelessWidget {
  const _ValuePill({
    required this.value,
    required this.fieldKey,
    required this.dropdownLookup,
    required this.accent,
    required this.isNew,
  });

  final dynamic value;
  final String fieldKey;
  final DropdownLookup? dropdownLookup;
  final Color accent;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final style = theme.textTheme.labelMedium!.copyWith(
      color: isNew ? cs.onSurface : cs.onSurfaceVariant,
      fontWeight: isNew ? FontWeight.w600 : FontWeight.w400,
      decoration: isNew ? null : TextDecoration.lineThrough,
      decorationColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isNew ? accent.withValues(alpha: 0.12) : s.glassFill,
        borderRadius: AppRadius.full,
        border: Border.all(color: isNew ? accent.withValues(alpha: 0.3) : s.microBorder),
      ),
      child: _ValueText(
        value: value,
        fieldKey: fieldKey,
        dropdownLookup: dropdownLookup,
        style: style,
      ),
    );
  }
}

class _ValueText extends ConsumerWidget {
  const _ValueText({
    required this.value,
    required this.fieldKey,
    required this.dropdownLookup,
    required this.style,
  });

  final dynamic value;
  final String fieldKey;
  final DropdownLookup? dropdownLookup;
  final TextStyle style;

  Text _text(String text) => Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For assignment field, null means "was unassigned" — show that specifically
    if (value == null) {
      return _text(fieldKey == 'assignedto' ? 'Unassigned' : 'Not Set');
    }
    if (value is String) {
      final normalized = (value as String).trim();
      if (normalized.isEmpty || normalized.toLowerCase() == 'not set') {
        return _text(fieldKey == 'assignedto' ? 'Unassigned' : 'Not Set');
      }
    }

    if (value is Timestamp) {
      final date = value.toDate();
      return _text('${date.day}/${date.month}/${date.year}');
    }

    final stringValue = value.toString();

    switch (fieldKey) {
      case 'assignedto':
        // null / empty means "was not assigned" — check before calling the provider
        if (stringValue.isEmpty || stringValue.toLowerCase() == 'unassigned') {
          return _text('Unassigned');
        }
        final asyncName = ref.watch(users_providers.userDisplayNameProvider(stringValue));
        return asyncName.when(
          data: (name) => _text(name == 'Unknown' ? 'Unassigned' : name),
          loading: () => _text('Loading...'),
          error: (err, _) => _text('Unassigned'),
        );
      case 'status':
      case 'eventstatus':
      case 'statusvalue': // camelCase key stored in audit trail
        return _text(DropdownLookup.statusLabelOf(dropdownLookup, stringValue));
      case 'eventtype':
      case 'eventtypevalue':
        return _text(
          dropdownLookup?.labelForEventType(stringValue) ?? DropdownLookup.titleCase(stringValue),
        );
      case 'priority':
      case 'priorityvalue':
        return _text(
          dropdownLookup?.labelForPriority(stringValue) ?? DropdownLookup.titleCase(stringValue),
        );
      case 'paymentstatus':
      case 'paymentstatusvalue':
        return _text(
          dropdownLookup?.labelForPaymentStatus(stringValue) ??
              DropdownLookup.titleCase(stringValue),
        );
      case 'source':
        return _text(
          dropdownLookup?.labelForSource(stringValue) ?? DropdownLookup.titleCase(stringValue),
        );
      default:
        return _text(stringValue.isEmpty ? 'Not Set' : stringValue);
    }
  }
}
