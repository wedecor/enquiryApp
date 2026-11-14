import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/services/contact_log_service.dart';
import '../../../../core/services/review_request_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../reengagement/presentation/occasion_card_share.dart';
import '../../../reengagement/presentation/wish_card.dart';
import '../../../settings/providers/settings_providers.dart';
import 'enquiry_round_action.dart';

/// Button for thanking a completed booking and asking for a Google review.
class ReviewRequestButton extends ConsumerWidget {
  const ReviewRequestButton({
    super.key,
    required this.customerPhone,
    required this.customerName,
    this.phoneNormalized = '',
    this.eventTypeLabel,
    this.enquiryId,
    this.enabled = true,
  });

  final String? customerPhone;
  final String customerName;
  final String phoneNormalized;
  final String? eventTypeLabel;
  final String? enquiryId;
  final bool enabled;

  static const label = 'Thank & ask for review';

  static String thankedOnLabel(DateTime at) => 'Thanked on ${DateFormat('d MMM yyyy').format(at)}';

  static String alreadySentMessage(DateTime at) =>
      'Already sent on ${DateFormat('d MMM yyyy').format(at)}. Send again?';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appGeneralConfigProvider);
    final thankedAt = enquiryId == null || enquiryId!.isEmpty
        ? null
        : ref.watch(lastReviewRequestAtProvider(enquiryId!)).valueOrNull;
    final hasPhone =
        (customerPhone != null && customerPhone!.trim().isNotEmpty) ||
        phoneNormalized.trim().isNotEmpty;
    if (!hasPhone) return const SizedBox.shrink();

    return configAsync.when(
      data: (config) {
        final googleReviewLink = config.googleReviewLink.isNotEmpty
            ? config.googleReviewLink
            : null;
        final businessName = config.companyName.isNotEmpty ? config.companyName : null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EnquiryRoundAction(
              icon: Icons.star_rate_rounded,
              label: label,
              color: AppSurfaces.of(context).accent,
              enabled: enabled,
              onTap: () => _handleThankYou(
                context,
                ref,
                googleReviewLink: googleReviewLink,
                businessName: businessName,
                previouslySentAt: thankedAt,
              ),
              semanticLabel: '$label for $customerName',
              semanticHint: thankedAt == null
                  ? 'Sends a thank-you card and review request on WhatsApp'
                  : 'Already ${thankedOnLabel(thankedAt).toLowerCase()}; tap to send again',
            ),
            if (thankedAt != null) ...[
              const SizedBox(height: AppTokens.space1),
              Text(
                thankedOnLabel(thankedAt),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleThankYou(
    BuildContext context,
    WidgetRef ref, {
    required String? googleReviewLink,
    required String? businessName,
    DateTime? previouslySentAt,
  }) async {
    if (previouslySentAt != null) {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'Send again?',
        message: alreadySentMessage(previouslySentAt),
        confirmText: 'Send again',
        icon: Icons.star_rate_rounded,
      );
      if (!confirmed || !context.mounted) return;
    }

    final reviewService = ref.read(reviewRequestServiceProvider);
    final launcher = ref.read(contactLauncherProvider);
    final text = reviewService.generateReviewMessage(
      customerName: customerName,
      eventTypeLabel: eventTypeLabel,
      googleReviewLink: googleReviewLink,
      businessName: businessName,
    );

    final sent = await OccasionCardShare.share(
      context: context,
      launcher: launcher,
      content: WishCardContent.thankYou(customerName: customerName),
      text: text,
      customerPhone: customerPhone,
      phoneNormalized: phoneNormalized,
      customerName: customerName,
      enquiryId: enquiryId,
      contactType: ContactType.reviewRequest,
      imageFileName: 'we-decor-thank-you.png',
      cardAttachFailedMessage: "Couldn't attach the thank-you card — sending text only",
    );

    if (!context.mounted || !sent) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank-you sent to $customerName'),
        backgroundColor: AppColorScheme.snackSuccess,
      ),
    );
  }
}
