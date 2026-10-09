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
import '../../domain/event_functions.dart';
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

/// Before moving an enquiry to Approved: everyone (admins and staff) sees the
/// Confirm booking sheet — the location (required, prefilled) and the amounts
/// (always shown, never required).
///
/// * Admins can enter or change the amounts; they are saved with the approval.
/// * Staff see stored amounts read-only (or "Amount will be added by an admin"):
///   the rules keep money admin-only, so a staff write never includes money fields.
///
/// Call it before the approved-date clash check.
Future<ApprovalBookingDecision> ensureApprovalBooking(
  BuildContext context,
  WidgetRef ref, {
  required String enquiryId,
  required Map<String, dynamic> data,
  required bool isAdmin,
}) async {
  // Callers may hold partial / stale data (e.g. list rows): re-read the stored doc.
  var current = data;
  try {
    final fresh = await ref.read(firestoreServiceProvider).getEnquiry(enquiryId);
    if (fresh != null) current = fresh;
  } catch (e) {
    Log.w('ensureApprovalBooking: fresh read failed', data: {'error': e.toString()});
  }
  DropdownLookup? lookup;
  try {
    lookup = await ref.read(dropdownLookupProvider.future);
  } catch (_) {
    // Labels fall back to title-cased values; they are display-only.
  }
  if (!context.mounted) return (proceed: false, sheetShown: false, fields: null);

  final eventTypeValue = ((current['eventTypeValue'] ?? current['eventType']) as String?)?.trim();
  final eventTypeLabel =
      (current['eventTypeLabel'] as String?) ??
      ((eventTypeValue == null || eventTypeValue.isEmpty)
          ? null
          : (lookup?.labelForEventType(eventTypeValue) ??
                DropdownLookup.titleCase(eventTypeValue)));
  final days = functionDaysOf(current);
  final subtitle = confirmBookingSubtitle(
    customerName: current['customerName'] as String?,
    eventType: eventTypeLabel,
    eventDate: days.isEmpty ? null : days.first,
  );

  final initialText = ((current['eventLocation'] ?? current['location']) as String?) ?? '';
  final result = await showModalBottomSheet<ConfirmBookingResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ConfirmBookingSheet(
      initialText: initialText,
      initialPlace: EnquiryPlace.fromData(current),
      locationKnown: isLocationKnownInData(current),
      subtitle: subtitle,
      canEditAmounts: isAdmin,
      initialTotal: amountText(current['totalCost']),
      initialAdvance: amountText(current['advancePaid']),
    ),
  );
  if (result == null) return (proceed: false, sheetShown: true, fields: null);

  final location = result.locationFields;
  var amountFields = const <String, Object?>{};
  // Money fields are admin-only in firestore.rules: never part of a staff write.
  if (isAdmin) {
    amountFields = bookingAmountFields(
      oldData: current,
      totalText: result.totalText,
      advanceText: result.advanceText,
      paymentStatusLabel: lookup?.labelForPaymentStatus ?? DropdownLookup.titleCase,
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
///
/// Location is required; the amounts section is always visible but optional —
/// Approve is enabled as soon as the location is good enough.
class ConfirmBookingSheet extends StatefulWidget {
  const ConfirmBookingSheet({
    super.key,
    required this.initialText,
    this.initialPlace,
    this.locationKnown = false,
    this.subtitle = '',
    this.canEditAmounts = false,
    this.initialTotal = '',
    this.initialAdvance = '',
  });

  final String initialText;
  final EnquiryPlace? initialPlace;

  /// The stored location is already good enough to approve.
  final bool locationKnown;

  /// "Customer · Event type · Date"; hidden when empty.
  final String subtitle;

  /// Admins edit the amounts; staff see stored amounts read-only.
  final bool canEditAmounts;
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
        totalText: widget.canEditAmounts ? _totalController.text : widget.initialTotal,
        advanceText: widget.canEditAmounts ? _advanceController.text : widget.initialAdvance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final showTick = widget.locationKnown && !_locationChanged;
    final quiet = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);

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
              if (widget.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  key: const Key('confirmBookingSubtitle'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppTokens.space4),
              const _SectionLabel('Location'),
              const SizedBox(height: AppTokens.space2),
              if (!widget.locationKnown) ...[
                Text('Add the area (e.g. JP Nagar) or the venue before approving.', style: quiet),
                const SizedBox(height: AppTokens.space2),
              ],
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
                    Text('Location on file', style: quiet),
                  ],
                ),
              ],
              const SizedBox(height: AppTokens.space5),
              const _SectionLabel('Amount'),
              const SizedBox(height: AppTokens.space2),
              if (widget.canEditAmounts)
                _EditableAmounts(
                  totalController: _totalController,
                  advanceController: _advanceController,
                )
              else
                _ReadOnlyAmounts(total: widget.initialTotal, advance: widget.initialAdvance),
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

/// Small muted heading for a sheet section.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    ).withHeaderSemantics();
  }
}

/// Admins: Total / Advance fields with a live balance. Optional — when both are
/// empty a quiet hint says it can be added later. Nothing is validated or flagged.
class _EditableAmounts extends StatelessWidget {
  const _EditableAmounts({required this.totalController, required this.advanceController});

  final TextEditingController totalController;
  final TextEditingController advanceController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

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
            final empty =
                totalController.text.trim().isEmpty && advanceController.text.trim().isEmpty;
            final line = balance ?? (empty ? 'Optional — you can add it later.' : null);
            if (line == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppTokens.space2),
              child: Text(line, key: const Key('confirmBookingAmountNote'), style: quiet),
            );
          },
        ),
      ],
    );
  }
}

/// Staff: stored amounts shown read-only, or a muted note when there are none.
class _ReadOnlyAmounts extends StatelessWidget {
  const _ReadOnlyAmounts({required this.total, required this.advance});

  final String total;
  final String advance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final quiet = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final totalValue = parseAmountText(total);
    final advanceValue = parseAmountText(advance);

    if (totalValue == null && advanceValue == null) {
      return Text(
        'Amount will be added by an admin',
        key: const Key('confirmBookingAmountByAdmin'),
        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      );
    }

    final balance = bookingBalanceText(total: totalValue, advance: advanceValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ReadOnlyAmount(
                label: 'Total amount',
                value: totalValue == null ? '—' : formatBookingAmount(totalValue),
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: _ReadOnlyAmount(
                label: 'Advance received',
                value: advanceValue == null ? '—' : formatBookingAmount(advanceValue),
              ),
            ),
          ],
        ),
        if (balance != null) ...[
          const SizedBox(height: AppTokens.space2),
          Text(balance, style: quiet),
        ],
      ],
    );
  }
}

class _ReadOnlyAmount extends StatelessWidget {
  const _ReadOnlyAmount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
