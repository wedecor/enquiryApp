import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';

/// Customer contact facts. Call/WhatsApp/review actions live in the header.
class CustomerInfoSection extends StatelessWidget {
  const CustomerInfoSection({
    super.key,
    required this.customerPhone,
    required this.location,
    this.onAddEvent,
  });

  final String? customerPhone;
  final String location;

  /// "Add another event" for this customer (admins only); null hides the button.
  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context) {
    return EnquiryDetailSection(
      eyebrow: 'Who & where',
      title: 'Basic Information',
      trailing: onAddEvent == null
          ? null
          : TextButton.icon(
              onPressed: onAddEvent,
              icon: const Icon(Icons.add_rounded, size: AppTokens.iconSmall),
              label: const Text('Add event'),
            ),
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
