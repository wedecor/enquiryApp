import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'enquiry_detail_section.dart';

/// Reference images grid for enquiry details.
class EnquiryImagesSection extends StatelessWidget {
  const EnquiryImagesSection({super.key, required this.images});

  final List<dynamic> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const EnquiryDetailSection(
        title: 'Reference Images',
        children: [Text('No images attached')],
      );
    }

    return EnquiryDetailSection(
      title: 'Reference Images',
      children: [
        GridView.builder(
          shrinkWrap: true,
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
            return GestureDetector(
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => Dialog(
                    child: InteractiveViewer(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                child: Image.network(url, fit: BoxFit.cover),
              ),
            );
          },
        ),
      ],
    );
  }
}
