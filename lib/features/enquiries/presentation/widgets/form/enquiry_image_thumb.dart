import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';

/// Square glass-framed thumbnail with a round remove button in the corner.
/// [isNew] adds a gold "new" marker for images not yet uploaded.
class EnquiryImageThumb extends StatelessWidget {
  const EnquiryImageThumb({
    super.key,
    required this.image,
    required this.onRemove,
    this.isNew = false,
  });

  final Widget image;
  final VoidCallback onRemove;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            color: s.glassFillStrong,
            border: Border.all(
              color: isNew ? s.accent.withValues(alpha: 0.6) : s.microBorder,
              width: isNew ? 1.4 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium - 3),
              child: image,
            ),
          ),
        ),
        if (isNew)
          Positioned(
            left: AppTokens.space2,
            bottom: AppTokens.space2,
            child: StatusDot(color: s.accent, size: 9),
          ),
        Positioned(
          top: 0,
          right: 0,
          child: Tooltip(
            message: 'Remove image',
            child: Pressable(
              onTap: onRemove,
              pressedScale: 0.85,
              borderRadius: AppRadius.full,
              semanticLabel: 'Remove image',
              child: SizedBox.square(
                dimension: 40,
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.glassFillStrong,
                      border: Border.all(color: s.microBorderStrong),
                    ),
                    child: Icon(Icons.close_rounded, size: AppTokens.iconSmall, color: cs.error),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
