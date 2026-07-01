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
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    }
    return value.toString();
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
