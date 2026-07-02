import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Label/value row for enquiry detail sections.
class EnquiryDetailInfoRow extends StatelessWidget {
  const EnquiryDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppSpacing.bottom2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
