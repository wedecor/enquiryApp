import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/a11y/semantics_ext.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/enquiry_fields.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../domain/booking_amounts.dart';
import '../../domain/enquiry_location.dart';
import 'form/enquiry_location_field.dart';

/// Result of [ensureApprovalBooking].
///
/// * [proceed] false → the user cancelled; abort the approval.
/// * [sheetShown] true → the user confirmed in the sheet (no further confirm needed).
/// * [fields] are written together with the status change (null when nothing
///   changed or nothing was asked).
typedef ApprovalBookingDecision = ({
  bool proceed,
  bool sheetShown,
  Map<String, Object?>? fields,
});

/// Before moving an enquiry to Approved.
///
/// * Admins always see the Confirm booking sheet: the location (required, prefilled)
///   and a quiet, optional "Add amount" section.
/// * Staff see it only when the location isn't known (area at minimum, see
///   [isLocationKnown]), without amounts — the rules keep money admin-only.
///
/// Call it before the approved-date clash check.
Future<ApprovalBookingDecision> ensureApprovalBooking(
  BuildContext context,
  WidgetRef ref, {
  required String enquiryId,
  required Map<String, dynamic> data,
  required bool isAdmin,
}) async {
  if (!isAdmin && isLocationKnownInData(data)) {
    return (proceed: true, sheetShown: false, fields: null);
  }

  // Callers may hold partial / stale data (e.g. list rows): re-read the stored doc.
  var current = data;
  try {
    final fresh = await ref.read(firestoreServiceProvider).getEnquiry(enquiryId);
    if (fresh != null) {
      if (!isAdmin && isLocationKnownInData(fresh)) {
        return (proceed: true, sheetShown: false, fields: null);
      }
      current = fresh;
    }
  } catch (e) {
    Log.w('ensureApprovalBooking: fresh read failed', data: {'error': e.toString()});
  }
  if (!context.mounted) return (proceed: false, sheetShown: false, fields: null);

  final initialText = ((current['eventLocation'] ?? current['location']) as String?) ?? '';
  final result = await showModalBottomSheet<ConfirmBookingResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ConfirmBookingSheet(
      initialText: initialText,
      initialPlace: EnquiryPlace.fromData(current),
      locationKnown: isLocationKnownInData(current),
      showAmounts: isAdmin,
      initialTotal: amountText(current['totalCost']),
      initialAdvance: amountText(current['advancePaid']),
    ),
  );
  if (result == null) return (proceed: false, sheetShown: true, fields: null);

  final location = result.locationFields;
  var amountFields = const <String, Object?>{};
  if (isAdmin) {
    String Function(String) labelFor = DropdownLookup.titleCase;
    try {
      labelFor = (await ref.read(dropdownLookupProvider.future)).labelForPaymentStatus;
    } catch (_) {
      // Fall back to a title-cased value; the label is display-only.
    }
    amountFields = bookingAmountFields(
      oldData: current,
      totalText: result.totalText,
      advanceText: result.advanceText,
      paymentStatusLabel: labelFor,
    );
  }

  final fields = <String, Object?>{
    if (location != null) ...{
      ...location,
      // Clear place parts the new location doesn't have (e.g. a stale city-only pick).
      for (final key in EnquiryPlace.fieldKeys)
        if (!location.containsKey(key)) key: FieldValue.delete(),
    },
    ...amountFields,
  };
  return (proceed: true, sheetShown: true, fields: fields.isEmpty ? null : fields);
}

/// What the Confirm booking sheet pops with on Approve.
class ConfirmBookingResult {
  const ConfirmBookingResult({
    required this.locationFields,
    this.totalText = '',
    this.advanceText = '',
  });

  /// From [approvalLocationFields]; null when a known location was left as it was.
  final Map<String, Object>? locationFields;
  final String totalText;
  final String advanceText;
}

/// "Confirm booking" sheet shown before approving. Pops a [ConfirmBookingResult],
/// or null on Cancel.
class ConfirmBookingSheet extends StatefulWidget {
  const ConfirmBookingSheet({
    super.key,
    required this.initialText,
    this.initialPlace,
    this.locationKnown = false,
    this.showAmounts = false,
    this.initialTotal = '',
    this.initialAdvance = '',
  });

