import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../domain/event_functions.dart';
import 'form/event_function_card.dart';

/// What the function sheet closed with: the edited function, or a delete.
typedef EventFunctionSheetResult = ({EventFunction? saved, bool deleted});

/// Bottom sheet to add or edit one function of a booking (reuses [EventFunctionCard]).
///
/// [initial] null = a new function. [canDelete] shows Delete (with a confirm).
/// Returns null on Cancel.
Future<EventFunctionSheetResult?> showEventFunctionSheet(
  BuildContext context, {
  EventFunction? initial,
  bool canDelete = false,
  DateTime? suggestedDate,
}) {
  return showModalBottomSheet<EventFunctionSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => EventFunctionSheet(
      initial: initial,
      canDelete: canDelete,
      suggestedDate: suggestedDate,
    ),
  );
}

class EventFunctionSheet extends ConsumerStatefulWidget {
  const EventFunctionSheet({
    super.key,
    this.initial,
    this.canDelete = false,
    this.suggestedDate,
  });

  final EventFunction? initial;
  final bool canDelete;

  /// Pre-filled date for a new function (e.g. the day after the last one).
  final DateTime? suggestedDate;

  @override
  ConsumerState<EventFunctionSheet> createState() => _EventFunctionSheetState();
}

class _EventFunctionSheetState extends ConsumerState<EventFunctionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final EventFunctionDraft _draft = widget.initial == null
      ? EventFunctionDraft.blank(date: widget.suggestedDate)
      : EventFunctionDraft.fromFunction(widget.initial!);
  bool _saving = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_draft.isComplete) return;
    setState(() => _saving = true);
    DropdownLookup? lookup;
    try {
      lookup = await ref.read(dropdownLookupProvider.future);
    } catch (_) {
      lookup = null;
    }
    if (!mounted) return;
    final saved = _draft.toFunction(
      labelFor: (value) => lookup?.labelForEventType(value) ?? DropdownLookup.titleCase(value),
    );
    Navigator.of(context).pop<EventFunctionSheetResult>((saved: saved, deleted: false));
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (initial == null) return;
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete function?',
      message:
          'Remove ${initial.label} on ${DateFormat('EEE, d MMM').format(initial.day)} '
          'from this booking?',
      confirmText: 'Delete',
      cancelText: 'Keep',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    Navigator.of(context).pop<EventFunctionSheetResult>((saved: null, deleted: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTokens.space4,
          right: AppTokens.space4,
          bottom: AppTokens.space4 + viewInsets,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initial == null ? 'Add function' : 'Edit function',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTokens.space4),
                EventFunctionCard(
                  draft: _draft,
                  onChanged: () => setState(() {}),
                  allowPastDates: true,
                  framed: false,
                ),
                const SizedBox(height: AppTokens.space4),
                Row(
                  children: [
                    if (widget.canDelete && widget.initial != null)
                      TextButton.icon(
                        onPressed: _saving ? null : _delete,
                        icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                        label: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppTokens.space2),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
