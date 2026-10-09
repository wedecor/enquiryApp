import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../shared/widgets/status_dropdown.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../domain/enquiry_location.dart';
import '../../../domain/event_functions.dart';
import '../enquiry_form_section.dart';
import 'enquiry_location_field.dart';

/// Editable state of one function while the form / sheet is open.
class EventFunctionDraft {
  EventFunctionDraft({
    required this.id,
    this.eventType,
    this.date,
    this.time,
    String? location,
    this.place,
    String? notes,
  }) : locationController = TextEditingController(text: location ?? ''),
       notesController = TextEditingController(text: notes ?? '');

  /// A new, empty function.
  factory EventFunctionDraft.blank({DateTime? date}) =>
      EventFunctionDraft(id: newEventFunctionId(), date: date);

  factory EventFunctionDraft.fromFunction(EventFunction f) => EventFunctionDraft(
    // The synthesized legacy function gets a real id once it is stored in the array.
    id: f.id == EventFunction.legacyId ? newEventFunctionId() : f.id,
    eventType: f.eventType,
    date: f.day,
    time: f.time,
    location: f.location,
    place: f.locationPlaceId == null
        ? null
        : EnquiryPlace(
            placeId: f.locationPlaceId!,
            address: f.locationAddress,
            area: f.locationArea,
          ),
    notes: f.notes,
  );

  final String id;
  String? eventType;
  DateTime? date;

  /// `HH:mm`, optional.
  String? time;
  final TextEditingController locationController;
  final TextEditingController notesController;

  /// Google Maps place attached to the location text (null for free text).
  EnquiryPlace? place;

  bool get hasType => eventType != null && eventType!.trim().isNotEmpty;
  bool get isComplete => hasType && date != null;

  /// The saved function. Free-text locations that name more than the city are also
  /// stored as the area (same rule as the approve sheet) so area analytics groups them.
  /// Call only when [isComplete].
  EventFunction toFunction({required String Function(String value) labelFor}) {
    final type = eventType!.trim();
    final text = locationController.text.trim();
    final notes = notesController.text.trim();
    final p = place;
    String? area;
    if (p != null) {
      area = p.area;
    } else if (!isVagueLocation(text)) {
      area = text;
    }
    return EventFunction(
      id: id,
      eventType: type,
      eventTypeLabel: labelFor(type),
      date: DateTime(date!.year, date!.month, date!.day),
      time: time,
      location: text.isEmpty ? null : text,
      locationArea: text.isEmpty ? null : area,
      locationPlaceId: text.isEmpty ? null : p?.placeId,
      locationAddress: text.isEmpty ? null : p?.address,
      notes: notes.isEmpty ? null : notes,
    );
  }

  void dispose() {
    locationController.dispose();
    notesController.dispose();
  }
}

