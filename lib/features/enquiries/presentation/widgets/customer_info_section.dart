import 'package:flutter/material.dart';

import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';

/// Customer contact facts. Call/WhatsApp/review actions live in the header.
class CustomerInfoSection extends StatelessWidget {
  const CustomerInfoSection({super.key, required this.customerPhone, required this.location});

  final String? customerPhone;
  final String location;

  @override
  Widget build(BuildContext context) {
    return EnquiryDetailSection(
      eyebrow: 'Who & where',
      title: 'Basic Information',
      children: [
        EnquiryInfoGrid(
          children: [
            EnquiryDetailInfoRow(label: 'Phone', value: customerPhone ?? 'N/A'),
            EnquiryDetailInfoRow(label: 'Location', value: location),
          ],
        ),
      ],
    );
  }
}
