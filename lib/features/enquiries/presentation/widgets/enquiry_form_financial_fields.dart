import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/status_dropdown.dart';
import '../../../../ui/primitives/primitives.dart';
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
          eyebrow: 'Admin only',
          eyebrowIcon: Icons.lock_outline_rounded,
          title: 'Financial Information',
          children: [
            EnquiryFieldPair(
              first: TextFormField(
                controller: totalCostController,
                scrollPadding: kEnquiryFieldScrollPadding,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Cost',
                  prefixIcon: Icon(Icons.attach_money),
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
              second: TextFormField(
                controller: advancePaidController,
                scrollPadding: kEnquiryFieldScrollPadding,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Advance Paid',
                  prefixIcon: Icon(Icons.payment),
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
            ),
            _AdvancePreview(
              totalCostController: totalCostController,
              advancePaidController: advancePaidController,
              parseDouble: parseDouble,
            ),
            const SizedBox(height: kEnquiryFieldGap),
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Live advance-vs-total strip; hidden until a positive total is entered.
class _AdvancePreview extends StatelessWidget {
  const _AdvancePreview({
    required this.totalCostController,
    required this.advancePaidController,
    required this.parseDouble,
  });

  final TextEditingController totalCostController;
  final TextEditingController advancePaidController;
  final double? Function(String?) parseDouble;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([totalCostController, advancePaidController]),
      builder: (context, _) {
        final total = parseDouble(totalCostController.text) ?? 0;
        final advance = parseDouble(advancePaidController.text) ?? 0;
        final visible = total > 0 && advance >= 0;
        final paid = visible ? advance.clamp(0.0, total) : 0.0;
        final pct = visible ? (paid / total * 100).round() : 0;

        return AnimatedSize(
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: !visible
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ProportionStrip(
                          height: 8,
                          segments: [(paid, s.accent), (total - paid, s.microBorderStrong)],
                        ),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$pct%',
                              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: ' advance',
                              style: t.labelMedium?.copyWith(
                                fontWeight: FontWeight.w300,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
