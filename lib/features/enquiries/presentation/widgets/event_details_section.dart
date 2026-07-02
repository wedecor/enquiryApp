import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';

class EventDetailsSection extends StatelessWidget {
  const EventDetailsSection({
    super.key,
    required this.eventTypeLabel,
    required this.eventDate,
    required this.guestCount,
    required this.budgetRange,
    required this.priorityLabel,
    required this.sourceLabel,
  });

  final String eventTypeLabel;
  final dynamic eventDate;
  final dynamic guestCount;
  final String? budgetRange;
  final String priorityLabel;
  final String sourceLabel;

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else {
      return value.toString();
    }
    if (date.year <= 1971) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return EnquiryDetailSection(
      title: 'Event Details',
      children: [
        EnquiryDetailInfoRow(label: 'Event Type', value: eventTypeLabel),
        EnquiryDetailInfoRow(label: 'Event Date', value: _formatDate(eventDate)),
        EnquiryDetailInfoRow(label: 'Guest Count', value: '${guestCount ?? 'N/A'} guests'),
        EnquiryDetailInfoRow(label: 'Budget Range', value: budgetRange ?? 'N/A'),
        EnquiryDetailInfoRow(label: 'Priority', value: priorityLabel),
        EnquiryDetailInfoRow(label: 'Source', value: sourceLabel),
      ],
    );
  }
}
