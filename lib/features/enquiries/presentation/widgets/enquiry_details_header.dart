import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';

/// Header card for enquiry details with ID and read-only status.
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
    final theme = Theme.of(context);
    final statusColor = AppColorScheme.statusColorFor(statusValue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.space4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (enquiryData['customerName'] as String?) ?? 'Customer',
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.full,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Enquiry #${enquiryId.substring(0, 8)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
