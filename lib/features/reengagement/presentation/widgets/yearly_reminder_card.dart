import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../enquiries/presentation/widgets/enquiry_detail_info_row.dart';
import '../../../enquiries/presentation/widgets/enquiry_detail_section.dart';
import '../../data/reengagement_repository.dart';
import '../../domain/enquiry_occasion.dart';
import '../../domain/occasion_kind.dart';
import '../../domain/occasion_reminder.dart';

/// "Yearly reminder" card on a completed enquiry: occasion kind, date and person,
/// an on/off switch (`occasionReminders`) and Edit (admin: kind / date / person;
/// staff: person only — firestore.rules protects the stamp fields).
class YearlyReminderCard extends ConsumerWidget {
  const YearlyReminderCard({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.isAdmin,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occasion = EnquiryOccasion.fromEnquiry(enquiryData);
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return EnquiryDetailSection(
      eyebrow: 'Same time next year',
      title: 'Yearly reminder',
      trailing: TextButton.icon(
        onPressed: () => _edit(context, ref, occasion),
        style: TextButton.styleFrom(foregroundColor: s.accentInk),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit'),
      ),
      children: [
        EnquiryDetailInfoRow(label: 'Occasion', value: occasion.summary),
        if (occasion.person != null) EnquiryDetailInfoRow(label: 'For', value: occasion.person),
        if (!occasion.stamped)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space3),
            child: Text(
              'Preview — saved automatically once the enquiry is completed.',
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                occasion.remindersOn
                    ? 'The team is reminded a month before'
                    : 'Reminders are off for this event',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Switch(
              value: occasion.remindersOn,
              onChanged: (on) => _toggle(context, ref, on),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    try {
      await ref.read(reengagementRepositoryProvider).setOccasionReminders(enquiryId, on: on);
    } catch (e) {
      Log.w('Yearly reminder toggle failed', data: {'error': e.toString()});
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not update the reminder')));
      }
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, EnquiryOccasion occasion) async {
    final result = await showDialog<_OccasionEdit>(
      context: context,
      builder: (_) => _EditOccasionDialog(occasion: occasion, isAdmin: isAdmin),
    );
    if (result == null || !context.mounted) return;
    final repo = ref.read(reengagementRepositoryProvider);
    try {
      if (isAdmin && (result.kind != occasion.kind || result.dayChanged)) {
        await repo.adminEditOccasion(
          enquiryId,
          kind: result.kind,
          day: result.day,
          person: result.person,
        );
      } else {
        await repo.setOccasionPerson(enquiryId, result.person);
      }
    } catch (e) {
      Log.w('Yearly reminder edit failed', data: {'error': e.toString()});
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not save the reminder')));
      }
    }
  }
}

class _OccasionEdit {
  const _OccasionEdit({
    required this.kind,
    required this.day,
    required this.dayChanged,
    required this.person,
  });

  final OccasionKind kind;

  /// Picked calendar day (y/m/d only).
  final DateTime day;
  final bool dayChanged;
  final String? person;
}

class _EditOccasionDialog extends StatefulWidget {
  const _EditOccasionDialog({required this.occasion, required this.isAdmin});

  final EnquiryOccasion occasion;
  final bool isAdmin;

  @override
  State<_EditOccasionDialog> createState() => _EditOccasionDialogState();
}

class _EditOccasionDialogState extends State<_EditOccasionDialog> {
  late OccasionKind _kind;
  late DateTime _day;
  bool _dayChanged = false;
  late final TextEditingController _person;

  @override
  void initState() {
    super.initState();
    _kind = widget.occasion.kind;
    final date = widget.occasion.date;
    if (date != null) {
      final ist = IstDate.calendar(date);
      _day = DateTime(ist.year, ist.month, ist.day);
    } else {
      final now = DateTime.now();
      _day = DateTime(now.year, now.month, now.day);
      _dayChanged = true;
    }
    _person = TextEditingController(text: widget.occasion.person ?? '');
  }

  @override
  void dispose() {
    _person.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(1950),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _day = DateTime(picked.year, picked.month, picked.day);
      _dayChanged = true;
    });
  }

  String get _dayLabel {
    final instant = IstDate.startOfDay(_day.year, _day.month, _day.day);
    return '${IstDate.long(instant)} ${_day.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Yearly reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isAdmin) ...[
              DropdownButtonFormField<OccasionKind>(
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Occasion',
                  prefixIcon: Icon(Icons.celebration_outlined),
                ),
                items: [
                  for (final kind in OccasionKind.values)
                    DropdownMenuItem(value: kind, child: Text(kind.label)),
                ],
                onChanged: (kind) {
                  if (kind != null) setState(() => _kind = kind);
                },
              ),
              const SizedBox(height: AppTokens.space4),
              OutlinedButton.icon(
                onPressed: _pickDay,
                icon: const Icon(Icons.event_outlined),
                label: Text(_dayLabel),
              ),
              const SizedBox(height: AppTokens.space1),
              Text(
                'Reminded every year on this day. Use the wedding date for '
                'haldi, mehendi or reception.',
                style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppTokens.space4),
            ],
            TextField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Whose occasion? (optional)',
                hintText: 'e.g. Aarav',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final person = _person.text.trim();
            Navigator.of(context).pop(
              _OccasionEdit(
                kind: _kind,
                day: _day,
                dayChanged: _dayChanged,
                person: person.isEmpty ? null : person,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
