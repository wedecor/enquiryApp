import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/status_dropdown.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_form_section.dart';

/// Event date, type, guest count and budget fields for the enquiry form.
///
/// A booking with several functions (Haldi, Mehendi, Wedding…) shows
/// [functionsEditor] in place of the single date + type fields.
class EnquiryFormEventFields extends StatelessWidget {
  const EnquiryFormEventFields({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    required this.selectedEventType,
    required this.onEventTypeChanged,
    required this.guestCountController,
    required this.budgetController,
    this.onAddFunction,
    this.functionsEditor,
  });

  final DateTime? selectedDate;
  final VoidCallback onSelectDate;
  final String? selectedEventType;
  final ValueChanged<String?> onEventTypeChanged;
  final TextEditingController guestCountController;
  final TextEditingController budgetController;

  /// "+ Add another function" under the date (switches the form to the Functions editor).
  final VoidCallback? onAddFunction;

  /// The Functions editor; replaces the single date + type fields when set.
  final Widget? functionsEditor;

  @override
  Widget build(BuildContext context) {
    return EnquiryFormSection(
      eyebrow: 'When & what',
      title: 'Event Details',
      children: [
        if (functionsEditor != null)
          functionsEditor!
        else
          ..._singleEventFields(context),
        const SizedBox(height: kEnquiryFieldGap),
        EnquiryFieldPair(
          first: TextFormField(
            controller: guestCountController,
            scrollPadding: kEnquiryFieldScrollPadding,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Guest Count (optional)',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              final count = int.tryParse(trimmed);
              if (count == null || count < 0) return 'Enter a valid guest count';
              return null;
            },
          ),
          second: TextFormField(
            controller: budgetController,
            scrollPadding: kEnquiryFieldScrollPadding,
            decoration: const InputDecoration(
              labelText: 'Budget Range (optional)',
              prefixIcon: Icon(Icons.currency_rupee),
              hintText: 'e.g. 50000-100000',
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _singleEventFields(BuildContext context) => [
    // Styled exactly like the text fields around it.
    Pressable(
      onTap: onSelectDate,
      borderRadius: AppRadius.medium,
      pressedScale: 0.98,
      child: InputDecorator(
        isEmpty: selectedDate == null,
        decoration: const InputDecoration(
          labelText: 'Event Date *',
          prefixIcon: Icon(Icons.calendar_today_outlined),
          suffixIcon: Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          selectedDate == null ? '' : DateFormat('EEE, d MMM yyyy').format(selectedDate!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
    const SizedBox(height: kEnquiryFieldGap),
    StatusDropdown(
      collectionName: 'event_types',
      value: selectedEventType,
      label: 'Event Type',
      required: true,
      onChanged: (value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onEventTypeChanged(value);
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please select an event type';
        }
        return null;
      },
    ),
    if (onAddFunction != null) ...[
      const SizedBox(height: AppTokens.space2),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onAddFunction,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add another function'),
        ),
      ),
    ],
  ];
}
