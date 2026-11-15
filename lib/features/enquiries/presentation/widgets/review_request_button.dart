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
import '../../../reengagement/presentation/reengagement_actions.dart';
import '../../../reengagement/presentation/wish_card.dart';
import '../../../settings/providers/settings_providers.dart';
import 'enquiry_round_action.dart';

/// Button for thanking a completed booking and asking for a Google review.
class ReviewRequestButton extends ConsumerStatefulWidget {
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

  /// Short label on the round action (header space is tight).
  static const label = 'Thank you';

  static String thankedOnLabel(DateTime at) => 'Thanked on ${DateFormat('d MMM yyyy').format(at)}';

  static String alreadySentMessage(DateTime at) =>
      'Already sent on ${DateFormat('d MMM yyyy').format(at)}. Send again?';

  @override
  ConsumerState<ReviewRequestButton> createState() => _ReviewRequestButtonState();
}

class _ReviewRequestButtonState extends ConsumerState<ReviewRequestButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final launcher = ref.watch(contactLauncherProvider);
    final configAsync = ref.watch(appGeneralConfigProvider);
    final enquiryId = widget.enquiryId;
    final thankedAt = enquiryId == null || enquiryId.isEmpty
        ? null
        : ref.watch(lastReviewRequestAtProvider(enquiryId)).valueOrNull;
    final hasPhone =
        ReengagementActions.isUsablePhone(launcher, widget.customerPhone) ||
        ReengagementActions.isUsablePhone(launcher, widget.phoneNormalized);
    if (!hasPhone) return const SizedBox.shrink();

    final googleReviewLink = configAsync.valueOrNull?.googleReviewLink;
    final businessName = configAsync.valueOrNull?.companyName;
    final configReady = configAsync.hasValue || configAsync.hasError;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EnquiryRoundAction(
          icon: Icons.star_rate_rounded,
          label: ReviewRequestButton.label,
          color: AppSurfaces.of(context).accent,
          enabled: widget.enabled && !_busy && configReady,
          onTap: () => _handleThankYou(
            googleReviewLink: (googleReviewLink != null && googleReviewLink.isNotEmpty)
                ? googleReviewLink
                : null,
            businessName: (businessName != null && businessName.isNotEmpty) ? businessName : null,
          ),
          semanticLabel: 'Thank & ask for review for ${widget.customerName}',
          semanticHint: thankedAt == null
              ? 'Sends a thank-you card and review request on WhatsApp'
              : 'Already ${ReviewRequestButton.thankedOnLabel(thankedAt).toLowerCase()}; tap to send again',
        ),
        if (thankedAt != null) ...[
          const SizedBox(height: AppTokens.space1),
          Text(
            ReviewRequestButton.thankedOnLabel(thankedAt),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleThankYou({
    required String? googleReviewLink,
    required String? businessName,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final enquiryId = widget.enquiryId;
      if (enquiryId != null && enquiryId.isNotEmpty) {
        final previouslySentAt = await ref
            .read(contactLogServiceProvider)
            .latestAt(enquiryId: enquiryId, type: ContactType.reviewRequest);
        if (!mounted) return;
        if (previouslySentAt != null) {
          final confirmed = await ConfirmationDialog.show(
            context: context,
            title: 'Send again?',
            message: ReviewRequestButton.alreadySentMessage(previouslySentAt),
            confirmText: 'Send again',
            icon: Icons.star_rate_rounded,
          );
          if (!confirmed || !mounted) return;
        }
      }

      final reviewService = ref.read(reviewRequestServiceProvider);
      final launcher = ref.read(contactLauncherProvider);
      final text = reviewService.generateReviewMessage(
        customerName: widget.customerName,
        eventTypeLabel: widget.eventTypeLabel,
        googleReviewLink: googleReviewLink,
        businessName: businessName,
      );

      final result = await OccasionCardShare.share(
        context: context,
        launcher: launcher,
        content: WishCardContent.thankYou(
          customerName: widget.customerName,
          eventTypeLabel: widget.eventTypeLabel,
        ),
        text: text,
        customerPhone: widget.customerPhone,
        phoneNormalized: widget.phoneNormalized,
        customerName: widget.customerName,
        enquiryId: enquiryId,
        contactType: ContactType.reviewRequest,
        imageFileName: 'we-decor-thank-you.png',
        cardAttachFailedMessage: "Couldn't attach the thank-you card — sending text only",
      );

      if (!mounted || result != OccasionShareResult.sent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank-you marked sent to ${widget.customerName}'),
          backgroundColor: AppColorScheme.snackSuccess,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
