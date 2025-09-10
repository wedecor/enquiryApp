import 'dart:math';
import 'package:flutter/material.dart';

class SimplePaymentPanel extends StatelessWidget {
  final double? totalAmount;
  final double? advanceAmount;
  const SimplePaymentPanel({super.key, this.totalAmount, this.advanceAmount});

  @override
  Widget build(BuildContext context) {
    final t = (totalAmount ?? 0).toDouble();
    final a = (advanceAmount ?? 0).toDouble();
    final balance = max(0, t - a);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Payment', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _row('Total Amount', t),
          _row('Advance Amount', a),
          const Divider(height: 24),
          _row('Balance', balance.toDouble(), bold: true),
        ]),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w600) : null;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: style),
      Text(value.toStringAsFixed(2), style: style),
    ]);
  }
}

