import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../data/event_functions_service.dart';
import '../../domain/event_functions.dart';
import 'approved_date_clash_prompt.dart';
import 'enquiry_detail_section.dart';
import 'event_function_sheet.dart';

/// "Functions" timeline on the enquiry details screen: every function of the booking
/// (type, weekday + date + time, location, notes), past ones dimmed and the next one
/// highlighted. Admins and the assigned staff can add, edit (tap) and delete.
///
/// Legacy single-event enquiries show their one synthesized function; adding a
/// function converts the booking to the `functions` array.
class EventFunctionsSection extends ConsumerStatefulWidget {
  const EventFunctionsSection({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.canEdit,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final bool canEdit;

  @override
  ConsumerState<EventFunctionsSection> createState() => _EventFunctionsSectionState();
}

class _EventFunctionsSectionState extends ConsumerState<EventFunctionsSection> {
  bool _saving = false;

  List<EventFunction> get _functions => functionsOf(widget.enquiryData);

  Future<void> _add() async {
    final current = _functions;
    final last = current.isEmpty ? null : current.last.day;
    final result = await showEventFunctionSheet(
      context,
      suggestedDate: last?.add(const Duration(days: 1)),
    );
    final saved = result?.saved;
    if (saved == null || !mounted) return;
    await _save([...current, saved]);
  }

  Future<void> _edit(int index) async {
    final current = _functions;
    if (index < 0 || index >= current.length) return;
    final result = await showEventFunctionSheet(
      context,
      initial: current[index],
      canDelete: current.length > 1,
    );
    if (result == null || !mounted) return;
    final next = [...current];
    if (result.deleted) {
      next.removeAt(index);
    } else if (result.saved != null) {
      next[index] = result.saved!;
    } else {
      return;
    }
    await _save(next);
  }

  Future<void> _save(List<EventFunction> functions) async {
    if (functions.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final userId = ref.read(currentUserWithFirestoreProvider).valueOrNull?.uid;
    if (userId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please sign in again')));
      return;
    }
    final data = widget.enquiryData;
    final status = data['statusValue'] as String?;

    // Approved booking: warn about other approved events on any new or moved day.
    if (EnquiryStatus.isApproved(status)) {
      final oldDays = functionDaysOf(data).toSet();
      final newDays = {for (final f in functions) f.day}.where((d) => !oldDays.contains(d)).toList();
      if (newDays.isNotEmpty) {
        final proceed = await confirmApprovedDateClash(
          context,
          ref,
          eventDates: newDays,
          excludeEnquiryId: widget.enquiryId,
          isDateChange: true,
        );
        if (!proceed || !mounted) return;
      }
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(eventFunctionsServiceProvider)
          .save(enquiryId: widget.enquiryId, oldData: data, functions: functions, userId: userId);
      if (!mounted) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastDay = sortEventFunctions(functions).last.day;
      final active =
          !EnquiryStatus.isLost(status) &&
          EnquiryStatus.fromValue(status) != EnquiryStatus.completed;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            active && lastDay.isBefore(today)
                ? 'Functions saved — every function is in the past, so this active '
                      'enquiry will be auto-closed overnight.'
                : 'Functions saved',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Could not save functions: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final functions = _functions;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = nextFunctionOf(functions, now);
    final canEdit = widget.canEdit && !_saving;

    return EnquiryDetailSection(
      eyebrow: functions.length > 1 ? functionDateRangeLabel(functions) : 'The plan',
      title: functions.length > 1 ? '${functions.length} Functions' : 'Functions',
      trailing: widget.canEdit
          ? TextButton.icon(
              onPressed: canEdit ? _add : null,
              icon: _saving
                  ? const SizedBox(
                      width: AppTokens.iconSmall,
                      height: AppTokens.iconSmall,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('Add function'),
            )
          : null,
      children: [
        if (functions.isEmpty)
          Text(
            'No event date yet.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
        else
          for (var i = 0; i < functions.length; i++)
            _FunctionTimelineTile(
              function: functions[i],
              isPast: functions[i].day.isBefore(today),
              isNext: functions.length > 1 && identical(functions[i], next),
              isFirst: i == 0,
              isLast: i == functions.length - 1,
              onTap: canEdit ? () => _edit(i) : null,
            ),
      ],
    );
  }
}

class _FunctionTimelineTile extends StatelessWidget {
  const _FunctionTimelineTile({
    required this.function,
    required this.isPast,
    required this.isNext,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  final EventFunction function;
  final bool isPast;
  final bool isNext;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final f = function;
    final time = formatFunctionTime(f.time);
    final when = '${DateFormat('EEE, d MMM yyyy').format(f.day)}${time == null ? '' : ' · $time'}';
    final place = [
      if (f.location?.trim().isNotEmpty ?? false) f.location!.trim(),
      if ((f.locationArea?.trim().isNotEmpty ?? false) &&
          !(f.location ?? '').toLowerCase().contains(f.locationArea!.trim().toLowerCase()))
        f.locationArea!.trim(),
    ].join(' · ');
    final notes = f.notes?.trim() ?? '';
    final dotColor = isNext ? s.accent : (isPast ? s.microBorderStrong : cs.secondary);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 6),
                StatusDot(color: dotColor, size: isNext ? 10 : 8),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        f.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: AppTokens.space2),
                      const Eyebrow('Next', accent: true),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  when,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        ],
      ),
    );

    final tile = Opacity(opacity: isPast && !isNext ? 0.5 : 1, child: content);
    if (onTap == null) return tile;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      pressedScale: 0.99,
      semanticLabel: 'Edit ${f.label} on ${DateFormat('d MMM').format(f.day)}',
      child: tile,
    );
  }
}
