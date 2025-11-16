import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/services/review_request_service.dart';
import '../../../settings/providers/settings_providers.dart';

/// Button widget for requesting reviews from customers for completed enquiries
class ReviewRequestButton extends ConsumerWidget {
  const ReviewRequestButton({
    super.key,
    required this.customerPhone,
    required this.customerName,
    this.enquiryId,
    this.enabled = true,
  });

  final String? customerPhone;
  final String customerName;
  final String? enquiryId;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reviewService = ref.read(reviewRequestServiceProvider);
    final configAsync = ref.watch(appGeneralConfigProvider);

    if (customerPhone == null || customerPhone!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return configAsync.when(
      data: (config) {
        // Use config values or defaults
        final googleReviewLink = config.googleReviewLink.isNotEmpty 
            ? config.googleReviewLink 
            : null;
        final instagramHandle = config.instagramHandle.isNotEmpty 
            ? config.instagramHandle 
            : null;
        final websiteUrl = config.websiteUrl.isNotEmpty 
            ? config.websiteUrl 
            : null;
            
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            onPressed: enabled
                ? () => _handleReviewRequest(
                      context,
                      ref,
                      reviewService,
                      googleReviewLink,
                      instagramHandle,
                      websiteUrl,
                    )
                : null,
            icon: const Icon(Icons.star_rate_rounded),
            label: const Text('Request Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleReviewRequest(
    BuildContext context,
    WidgetRef ref,
    ReviewRequestService reviewService,
    String? googleReviewLink,
    String? instagramHandle,
    String? websiteUrl,
  ) async {
    if (customerPhone == null || customerPhone!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for review request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final status = await reviewService.sendReviewRequest(
        customerPhone: customerPhone!,
        customerName: customerName,
        googleReviewLink: googleReviewLink,
        instagramHandle: instagramHandle,
        websiteUrl: websiteUrl,
        enquiryId: enquiryId,
      );

      if (!context.mounted) return;

      switch (status) {
        case ContactLaunchStatus.opened:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Review request sent to $customerName'),
              backgroundColor: Colors.green,
            ),
          );
          break;

        case ContactLaunchStatus.invalidNumber:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid phone number format'),
              backgroundColor: Colors.red,
            ),
          );
          break;

        case ContactLaunchStatus.notInstalled:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp not installed. Opened in browser instead.'),
              backgroundColor: Colors.orange,
            ),
          );
          break;

        case ContactLaunchStatus.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending review request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

