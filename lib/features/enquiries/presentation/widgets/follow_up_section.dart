import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/glass_dialog.dart';
import '../../data/follow_up_service.dart';
import '../../domain/follow_up.dart';
import 'enquiry_detail_section.dart';

/// Automatic follow-up for an open (New / In Talks) enquiry: when it is due, and
/// Scheduled follow-up card (due / Mark done / reschedule / callback).
/// Switched off in the UI (Nov 2026) — Follow Up tab uses the 10-day rule instead.
class FollowUpSection extends ConsumerStatefulWidget {
  const FollowUpSection({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.canAct,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;

  /// Admin or the assigned staff member (the rules enforce the same).
  final bool canAct;

  /// Shown for eligible statuses once the server tracks follow-ups for the enquiry.
  static bool shouldShow(Map<String, dynamic> data) {
    final info = FollowUpInfo.fromData(data);
    return FollowUpInfo.isEligibleStatus(data['statusValue'] as String?) &&
        (info.tracked || info.dueAt != null);
  }

  @override
  ConsumerState<FollowUpSection> createState() => _FollowUpSectionState();
}

class _FollowUpSectionState extends ConsumerState<FollowUpSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(String userId) action, String done) async {
    final userId = ref.read(currentUserWithFirestoreProvider).valueOrNull?.uid;
    if (userId == null || _busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(userId);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not update the follow-up')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(FollowUpInfo info) => _run(
    (userId) => ref
        .read(followUpServiceProvider)
        .complete(enquiryId: widget.enquiryId, userId: userId, previousDueAt: info.dueAt),
    'Follow-up marked done',
  );

  Future<void> _reschedule(FollowUpInfo info) async {
    final now = DateTime.now();
    final initial = now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Call back on',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Call back at',
    );
    if (time == null || !mounted) return;
    final dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!dueAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick a time in the future')));
      return;
    }
    final note = await _askNote(dueAt);
    if (note == null || !mounted) return;
    await _run(
      (userId) => ref
          .read(followUpServiceProvider)
          .reschedule(
            enquiryId: widget.enquiryId,
            userId: userId,
            dueAt: dueAt,
            previousDueAt: info.dueAt,
            note: note,
          ),
      'Callback set for ${DateFormat('d MMM, h:mm a').format(dueAt)}',
    );
  }

  /// Returns the note ('' for none), or null when cancelled.
  Future<String?> _askNote(DateTime dueAt) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => GlassDialog(
        icon: Icons.event_repeat_rounded,
        title: 'Callback ${DateFormat('d MMM, h:mm a').format(dueAt)}',
        content: TextField(
          controller: controller,
          maxLength: FollowUpService.maxNoteLength,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'e.g. Customer asked to call after 6 pm',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final info = FollowUpInfo.fromData(widget.enquiryData);
    final state = info.stateAt(now);
    final tint = switch (state) {
      FollowUpState.overdue => cs.error,
      FollowUpState.due => AppColorScheme.warning,
      _ => cs.primary,
    };
    final due = info.dueAt;
    final details = <String>[
      if (due != null) DateFormat('EEE d MMM, h:mm a').format(due),
      if (info.isPastEvent) 'Event date has passed — confirm the outcome or follow up',
      if (info.isCallback) 'Customer callback',
      if (info.note != null && info.note!.trim().isNotEmpty) info.note!.trim(),
      if (info.lastCompletedAt != null)
        'Last follow-up ${DateFormat('d MMM').format(info.lastCompletedAt!)}',
    ];

    return EnquiryDetailSection(
      eyebrow: 'Follow-up',
      title: followUpDueLabel(info, now),
      trailing: Icon(
        state == FollowUpState.overdue ? Icons.alarm_rounded : Icons.event_repeat_rounded,
        color: tint,
        semanticLabel: state.name,
      ),
      children: [
        for (final line in details)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space1),
            child: Text(line, style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ),
        if (widget.canAct) ...[
          const SizedBox(height: AppTokens.space2),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: [
              if (due != null)
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _complete(info),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark done'),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _reschedule(info),
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Reschedule'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
