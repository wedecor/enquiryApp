import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger.dart';
import '../../../core/providers/audit_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart' as notification_service;
import '../../../core/utils/enquiry_fields.dart';
import '../domain/event_functions.dart';

/// Saves a booking's functions from the details screen (admins and the assigned staff).
///
/// Writes `functions` plus the synced top-level fields ([functionsWriteFields]) and
/// the search index, then a "Functions" history entry and an update push.
/// None of these fields are staff-protected in firestore.rules.
class EventFunctionsService {
  const EventFunctionsService(this._firestoreService, this._auditService, this._notificationService);

  final FirestoreService _firestoreService;
  final AuditService _auditService;
  final notification_service.NotificationService _notificationService;

  /// Firestore update for [functions] on a booking whose current data is [oldData].
  static Map<String, dynamic> updateFields({
    required List<EventFunction> functions,
    required Map<String, dynamic> oldData,
    required String userId,
  }) {
    final fields = functionsWriteFields(functions, existing: oldData);
    return {
      for (final e in fields.entries) e.key: e.value ?? FieldValue.delete(),
      ...FirestoreService.searchIndexFieldsFor(
        customerName: (oldData['customerName'] as String?) ?? '',
        customerPhone: oldData['customerPhone'] as String?,
        customerEmail: oldData['customerEmail'] as String?,
        notes: enquiryNotesFrom(oldData),
        eventTypes: functionTypeLabels(functions),
      ),
      'updatedBy': userId,
    };
  }

  /// Saves [functions] (at least one). Throws on a failed write; history and the push
  /// are best-effort.
  Future<void> save({
    required String enquiryId,
    required Map<String, dynamic> oldData,
    required List<EventFunction> functions,
    required String userId,
  }) async {
    if (functions.isEmpty) throw ArgumentError('A booking needs at least one function');
    await _firestoreService.updateEnquiry(
      enquiryId,
      updateFields(functions: functions, oldData: oldData, userId: userId),
    );

    final oldSummary = functionsSummary(functionsOf(oldData));
    final newSummary = functionsSummary(functions);
    if (oldSummary != newSummary) {
      await _auditService.recordChange(
        enquiryId: enquiryId,
        fieldChanged: 'functions',
        oldValue: oldSummary.isEmpty ? 'Not Set' : oldSummary,
        newValue: newSummary,
      );
    }

    try {
      await _notificationService.notifyEnquiryUpdated(
        enquiryId: enquiryId,
        customerName: (oldData['customerName'] as String?) ?? 'Customer',
        eventType: mainFunctionOf(functions)?.label ?? 'Event',
        updatedBy: userId,
        assignedTo: oldData['assignedTo'] as String?,
      );
    } catch (e) {
      Log.w('EventFunctionsService: update push failed', data: {'error': e.toString()});
    }
  }
}

final eventFunctionsServiceProvider = Provider<EventFunctionsService>(
  (ref) => EventFunctionsService(
    ref.watch(firestoreServiceProvider),
    ref.watch(auditServiceProvider),
    ref.watch(notificationServiceProvider),
  ),
);
