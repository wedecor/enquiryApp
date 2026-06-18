import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/status_dropdown.dart';
import 'enquiry_form_section.dart';

/// Admin-only financial fields for the enquiry form.
class EnquiryFormFinancialFields extends ConsumerWidget {
  const EnquiryFormFinancialFields({
    super.key,
    required this.totalCostController,
    required this.advancePaidController,
    required this.selectedPaymentStatus,
    required this.onPaymentStatusChanged,
    required this.parseDouble,
  });

  final TextEditingController totalCostController;
  final TextEditingController advancePaidController;
  final String? selectedPaymentStatus;
  final ValueChanged<String?> onPaymentStatusChanged;
  final double? Function(String?) parseDouble;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);

    return roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return const SizedBox.shrink();
        }
        return EnquiryFormSection(
          title: 'Financial Information (Admin Only)',
          children: [
            TextFormField(
              controller: totalCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Cost',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                hintText: 'Enter total cost',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final cost = parseDouble(value);
                  if (cost == null || cost < 0) {
                    return 'Please enter a valid amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.space4),
            TextFormField(
              controller: advancePaidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Advance Paid',
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
                hintText: 'Enter advance amount',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final advance = parseDouble(value);
                  if (advance == null || advance < 0) {
                    return 'Please enter a valid amount';
                  }

                  final totalCost = parseDouble(totalCostController.text);
                  if (totalCost != null && advance > totalCost) {
                    return 'Advance cannot be more than total cost';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.space4),
            StatusDropdown(
              collectionName: 'payment_statuses',
              value: selectedPaymentStatus,
              label: 'Payment Status',
              onChanged: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onPaymentStatusChanged(value);
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a payment status';
                }
                return null;
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