/// Sorts drafts by date then time; drafts without a date go last (stable).
List<EventFunctionDraft> sortFunctionDrafts(List<EventFunctionDraft> drafts) {
  final indexed = drafts.asMap().entries.toList()
    ..sort((a, b) {
      final da = a.value.date;
      final db = b.value.date;
      if (da == null || db == null) {
        if (da == null && db == null) return a.key.compareTo(b.key);
        return da == null ? 1 : -1;
      }
      final byDay = da.compareTo(db);
      if (byDay != 0) return byDay;
      final byTime = (a.value.time ?? '').compareTo(b.value.time ?? '');
      return byTime != 0 ? byTime : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// One function's fields: event type, date, optional time, location and notes.
///
/// Used by the enquiry form's Functions editor and the details screen's function
/// sheet. Changes are written into [draft]; [onChanged] asks the parent to rebuild
/// (and re-sort by date).
class EventFunctionCard extends StatelessWidget {
  const EventFunctionCard({
    super.key,
    required this.draft,
    required this.onChanged,
    this.title,
    this.onRemove,
    this.allowPastDates = false,
    this.requireKnownLocation = false,
    this.framed = true,
  });

  final EventFunctionDraft draft;
  final VoidCallback onChanged;

  /// e.g. "Function 2 of 4"; hidden when null.
  final String? title;

  /// Shows a remove button when set.
  final VoidCallback? onRemove;

  /// Edit mode: past dates may be picked to correct wrong entries.
  final bool allowPastDates;

  /// The booking is (or will be) approved: a city-only location is rejected.
  final bool requireKnownLocation;

  /// Draws the card outline (off inside a bottom sheet).
  final bool framed;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final defaultLast = today.add(const Duration(days: 730));
    var initialDate = draft.date ?? today;
    if (!allowPastDates && initialDate.isBefore(today)) initialDate = today;
    final earliest = DateTime(2020, 1, 1);
    final firstDate = allowPastDates
        ? (initialDate.isBefore(earliest) ? initialDate : earliest)
        : today;
    final lastDate = initialDate.isAfter(defaultLast) ? initialDate : defaultLast;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (!context.mounted || picked == null) return;
    draft.date = DateTime(picked.year, picked.month, picked.day);
    onChanged();
  }

  Future<void> _pickTime(BuildContext context) async {
    final current = parseFunctionTime(draft.time);
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 18, minute: 0)
          : TimeOfDay(hour: current.$1, minute: current.$2),
    );
    if (!context.mounted || picked == null) return;
    draft.time = functionTimeText(picked.hour, picked.minute);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    final date = draft.date;
    final timeLabel = formatFunctionTime(draft.time);

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || onRemove != null) ...[
          Row(
            children: [
              Expanded(child: Eyebrow(title ?? '', accent: true)),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove function',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
        ],
        StatusDropdown(
          collectionName: 'event_types',
          value: draft.eventType,
          label: 'Function',
          required: true,
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              draft.eventType = value;
              onChanged();
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Please select the function';
            return null;
          },
        ),
        const SizedBox(height: kEnquiryFieldGap),
        EnquiryFieldPair(
          first: FormField<DateTime>(
            // Re-validated on submit; reads the draft, not the field value.
            validator: (_) => draft.date == null ? 'Pick a date' : null,
            builder: (field) => Pressable(
              onTap: () async {
                await _pickDate(context);
                if (field.mounted && field.hasError) field.validate();
              },
              borderRadius: AppRadius.medium,
              pressedScale: 0.98,
              child: InputDecorator(
                isEmpty: date == null,
                decoration: InputDecoration(
                  labelText: 'Date *',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: const Icon(Icons.expand_more_rounded),
                  errorText: field.errorText,
                ),
                child: Text(
                  date == null ? '' : DateFormat('EEE, d MMM yyyy').format(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          second: Pressable(
            onTap: () => _pickTime(context),
            borderRadius: AppRadius.medium,
            pressedScale: 0.98,
            child: InputDecorator(
              isEmpty: timeLabel == null,
              decoration: InputDecoration(
                labelText: 'Time (optional)',
                prefixIcon: const Icon(Icons.schedule_outlined),
                suffixIcon: timeLabel == null
                    ? const Icon(Icons.expand_more_rounded)
                    : IconButton(
                        tooltip: 'Clear time',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          draft.time = null;
                          onChanged();
                        },
                      ),
              ),
              child: Text(
                timeLabel ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        const SizedBox(height: kEnquiryFieldGap),
        EnquiryLocationField(
          controller: draft.locationController,
          place: draft.place,
          onPlaceChanged: (place) {
            draft.place = place;
            onChanged();
          },
          requireKnownLocation: requireKnownLocation,
        ),
        const SizedBox(height: kEnquiryFieldGap),
        TextFormField(
          controller: draft.notesController,
          scrollPadding: kEnquiryFieldScrollPadding,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );

    if (!framed) return fields;
    return Container(
      margin: AppSpacing.bottom(AppTokens.space3),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space3,
        AppTokens.space4,
        AppTokens.space4,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        border: Border.all(color: s.microBorderStrong),
      ),
      child: fields,
    );
  }
}
