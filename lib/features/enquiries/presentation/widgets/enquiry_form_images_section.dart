import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/tokens.dart';
import 'enquiry_form_section.dart';

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
      title: 'Reference Images',
      children: [
        ElevatedButton.icon(
          onPressed: onPickImages,
          icon: const Icon(Icons.upload),
          label: const Text('Upload Images'),
          style: ElevatedButton.styleFrom(
            padding: AppSpacing.vertical(AppTokens.space4),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        if (selectedImages.isNotEmpty) ...[
          Text(
            'New Images (${selectedImages.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTokens.space2),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: AppSpacing.right(AppTokens.space2),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMedium,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMedium,
                          ),
                          child: kIsWeb
                              ? FutureBuilder<Uint8List>(
                                  future: selectedImages[index].readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return const Icon(Icons.error);
                                  },
                                )
                              : Image.file(
                                  File(selectedImages[index].path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: AppTokens.space1,
                        right: AppTokens.space1,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: AppSpacing.space1,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: colorScheme.onError,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.space4),
        ],
        Text(
          'Existing Images (${existingImageUrls.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (existingImageUrls.isEmpty) ...[
          Padding(
            padding: AppSpacing.space2,
            child: Text(
              'No existing images found',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: AppTokens.space2),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: existingImageUrls.length,
              itemBuilder: (context, index) {
                final url = existingImageUrls[index];
                return Padding(
                  padding: AppSpacing.right(AppTokens.space2),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMedium,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMedium,
                          ),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppTokens.space1,
                        right: AppTokens.space1,
                        child: GestureDetector(
                          onTap: () => onRemoveExistingImage(index),
                          child: Container(
                            padding: AppSpacing.space1,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: colorScheme.onError,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.space4),
        ],
      ],
    );
  }
}
