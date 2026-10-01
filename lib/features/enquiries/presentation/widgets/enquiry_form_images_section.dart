import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_form_section.dart';
import 'form/enquiry_image_thumb.dart';

/// Reference image upload and preview section for the enquiry form.
class EnquiryFormImagesSection extends StatelessWidget {
  const EnquiryFormImagesSection({
    super.key,
    required this.selectedImages,
    required this.existingImageUrls,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onRemoveExistingImage,
  });

  final List<XFile> selectedImages;
  final List<String> existingImageUrls;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final ValueChanged<int> onRemoveExistingImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EnquiryFormSection(
      eyebrow: 'Moodboard',
      title: 'Reference Images',
      children: [
        _UploadTile(onTap: onPickImages),
        if (selectedImages.isNotEmpty) ...[
          const SizedBox(height: AppTokens.space5),
          _GroupLabel('New Images (${selectedImages.length})'),
          const SizedBox(height: AppTokens.space2),
          _ThumbGrid(
            count: selectedImages.length,
            itemBuilder: (index) => EnquiryImageThumb(
              isNew: true,
              onRemove: () => onRemoveImage(index),
              image: kIsWeb
                  ? FutureBuilder<Uint8List>(
                      future: selectedImages[index].readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        if (snapshot.hasData) {
                          return Image.memory(snapshot.data!, fit: BoxFit.cover);
                        }
                        return const Icon(Icons.error);
                      },
                    )
                  : Image.file(File(selectedImages[index].path), fit: BoxFit.cover),
            ),
          ),
        ],
        const SizedBox(height: AppTokens.space5),
        _GroupLabel('Existing Images (${existingImageUrls.length})'),
        if (existingImageUrls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.space2),
            child: Text(
              'No existing images found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w300,
              ),
            ),
          )
        else ...[
          const SizedBox(height: AppTokens.space2),
          _ThumbGrid(
            count: existingImageUrls.length,
            itemBuilder: (index) => EnquiryImageThumb(
              onRemove: () => onRemoveExistingImage(index),
              image: Image.network(
                existingImageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// Responsive square grid: three columns on phones, more on wider panels.
class _ThumbGrid extends StatelessWidget {
  const _ThumbGrid({required this.count, required this.itemBuilder});

  final int count;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = (box.maxWidth / 120).floor().clamp(3, 6);
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppTokens.space2,
            mainAxisSpacing: AppTokens.space2,
          ),
          itemCount: count,
          itemBuilder: (context, index) => StaggerIn(index: index, child: itemBuilder(index)),
        );
      },
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.large,
      semanticLabel: 'Upload Images',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.large,
          color: Color.alphaBlend(s.accent.withValues(alpha: 0.06), s.glassFillStrong),
          border: Border.all(color: s.accent.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Row(
            children: [
              Container(
                width: AppTokens.minTapTarget,
                height: AppTokens.minTapTarget,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: s.accentGradient,
                  boxShadow: AppShadows.glow(s.accent, strength: 0.22),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColorScheme.brandCharcoal,
                ),
              ),
              const SizedBox(width: AppTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Images',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Choose one or more from your gallery',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
