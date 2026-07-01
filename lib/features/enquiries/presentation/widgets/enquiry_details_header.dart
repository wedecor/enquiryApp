import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import 'enquiry_status_control.dart';

/// Header card for enquiry details with ID, customer name, and status control.
class EnquiryDetailsHeader extends StatelessWidget {
  const EnquiryDetailsHeader({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.userRole,
    required this.currentUserId,
    required this.statusValue,
    required this.statusLabel,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final UserRole? userRole;
  final String currentUserId;
  final String statusValue;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.space4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Enquiry #${enquiryId.substring(0, 8)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (userRole == UserRole.admin)
                  EnquiryStatusControl(
                    enquiryId: enquiryId,
                    enquiryData: enquiryData,
                    currentStatusValue: statusValue,
                    currentStatusLabel: statusLabel,
                    isAdmin: true,
                  )
                else if (userRole == UserRole.staff)
                  EnquiryStatusControl(
                    enquiryId: enquiryId,
                    enquiryData: enquiryData,
                    currentStatusValue: statusValue,
                    currentStatusLabel: statusLabel,
                    isAdmin: false,
                    isAssignee: (enquiryData['assignedTo'] as String?) == currentUserId,
                  )
                else
                  _ReadOnlyStatusChip(label: statusLabel, statusValue: statusValue),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Customer: ${(enquiryData['customerName'] as String?) ?? 'N/A'}',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyStatusChip extends StatelessWidget {
  const _ReadOnlyStatusChip({required this.label, required this.statusValue});

  final String label;
  final String statusValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.horizontal(
        AppTokens.space3,
      ).copyWith(top: AppTokens.space1 + 2, bottom: AppTokens.space1 + 2),
      decoration: BoxDecoration(
        color: statusColorFor(context, statusValue),
        borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
