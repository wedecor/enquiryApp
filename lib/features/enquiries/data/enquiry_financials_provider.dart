import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/enquiry_financials.dart';
import '../../../core/services/firestore_service.dart';

/// Live `enquiries/{id}/financial/summary` (admin only; null when it doesn't
/// exist yet, i.e. the enquiry still carries legacy money fields on the parent).
/// Never watch this for staff: the rules deny the read.
final enquiryFinancialSummaryProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, enquiryId) {
      final db = ref.watch(firestoreServiceProvider).firestore;
      return EnquiryFinancials.watch(db, enquiryId);
    });
