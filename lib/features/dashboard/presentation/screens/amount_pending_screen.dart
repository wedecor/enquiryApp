import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../ui/components/glass_page_scaffold.dart';
import '../../../../ui/components/glass_state_message.dart';
import '../../../enquiries/domain/booking_amounts.dart';
import '../../../enquiries/presentation/widgets/enquiry_list_item.dart';
import '../dashboard_providers.dart';
import '../widgets/dashboard_enquiry_utils.dart';

/// Slices that hold approved + completed bookings (completed is capped at 200).
const List<EnquiryScope> amountPendingScopes = [EnquiryScope.active, EnquiryScope.completed];

/// Approved / completed bookings without a total amount ([isApprovedAmountPending]),
/// from the already-loaded dashboard slices — no extra query.
///
/// Approved first (soonest event first), then completed (most recent first).
List<QueryDocumentSnapshot<Object?>> amountPendingDocs(
  Iterable<QueryDocumentSnapshot<Object?>> docs,
) {
  final pending = docs.where((doc) {
    final data = doc.data();
    return data is Map<String, dynamic> && isApprovedAmountPending(data);
  }).toList();
  DateTime dateOf(QueryDocumentSnapshot<Object?> doc) =>
      parseEnquiryDateTime((doc.data()! as Map<String, dynamic>)['eventDate']) ?? DateTime(2000);
  bool approved(QueryDocumentSnapshot<Object?> doc) =>
      EnquiryStatus.isApproved((doc.data()! as Map<String, dynamic>)['statusValue'] as String?);
  pending.sort((a, b) {
    final aApproved = approved(a);
    final bApproved = approved(b);
    if (aApproved != bApproved) return aApproved ? -1 : 1;
    return aApproved ? dateOf(a).compareTo(dateOf(b)) : dateOf(b).compareTo(dateOf(a));
  });
  return pending;
}

/// Admin list of approved / completed bookings without an amount. Tap a row for
/// the enquiry details; Edit there adds the amount.
class AmountPendingScreen extends ConsumerWidget {
  const AmountPendingScreen({super.key, required this.userId});

  /// Same key as the dashboard listeners, so no new query is opened.
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = watchRoleScopedEnquiries(
      ref,
      isAdmin: true,
      uid: userId,
      scopes: amountPendingScopes,
    );
    final lookup = ref.watch(dropdownLookupProvider).valueOrNull;

    return GlassPageScaffold(
      eyebrow: 'Bookings',
      title: 'Amount pending',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const GlassStateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Couldn\'t load bookings',
        ),
        data: (docs) {
          final pending = amountPendingDocs(docs);
          if (pending.isEmpty) {
            return const GlassStateMessage(
              icon: Icons.check_circle_outline_rounded,
              title: 'Every booking has an amount',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppTokens.space3, bottom: AppTokens.space12),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final doc = pending[i];
              return EnquiryListItem(
                key: ValueKey(doc.id),
                enquiryId: doc.id,
                data: doc.data()! as Map<String, dynamic>,
                dropdownLookup: lookup,
              );
            },
          );
        },
      ),
    );
  }
}
