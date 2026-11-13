import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/logging/logger.dart';
import '../utils/string_extension.dart';
import 'firestore_service.dart';

/// Lowercase set of enquiry history `field_changed` names that carry money or
/// payment information. These must NEVER be written to staff-readable `history`.
const Set<String> moneyHistoryFieldsLower = {
  'totalcost',
  'advancepaid',
  'quotedamount',
  'quotedat',
  'paymentstatus',
  'paymentstatusvalue',
  'paymentstatuslabel',
};

/// Maximum character length allowed by Firestore rules for string values in
/// `history` and `financial_history` (`old_value` / `new_value`).
const int maxHistoryStringLength = 2000;

/// Service for tracking audit trail and change history
class AuditService {
  AuditService(this._firestoreService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;

  FirebaseFirestore get _firestore => _firestoreService.firestore;

  /// Returns `true` when [fieldChanged] belongs to the money/payment history set
  /// (case-insensitive).
  static bool isMoneyHistoryField(String fieldChanged) =>
      moneyHistoryFieldsLower.contains(fieldChanged.trim().toLowerCase());

  static dynamic _truncateHistoryValue(dynamic value) {
    if (value is String && value.length > maxHistoryStringLength) {
      return value.substring(0, maxHistoryStringLength);
    }
    return value;
  }

  /// UID that history docs are attributed to. Security rules require
  /// `user_id == request.auth.uid` on create, so this is always the signed-in user.
  String? get _historyUserId => _auth.currentUser?.uid;

  /// A fresh `enquiries/{enquiryId}/history/{auto}` reference, for callers that write the
  /// history entry inside their own transaction or batch.
  DocumentReference<Map<String, dynamic>> newHistoryRef(String enquiryId) =>
      _firestore.collection('enquiries').doc(enquiryId).collection('history').doc();

  /// A fresh `enquiries/{enquiryId}/financial_history/{auto}` reference (admin-only).
  DocumentReference<Map<String, dynamic>> newFinancialHistoryRef(String enquiryId) =>
      _firestore.collection('enquiries').doc(enquiryId).collection('financial_history').doc();

  /// Routes money/payment fields to `financial_history` and everything else to `history`.
  DocumentReference<Map<String, dynamic>> historyRefForField(
    String enquiryId,
    String fieldChanged,
  ) => isMoneyHistoryField(fieldChanged)
      ? newFinancialHistoryRef(enquiryId)
      : newHistoryRef(enquiryId);

  /// History document data for a change made by the signed-in user.
  ///
  /// Throws [StateError] when nobody is signed in (the write would be rejected anyway).
  Map<String, dynamic> buildHistoryEntry({
    required String fieldChanged,
    required dynamic oldValue,
    required dynamic newValue,
  }) {
    final currentUser = _auth.currentUser;
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('Cannot record history without a signed-in user');
    }
    return {
      'field_changed': fieldChanged,
      'old_value': _truncateHistoryValue(oldValue),
      'new_value': _truncateHistoryValue(newValue),
      'user_id': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'user_email': currentUser?.email ?? 'unknown',
    };
  }

  void _warnIfForeignUserId(String? userId) {
    if (userId != null && userId != _historyUserId) {
      Log.w(
        'AuditService: ignoring userId that is not the signed-in user',
        data: {'requestedUserId': userId, 'currentUserId': _historyUserId},
      );
    }
  }

  /// Record a change to an enquiry.
  ///
  /// Non-fatal: failures are logged (never thrown) so the UI action that triggered the
  /// change still completes. [userId] is accepted for compatibility but history is always
  /// attributed to the signed-in user (rules enforce it).
  Future<void> recordChange({
    required String enquiryId,
    required String fieldChanged,
    required dynamic oldValue,
    required dynamic newValue,
    String? userId,
  }) async {
    try {
      _warnIfForeignUserId(userId);
      await historyRefForField(
        enquiryId,
        fieldChanged,
      ).set(buildHistoryEntry(fieldChanged: fieldChanged, oldValue: oldValue, newValue: newValue));

      Log.d('AuditService: recorded change', data: {'field': fieldChanged, 'enquiryId': enquiryId});
    } catch (e, st) {
      Log.w(
        'AuditService: history entry NOT recorded',
        data: {'field': fieldChanged, 'enquiryId': enquiryId, 'error': e.toString()},
      );
      Log.e('AuditService: error recording change', error: e, stackTrace: st);
    }
  }

