import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';

/// Provider for AuditService
final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService();
});

/// Provider for enquiry history stream
final enquiryHistoryProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  enquiryId,
) {
  final auditService = ref.read(auditServiceProvider);
  return auditService.getEnquiryHistoryStream(enquiryId);
});

/// Provider for field history stream
final fieldHistoryProvider = StreamProvider.family<List<Map<String, dynamic>>, Map<String, String>>(
  (ref, params) {
    final auditService = ref.read(auditServiceProvider);
    final enquiryId = params['enquiryId']!;
    final fieldName = params['fieldName']!;
    return Stream.fromFuture(auditService.getFieldHistory(enquiryId, fieldName));
  },
);

/// Provider for user changes stream
final userChangesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  userId,
) {
  final auditService = ref.read(auditServiceProvider);
  return Stream.fromFuture(auditService.getUserChanges(userId));
});

/// Provider for recent changes stream
final recentChangesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final auditService = ref.read(auditServiceProvider);
  return Stream.fromFuture(auditService.getRecentChanges());
});

/// Provider for enquiry change summary
final enquiryChangeSummaryProvider = StreamProvider.family<Map<String, dynamic>, String>((
  ref,
  enquiryId,
) {
  final auditService = ref.read(auditServiceProvider);
  return Stream.fromFuture(auditService.getEnquiryChangeSummary(enquiryId));
});
