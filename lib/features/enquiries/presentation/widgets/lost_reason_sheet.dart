import 'package:flutter/material.dart';

import '../../../../core/a11y/semantics_ext.dart';
import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/enquiry_lifecycle.dart';

/// Result of [promptLostReasonIfNeeded].
///
/// * [proceed] false → the user cancelled; abort the status change.
/// * [choice] is set only when moving to a lost status.
class LostReasonPrompt {
  const LostReasonPrompt._(this.proceed, this.choice);

  static const LostReasonPrompt notNeeded = LostReasonPrompt._(true, null);
  static const LostReasonPrompt cancelled = LostReasonPrompt._(false, null);

  final bool proceed;
  final LostReasonChoice? choice;
}

/// Asks for a lost reason when [nextStatus] is a lost status (not interested,
/// closed lost, cancelled). Returns [LostReasonPrompt.notNeeded] for any other
/// status, and [LostReasonPrompt.cancelled] if the sheet is dismissed.
Future<LostReasonPrompt> promptLostReasonIfNeeded(
  BuildContext context,
  String nextStatus,
) async {
  if (!EnquiryStatus.isLost(nextStatus)) return LostReasonPrompt.notNeeded;
  final label = EnquiryStatus.fromValue(nextStatus)?.label ?? 'Lost';
  final choice = await showModalBottomSheet<LostReasonChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => LostReasonSheet(statusLabel: label),
  );
  if (choice == null) return LostReasonPrompt.cancelled;
  return LostReasonPrompt._(true, choice);
}

/// Bottom sheet that asks why an enquiry is being closed as lost.
/// Pops with a [LostReasonChoice], or `null` when cancelled.
class LostReasonSheet extends StatefulWidget {
  const LostReasonSheet({super.key, required this.statusLabel});

  /// Target status label, e.g. "Not Interested".
  final String statusLabel;

  @override
  State<LostReasonSheet> createState() => _LostReasonSheetState();
}

class _LostReasonSheetState extends State<LostReasonSheet> {
  LostReason? _selected;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _noteRequired => _selected == LostReason.other;

  bool get _canSave => _selected != null && (!_noteRequired || _note.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTokens.space4,
          right: AppTokens.space4,
          bottom: AppTokens.space4 + viewInsets,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Why is this ${widget.statusLabel.toLowerCase()}?',
                style: theme.textTheme.titleMedium,
              ).withHeaderSemantics(),
              const SizedBox(height: AppTokens.space1),
              Text(
                'Used in analytics to see where and why enquiries are lost.',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppTokens.space3),
              for (final reason in LostReason.values)
                ListTile(
                  key: ValueKey('lost-reason-${reason.value}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    _selected == reason ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: _selected == reason ? cs.primary : cs.onSurfaceVariant,
                  ),
                  title: Text(reason.label),
                  selected: _selected == reason,
                  onTap: () => setState(() => _selected = reason),
                ),
              const SizedBox(height: AppTokens.space2),
              TextField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _noteRequired ? 'Note (required)' : 'Note (optional)',
                  hintText: 'e.g. went with a cheaper vendor',
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTokens.space2),
                  FilledButton(
                    onPressed: _canSave
                        ? () => Navigator.of(
                            context,
                          ).pop(LostReasonChoice(_selected!, note: _note.text))
                        : null,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
