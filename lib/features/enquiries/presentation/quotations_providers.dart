import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quotations_repository.dart';
import '../domain/quotation.dart';

/// Live quotations for one enquiry (admin-only in rules).
final enquiryQuotationsProvider = StreamProvider.autoDispose.family<List<Quotation>, String>((
  ref,
  enquiryId,
) {
  return ref.watch(quotationsRepositoryProvider).watchQuotations(enquiryId);
});

/// Shared catalog of reusable line items.
final quoteCatalogProvider = StreamProvider.autoDispose<List<CatalogItem>>((ref) {
  return ref.watch(quotationsRepositoryProvider).watchCatalog();
});