  final String initialText;
  final EnquiryPlace? initialPlace;

  /// The stored location is already good enough to approve.
  final bool locationKnown;

  /// Admins: optional amounts section (collapsed unless amounts already exist).
  final bool showAmounts;
  final String initialTotal;
  final String initialAdvance;

  @override
  State<ConfirmBookingSheet> createState() => _ConfirmBookingSheetState();
}

class _ConfirmBookingSheetState extends State<ConfirmBookingSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText.trim(),
  );
  late final TextEditingController _totalController = TextEditingController(
    text: widget.initialTotal,
  );
  late final TextEditingController _advanceController = TextEditingController(
    text: widget.initialAdvance,
  );
  late EnquiryPlace? _place = widget.initialPlace;
  late bool _amountsOpen =
      widget.initialTotal.trim().isNotEmpty || widget.initialAdvance.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _totalController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canSave => canSaveApprovalLocation(text: _controller.text, place: _place);

  bool get _locationChanged =>
      _controller.text.trim() != widget.initialText.trim() ||
      !identical(_place, widget.initialPlace);

  void _save() {
    if (!_canSave) return;
    final writeLocation = !widget.locationKnown || _locationChanged;
    Navigator.of(context).pop(
      ConfirmBookingResult(
        locationFields: writeLocation
            ? approvalLocationFields(text: _controller.text, place: _place)
            : null,
        totalText: widget.showAmounts ? _totalController.text : widget.initialTotal,
        advanceText: widget.showAmounts ? _advanceController.text : widget.initialAdvance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final showTick = widget.locationKnown && !_locationChanged;

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
              Text('Confirm booking', style: theme.textTheme.titleMedium).withHeaderSemantics(),
              if (!widget.locationKnown) ...[
                const SizedBox(height: AppTokens.space1),
                Text(
                  'Add the area (e.g. JP Nagar) or the venue before approving.',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppTokens.space4),
              EnquiryLocationField(
                controller: _controller,
                place: _place,
                onPlaceChanged: (place) => setState(() => _place = place),
                autofocus: !widget.locationKnown,
              ),
              if (showTick) ...[
                const SizedBox(height: AppTokens.space1),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 16, color: cs.primary),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      'Location on file',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
              if (widget.showAmounts) ...[
                const SizedBox(height: AppTokens.space3),
                _OptionalAmounts(
                  open: _amountsOpen,
                  onOpen: () => setState(() => _amountsOpen = true),
                  totalController: _totalController,
                  advanceController: _advanceController,
                ),
              ],
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
                    key: const Key('confirmBookingApprove'),
                    onPressed: _canSave ? _save : null,
                    child: Text(widget.locationKnown ? 'Approve' : 'Save & approve'),
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

/// Quiet "Add amount (optional)" row that expands into Total / Advance fields and
/// a live balance line. Nothing here is required or validated.
class _OptionalAmounts extends StatelessWidget {
  const _OptionalAmounts({
    required this.open,
    required this.onOpen,
    required this.totalController,
    required this.advanceController,
  });

  final bool open;
  final VoidCallback onOpen;
  final TextEditingController totalController;
  final TextEditingController advanceController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final quiet = theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant);

    if (!open) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('confirmBookingAddAmount'),
          onPressed: onOpen,
          style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text('Add amount (optional)', style: quiet),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AmountField(
                key: const Key('confirmBookingTotal'),
                controller: totalController,
                label: 'Total amount',
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: _AmountField(
                key: const Key('confirmBookingAdvance'),
                controller: advanceController,
                label: 'Advance received',
              ),
            ),
          ],
        ),
        ListenableBuilder(
          listenable: Listenable.merge([totalController, advanceController]),
          builder: (context, _) {
            final balance = bookingBalanceText(
              total: parseAmountText(totalController.text),
              advance: parseAmountText(advanceController.text),
            );
            if (balance == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppTokens.space2),
              child: Text(
                balance,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixText: '₹ '),
    );
  }
}
