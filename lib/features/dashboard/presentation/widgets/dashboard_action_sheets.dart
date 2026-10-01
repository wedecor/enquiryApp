import 'package:flutter/material.dart';

import '../../../../core/a11y/semantics_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../enquiries/domain/enquiry.dart';
import '../../../enquiries/presentation/widgets/status_inline_control.dart';

/// Bottom-sheet body for changing an enquiry's status from a dashboard row.
/// Persistence is handled inside [StatusInlineControl].
class UpdateStatusSheet extends StatelessWidget {
  const UpdateStatusSheet({super.key, required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update status', style: theme.textTheme.titleMedium).withHeaderSemantics(),
          const SizedBox(height: AppTokens.space3),
          StatusInlineControl(enquiry: enquiry),
          const SizedBox(height: AppTokens.space3),
          Text('Changes are saved automatically.', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Bottom-sheet body for editing follow-up notes.
///
/// Pops with: `null` = cancelled, `''` = clear notes, otherwise the trimmed text.
class FollowUpNotesSheet extends StatefulWidget {
  const FollowUpNotesSheet({super.key, this.initialNotes});

  final String? initialNotes;

  @override
  State<FollowUpNotesSheet> createState() => _FollowUpNotesSheetState();
}

class _FollowUpNotesSheetState extends State<FollowUpNotesSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNotes ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTokens.space4,
        right: AppTokens.space4,
        top: AppTokens.space4,
        bottom: AppTokens.space4 + viewInsets,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow-up notes',
            style: Theme.of(context).textTheme.titleMedium,
          ).withHeaderSemantics(),
          const SizedBox(height: AppTokens.space3),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Add any internal notes or follow-up reminders',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                  if (hasText)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(''),
                      child: const Text('Clear'),
                    ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(value.text.trim()),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
