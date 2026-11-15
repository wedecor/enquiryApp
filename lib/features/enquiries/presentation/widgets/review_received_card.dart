import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/firestore_schema.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../data/review_received_service.dart';
import 'enquiry_detail_section.dart';

/// Admin/assignee toggle on a completed enquiry: Google review received.
class ReviewReceivedCard extends ConsumerStatefulWidget {
  const ReviewReceivedCard({super.key, required this.enquiryId, required this.enquiryData});

  final String enquiryId;
  final Map<String, dynamic> enquiryData;

  @override
  ConsumerState<ReviewReceivedCard> createState() => _ReviewReceivedCardState();
}

class _ReviewReceivedCardState extends ConsumerState<ReviewReceivedCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final enquiryData = widget.enquiryData;
    final receivedAt = enquiryData[EnquiryFields.reviewReceivedAt];
    final received = receivedAt != null;
    final when = receivedAt is Timestamp ? receivedAt.toDate() : null;
    final markedBy = enquiryData[EnquiryFields.reviewReceivedBy] as String?;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final statusLine = received
        ? (when == null
              ? 'Marked as received'
              : 'Received on ${DateFormat('d MMM yyyy').format(when)}'
                    '${markedBy != null && markedBy.isNotEmpty ? ' · by staff' : ''}')
        : 'Mark when a Google review lands';

    return EnquiryDetailSection(
      eyebrow: 'Google review',
      title: 'Review received',
      children: [
        Row(
          children: [
            Expanded(
              child: Text(statusLine, style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
            Switch(value: received, onChanged: _busy ? null : (on) => _toggle(on)),
          ],
        ),
      ],
    );
  }

  Future<void> _toggle(bool on) async {
    if (_busy) return;
    final uid = ref.read(currentUserWithFirestoreProvider).valueOrNull?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign in again to update review status')));
      }
      return;
    }
    if (!on) {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'Clear review received?',
        message: 'This removes the received mark from the enquiry.',
        confirmText: 'Clear',
        icon: Icons.rate_review_outlined,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(reviewReceivedServiceProvider)
          .setReceived(enquiryId: widget.enquiryId, userId: uid, received: on);
    } catch (e) {
      Log.w('Review received toggle failed', data: {'error': e.toString()});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not update review status')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
