import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_detail_section.dart';

/// Reference images as rounded glass thumbnails; tap to zoom.
class EnquiryImagesSection extends StatelessWidget {
  const EnquiryImagesSection({super.key, required this.images});

  final List<dynamic> images;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (images.isEmpty) {
      return EnquiryDetailSection(
        eyebrow: 'Moodboard',
        title: 'Reference Images',
        children: [
          Text(
            'No images attached',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w300,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
        ],
      );
    }

    return EnquiryDetailSection(
      eyebrow: 'Moodboard',
      title: 'Reference Images',
      trailing: Eyebrow('${images.length}', accent: true),
      children: [
        GridView.builder(
          shrinkWrap: true,
          padding: AppSpacing.bottom(AppTokens.space2),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppTokens.space2,
            mainAxisSpacing: AppTokens.space2,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final url = images[index] as String?;
            if (url == null || url.isEmpty) {
              return const SizedBox.shrink();
            }
            return StaggerIn(
              index: index,
              child: _Thumb(url: url),
            );
          },
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    return Pressable(
      borderRadius: AppRadius.medium,
      semanticLabel: 'View reference image',
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: AppRadius.large,
              child: InteractiveViewer(
                child: AspectRatio(aspectRatio: 1, child: Image.network(url, fit: BoxFit.contain)),
              ),
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.medium,
          color: s.glassFillStrong,
          border: Border.all(color: s.microBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium - 3),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
