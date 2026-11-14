import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/firestore_schema.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../data/review_received_service.dart';
import 'enquiry_detail_section.dart';

/// Admin/assignee toggle on a completed enquiry: Google review received.
class ReviewReceivedCard extends ConsumerWidget {
  const ReviewReceivedCard({super.key, required this.enquiryId, required this.enquiryData});

  final String enquiryId;
  final Map<String, dynamic> enquiryData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedAt = enquiryData[EnquiryFields.reviewReceivedAt];
    final received = receivedAt != null;
    final when = receivedAt is Timestamp ? receivedAt.toDate() : null;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return EnquiryDetailSection(
      eyebrow: 'Google review',
      title: 'Review received',
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                received
                    ? (when == null
                          ? 'Marked as received'
                          : 'Received on ${DateFormat('d MMM yyyy').format(when)}')
                    : 'Mark when a Google review lands',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Switch(value: received, onChanged: (on) => _toggle(context, ref, on)),
          ],
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final uid = ref.read(currentUserWithFirestoreProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(reviewReceivedServiceProvider)
          .setReceived(enquiryId: enquiryId, userId: uid, received: on);
    } catch (e) {
      Log.w('Review received toggle failed', data: {'error': e.toString()});
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not update review status')));
      }
    }
  }
}
