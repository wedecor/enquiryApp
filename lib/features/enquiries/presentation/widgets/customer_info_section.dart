import 'package:flutter/material.dart';

import 'contact_buttons.dart';
import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';
import 'review_request_button.dart';

class CustomerInfoSection extends StatelessWidget {
  const CustomerInfoSection({
    super.key,
    required this.enquiryId,
    required this.customerName,
    required this.customerPhone,
    required this.location,
    required this.eventTypeLabel,
    required this.eventDate,
    required this.statusValue,
  });

  final String enquiryId;
  final String customerName;
  final String? customerPhone;
  final String location;
  final String eventTypeLabel;
  final DateTime? eventDate;
  final String statusValue;

  @override
  Widget build(BuildContext context) {
    return EnquiryDetailSection(
      title: 'Basic Information',
      children: [
        EnquiryDetailInfoRow(label: 'Customer Name', value: customerName),
        EnquiryDetailInfoRow(label: 'Phone', value: customerPhone ?? 'N/A'),
        ContactButtons(
          customerPhone: customerPhone,
          customerName: customerName,
          enquiryId: enquiryId,
          eventType: eventTypeLabel,
          eventDate: eventDate,
        ),
        if (statusValue == 'completed')
          ReviewRequestButton(
            customerPhone: customerPhone,
            customerName: customerName,
            enquiryId: enquiryId,
          ),
        EnquiryDetailInfoRow(label: 'Location', value: location),
      ],
    );
  }
}
