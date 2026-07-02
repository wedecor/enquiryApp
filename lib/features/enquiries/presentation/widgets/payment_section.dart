import 'package:flutter/material.dart';

import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';

class PaymentSection extends StatelessWidget {
  const PaymentSection({
    super.key,
    required this.totalCost,
    required this.advancePaid,
    required this.paymentStatusLabel,
  });

  final dynamic totalCost;
  final dynamic advancePaid;
  final String paymentStatusLabel;

  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) return '₹${value.toStringAsFixed(0)}';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return EnquiryDetailSection(
      title: 'Financial Information',
      children: [
        EnquiryDetailInfoRow(
          label: 'Total Cost',
          value: _formatCurrency(totalCost),
        ),
        EnquiryDetailInfoRow(
          label: 'Advance Paid',
          value: _formatCurrency(advancePaid),
        ),
        EnquiryDetailInfoRow(
          label: 'Payment Status',
          value: paymentStatusLabel,
        ),
      ],
    );
  }
}
