import '../../../../services/dropdown_lookup.dart';

/// Resolves display labels for an enquiry document, preferring the stored
/// `*Label` field, then the dropdown lookup, then a title-cased value.
///
/// Moved verbatim out of `EnquiryDetailsScreen.build` so the screen is layout
/// only; behaviour is unchanged.
class EnquiryDisplayLabels {
  const EnquiryDisplayLabels._({
    required this.statusValue,
    required this.statusLabel,
    required this.eventTypeLabel,
    required this.priorityLabel,
    required this.paymentStatusLabel,
    required this.sourceLabel,
  });

  factory EnquiryDisplayLabels.from(
    Map<String, dynamic> enquiryData,
    DropdownLookup? dropdownLookup,
  ) {
    String labelOrLookup(
      String? label,
      String value,
      String Function(DropdownLookup, String) resolver,
    ) {
      if (label != null && label.trim().isNotEmpty) return label;
      return dropdownLookup != null
          ? resolver(dropdownLookup, value)
          : DropdownLookup.titleCase(value);
    }

    final statusValueRaw = enquiryData['statusValue'] as String?;
    final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
        ? statusValueRaw!.trim()
        : 'new';
    final statusLabel = labelOrLookup(
      enquiryData['statusLabel'] as String?,
      statusValue,
      (l, v) => l.labelForStatus(v),
    );

    final eventTypeValueRaw =
        (enquiryData['eventTypeValue'] ?? enquiryData['eventType']) as String?;
    final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
        ? eventTypeValueRaw!.trim()
        : 'event';
    final eventTypeLabel = labelOrLookup(
      enquiryData['eventTypeLabel'] as String?,
      eventTypeValue,
      (l, v) => l.labelForEventType(v),
    );

    final priorityValueRaw = (enquiryData['priorityValue'] ?? enquiryData['priority']) as String?;
    final priorityValue = (priorityValueRaw?.trim().isNotEmpty ?? false)
        ? priorityValueRaw!.trim()
        : null;
    final priorityLabel = priorityValue != null
        ? labelOrLookup(
            enquiryData['priorityLabel'] as String?,
            priorityValue,
            (l, v) => l.labelForPriority(v),
          )
        : 'N/A';

    final paymentStatusValueRaw =
        (enquiryData['paymentStatusValue'] ?? enquiryData['paymentStatus']) as String?;
    final paymentStatusValue = (paymentStatusValueRaw?.trim().isNotEmpty ?? false)
        ? paymentStatusValueRaw!.trim()
        : null;
    final paymentStatusLabel = paymentStatusValue != null
        ? labelOrLookup(
            enquiryData['paymentStatusLabel'] as String?,
            paymentStatusValue,
            (l, v) => l.labelForPaymentStatus(v),
          )
        : 'N/A';

    final sourceValueRaw = (enquiryData['sourceValue'] ?? enquiryData['source']) as String?;
    final sourceValue = (sourceValueRaw?.trim().isNotEmpty ?? false)
        ? sourceValueRaw!.trim()
        : null;
    final sourceLabel = sourceValue != null
        ? labelOrLookup(
            enquiryData['sourceLabel'] as String?,
            sourceValue,
            (l, v) => l.labelForSource(v),
          )
        : 'N/A';

    return EnquiryDisplayLabels._(
      statusValue: statusValue,
      statusLabel: statusLabel,
      eventTypeLabel: eventTypeLabel,
      priorityLabel: priorityLabel,
      paymentStatusLabel: paymentStatusLabel,
      sourceLabel: sourceLabel,
    );
  }

  final String statusValue;
  final String statusLabel;
  final String eventTypeLabel;
  final String priorityLabel;
  final String paymentStatusLabel;
  final String sourceLabel;
}