  /// Record multiple changes at once (for bulk updates). Non-fatal, like [recordChange].
  Future<void> recordMultipleChanges({
    required String enquiryId,
    required Map<String, Map<String, dynamic>> changes,
    String? userId,
  }) async {
    if (changes.isEmpty) return;
    try {
      _warnIfForeignUserId(userId);
      final batch = _firestore.batch();

      for (final entry in changes.entries) {
        final changeData = entry.value;
        batch.set(
          historyRefForField(enquiryId, entry.key),
          buildHistoryEntry(
            fieldChanged: entry.key,
            oldValue: changeData['old_value'],
            newValue: changeData['new_value'],
          ),
        );
      }

      await batch.commit();
      Log.d(
        'AuditService: recorded multiple changes',
        data: {'count': changes.length, 'enquiryId': enquiryId},
      );
    } catch (e, st) {
      Log.w(
        'AuditService: history entries NOT recorded',
        data: {'fields': changes.keys.toList(), 'enquiryId': enquiryId, 'error': e.toString()},
      );
      Log.e('AuditService: error recording multiple changes', error: e, stackTrace: st);
    }
  }

  /// Get change history for an enquiry (real-time stream)
  Stream<List<Map<String, dynamic>>> getEnquiryHistoryStream(String enquiryId) {
    try {
      // Try subcollection approach first
      // Limit to 100 for history - can grow large but we want recent history
      // Note: orderBy('timestamp') may require Firestore index - check console if errors occur
      return _firestore
          .collection('enquiries')
          .doc(enquiryId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .timeout(const Duration(seconds: 30))
          .map((snapshot) {
            Log.d(
              'AuditService: history snapshot received',
              data: {'enquiryId': enquiryId, 'count': snapshot.docs.length},
            );

            if (snapshot.docs.isEmpty) {
              Log.d('AuditService: no history found', data: {'enquiryId': enquiryId});
              return <Map<String, dynamic>>[];
            }

            final docs = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();

            Log.d(
              'AuditService: returning history items',
              data: {'enquiryId': enquiryId, 'count': docs.length},
            );
            return docs;
          })
          .handleError((Object error) {
            Log.e(
              'AuditService: history stream error',
              error: error,
              data: {'enquiryId': enquiryId},
            );
            // Try one-time fetch as fallback on error
            return getEnquiryHistory(enquiryId).asStream();
          })
          .handleError((Object error) {
            Log.e(
              'AuditService: fallback fetch also failed',
              error: error,
              data: {'enquiryId': enquiryId},
            );
            // Return empty list as last resort
            return <Map<String, dynamic>>[];
          });
    } catch (e, st) {
      Log.e(
        'AuditService: failed to create history stream',
        error: e,
        stackTrace: st,
        data: {'enquiryId': enquiryId},
      );
      // Try one-time fetch as fallback
      return getEnquiryHistory(enquiryId).asStream().handleError((Object error) {
        Log.e(
          'AuditService: fallback fetch failed in catch',
          error: error,
          data: {'enquiryId': enquiryId},
        );
        return <Map<String, dynamic>>[];
      });
    }
  }

  /// Real-time stream of admin-only `financial_history` for an enquiry.
  /// Must only be subscribed for admins.
  Stream<List<Map<String, dynamic>>> getEnquiryFinancialHistoryStream(String enquiryId) {
    return _firestore
        .collection('enquiries')
        .doc(enquiryId)
        .collection('financial_history')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .timeout(const Duration(seconds: 30))
        .map(
          (snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        )
        .handleError((Object error) {
          Log.e(
            'AuditService: financial_history stream error',
            error: error,
            data: {'enquiryId': enquiryId},
          );
          return <Map<String, dynamic>>[];
        });
  }

  /// Merged history stream: staff receive `history` only (never attempting a
  /// `financial_history` read); admins receive both `history` and
  /// `financial_history` merged by timestamp descending.
  Stream<List<Map<String, dynamic>>> getMergedEnquiryHistoryStream(
    String enquiryId, {
    required bool includeFinancial,
  }) {
    if (!includeFinancial) {
      return getEnquiryHistoryStream(enquiryId);
    }

    late final StreamController<List<Map<String, dynamic>>> controller;
    List<Map<String, dynamic>> latestPublic = const [];
    List<Map<String, dynamic>> latestFinancial = const [];
    var hasPublic = false;
    var hasFinancial = false;
    StreamSubscription<List<Map<String, dynamic>>>? subPublic;
    StreamSubscription<List<Map<String, dynamic>>>? subFinancial;

    DateTime? toDate(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      return null;
    }

    void emitMerged() {
      if (!hasPublic && !hasFinancial) return;
      final combined = <Map<String, dynamic>>[...latestPublic, ...latestFinancial];
      combined.sort((a, b) {
        final da = toDate(a['timestamp']);
        final db = toDate(b['timestamp']);
        if (da == null && db == null) return 0;
        if (da == null) return -1;
        if (db == null) return 1;
        return db.compareTo(da);
      });
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        subPublic = getEnquiryHistoryStream(enquiryId).listen(
          (items) {
            latestPublic = items;
            hasPublic = true;
            emitMerged();
          },
          onError: (Object err, StackTrace st) {
            Log.e('AuditService: public history stream error', error: err, stackTrace: st);
          },
        );
        subFinancial = getEnquiryFinancialHistoryStream(enquiryId).listen(
          (items) {
            latestFinancial = items;
            hasFinancial = true;
            emitMerged();
          },
          onError: (Object err, StackTrace st) {
            Log.e('AuditService: financial history stream error', error: err, stackTrace: st);
          },
        );
      },
      onCancel: () async {
        await subPublic?.cancel();
        await subFinancial?.cancel();
      },
    );

    return controller.stream;
  }

  /// Get change history for an enquiry (one-time fetch)
  Future<List<Map<String, dynamic>>> getEnquiryHistory(String enquiryId) async {
    try {
      final snapshot = await _firestore
          .collection('enquiries')
          .doc(enquiryId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e, st) {
      Log.e(
        'AuditService: error getting enquiry history',
        error: e,
        stackTrace: st,
        data: {'enquiryId': enquiryId},
      );
      return [];
    }
  }

  /// Get change history for a specific field
  Future<List<Map<String, dynamic>>> getFieldHistory(String enquiryId, String fieldName) async {
    try {
      final snapshot = await _firestore
          .collection('enquiries')
          .doc(enquiryId)
          .collection('history')
          .where('field_changed', isEqualTo: fieldName)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e, st) {
      Log.e(
        'AuditService: error getting field history',
        error: e,
        stackTrace: st,
        data: {'enquiryId': enquiryId, 'field': fieldName},
      );
      return [];
    }
  }

  /// Get changes by a specific user
  Future<List<Map<String, dynamic>>> getUserChanges(String userId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('history')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'enquiry_id': doc.reference.parent.parent?.id, ...data};
      }).toList();
    } catch (e, st) {
      Log.e(
        'AuditService: error getting user changes',
        error: e,
        stackTrace: st,
        data: {'userId': userId},
      );
      return [];
    }
  }

  /// Get recent changes across all enquiries
  Future<List<Map<String, dynamic>>> getRecentChanges({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'enquiry_id': doc.reference.parent.parent?.id, ...data};
      }).toList();
    } catch (e, st) {
      Log.e('AuditService: error getting recent changes', error: e, stackTrace: st);
      return [];
    }
  }

  /// Log admin-specific actions for compliance and audit trail
  Future<void> logAdminAction(String action, Map<String, Object?> data) async {
    try {
      final currentUser = _auth.currentUser;

      final packageInfo = await PackageInfo.fromPlatform();
      await _firestore.collection('admin_audit').add({
        'action': action,
        'user_id': currentUser?.uid ?? 'unknown',
        'user_email': currentUser?.email ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
        'app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
      });

      Log.i(
        'AuditService: admin action logged',
        data: {'action': action, 'userId': currentUser?.uid},
      );
    } catch (e, st) {
      Log.e('AuditService: error logging admin action', error: e, stackTrace: st);
    }
  }

  /// Format change description for display
  String formatChangeDescription(Map<String, dynamic> change) {
    final fieldChanged = change['field_changed'] as String? ?? 'Unknown Field';
    final oldValue = change['old_value'];
    final newValue = change['new_value'];
    final userEmail = change['user_email'] as String? ?? 'Unknown User';

    final fieldDisplayName = _getFieldDisplayName(fieldChanged);
    final oldValueDisplay = _formatValue(oldValue);
    final newValueDisplay = _formatValue(newValue);

    return '$userEmail changed $fieldDisplayName from "$oldValueDisplay" to "$newValueDisplay"';
  }

  /// Get display name for field
  String _getFieldDisplayName(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'status':
        return 'Status';
      case 'assignedto':
        return 'Assignment';
      case 'priority':
        return 'Priority';
      case 'totalcost':
        return 'Total Cost';
      case 'advancepaid':
        return 'Advance Paid';
      case 'paymentstatus':
        return 'Payment Status';
      case 'customername':
        return 'Customer Name';
      case 'customerphone':
        return 'Customer Phone';
      case 'eventtype':
        return 'Event Type';
      case 'eventdate':
        return 'Event Date';
      case 'eventlocation':
        return 'Event Location';
      case 'functions':
        return 'Functions';
      case 'description':
        return 'Description';
      case 'notes':
        return 'Notes';
      case 'customeremail':
        return 'Customer Email';
      case 'guestcount':
        return 'Guest Count';
      case 'budgetrange':
        return 'Budget Range';
      case 'source':
        return 'Source';
      case 'quotedamount':
        return 'Quoted Amount';
      case 'quotedat':
        return 'Quoted On';
      case 'images':
        return 'Reference Images';
      case 'lostreason':
        return 'Lost Reason';
      default:
        return fieldName.replaceAll('_', ' ').toTitleCase();
    }
  }

  /// Format value for display
  String _formatValue(dynamic value) {
    if (value == null) return 'Not Set';
    if (value is Timestamp) {
      return '${value.toDate().day}/${value.toDate().month}/${value.toDate().year}';
    }
    if (value is num) {
      return value.toString();
    }
    if (value is String) {
      return value.isEmpty ? 'Empty' : value;
    }
    return value.toString();
  }

  /// Get change summary for an enquiry
  Future<Map<String, dynamic>> getEnquiryChangeSummary(String enquiryId) async {
    try {
      final history = await getEnquiryHistory(enquiryId);

      final summary = <String, dynamic>{
        'total_changes': history.length,
        'last_modified': history.isNotEmpty ? history.first['timestamp'] : null,
        'last_modified_by': history.isNotEmpty ? history.first['user_email'] : null,
        'fields_changed': <String>[],
        'users_involved': <String>[],
      };

      for (final change in history) {
        final fieldChanged = change['field_changed'] as String?;
        final userEmail = change['user_email'] as String?;

        if (fieldChanged != null &&
            !(summary['fields_changed'] as List<String>).contains(fieldChanged)) {
          (summary['fields_changed'] as List<String>).add(fieldChanged);
        }

        if (userEmail != null && !(summary['users_involved'] as List<String>).contains(userEmail)) {
          (summary['users_involved'] as List<String>).add(userEmail);
        }
      }

      return summary;
    } catch (e, st) {
      Log.e('AuditService: error getting change summary', error: e, stackTrace: st);
      return {
        'total_changes': 0,
        'last_modified': null,
        'last_modified_by': null,
        'fields_changed': <String>[],
        'users_involved': <String>[],
      };
    }
  }
}
