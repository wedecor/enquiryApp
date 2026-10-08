import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/a11y/semantics_ext.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/enquiry_location.dart';
import 'form/enquiry_location_field.dart';

/// Result of [ensureApprovalLocation].
///
/// * [proceed] false → the user cancelled; abort the approval.
/// * [fields] are written together with the status change (null when the stored
///   location was already good enough and nothing was asked).
typedef ApprovalLocationDecision = ({bool proceed, Map<String, Object?>? fields});

/// Approval requires a known location (area at minimum, see [isLocationKnown]).
///
/// When [data] (and, failing that, a fresh read of the enquiry) has none, shows the
/// Confirm location sheet. Call it before the approved-date clash check.
Future<ApprovalLocationDecision> ensureApprovalLocation(
  BuildContext context,
  WidgetRef ref, {
  required String enquiryId,
  required Map<String, dynamic> data,
}) async {
  if (isLocationKnownInData(data)) return (proceed: true, fields: null);

  // Callers may hold partial / stale data (e.g. list rows): re-check the stored doc.
  var current = data;
  try {
    final fresh = await ref.read(firestoreServiceProvider).getEnquiry(enquiryId);
    if (fresh != null) {
      if (isLocationKnownInData(fresh)) return (proceed: true, fields: null);
      current = fresh;
    }
  } catch (e) {
    Log.w('ensureApprovalLocation: fresh read failed', data: {'error': e.toString()});
  }
  if (!context.mounted) return (proceed: false, fields: null);

  final initialText = ((current['eventLocation'] ?? current['location']) as String?) ?? '';
  final fields = await showModalBottomSheet<Map<String, Object>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ConfirmLocationSheet(
      initialText: initialText,
      initialPlace: EnquiryPlace.fromData(current),
    ),
  );
  if (fields == null) return (proceed: false, fields: null);
  return (
    proceed: true,
    fields: <String, Object?>{
      ...fields,
      // Clear place parts the new location doesn't have (e.g. a stale city-only pick).
      for (final key in EnquiryPlace.fieldKeys)
        if (!fields.containsKey(key)) key: FieldValue.delete(),
    },
  );
}

/// "Confirm location" sheet shown before approving an enquiry whose location is
/// only the city. Pops with the fields from [approvalLocationFields], or null on
/// Cancel.
class ConfirmLocationSheet extends StatefulWidget {
  const ConfirmLocationSheet({super.key, required this.initialText, this.initialPlace});

  final String initialText;
  final EnquiryPlace? initialPlace;

  @override
  State<ConfirmLocationSheet> createState() => _ConfirmLocationSheetState();
}

class _ConfirmLocationSheetState extends State<ConfirmLocationSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText.trim(),
  );
  late EnquiryPlace? _place = widget.initialPlace;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canSave => canSaveApprovalLocation(text: _controller.text, place: _place);

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(approvalLocationFields(text: _controller.text, place: _place));
  }

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
              Text('Confirm location', style: theme.textTheme.titleMedium).withHeaderSemantics(),
              const SizedBox(height: AppTokens.space1),
              Text(
                'Add the area (e.g. JP Nagar) or the venue before approving.',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppTokens.space4),
              EnquiryLocationField(
                controller: _controller,
                place: _place,
                onPlaceChanged: (place) => setState(() => _place = place),
                autofocus: true,
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
                    key: const Key('confirmLocationSave'),
                    onPressed: _canSave ? _save : null,
                    child: const Text('Save & approve'),
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
