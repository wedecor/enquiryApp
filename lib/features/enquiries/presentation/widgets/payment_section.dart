import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';

/// Admin financial panel: a gold ring for advance-vs-total beside the hero
/// total, then advance, balance and payment status.
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
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final total = totalCost is num ? (totalCost as num).toDouble() : null;
    final advance = advancePaid is num ? (advancePaid as num).toDouble() : null;
    final ratio = (total != null && total > 0) ? ((advance ?? 0) / total).clamp(0.0, 1.0) : null;
    final balance = (total != null && advance != null) ? total - advance : null;

    return EnquiryDetailSection(
      eyebrow: 'Admin only',
      title: 'Financial Information',
      children: [
        Row(
          children: [
            RingGauge(
              value: ratio ?? 0,
              size: 84,
              thickness: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ratio == null ? '—' : '${(ratio * 100).round()}%',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'paid',
                    style: t.labelSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Total Cost'),
                  const SizedBox(height: AppTokens.space1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatCurrency(totalCost),
                      maxLines: 1,
                      style: AppTypography.numeral.copyWith(color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space5),
        EnquiryInfoGrid(
          children: [
            EnquiryDetailInfoRow(label: 'Advance Paid', value: _formatCurrency(advancePaid)),
            if (balance != null)
              EnquiryDetailInfoRow(label: 'Balance', value: _formatCurrency(balance)),
            EnquiryDetailInfoRow(
              label: 'Payment Status',
              value: paymentStatusLabel,
              leading: StatusDot(color: s.accent),
            ),
          ],
        ),
      ],
    );
  }
}
