import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/logger.dart';

/// Service for tracking audit trail and change history
class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Record a change to an enquiry
  Future<void> recordChange({
    required String enquiryId,
    required String fieldChanged,
    required dynamic oldValue,
    required dynamic newValue,
    String? userId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final changeUserId = userId ?? currentUser?.uid ?? 'unknown';

      await _firestore.collection('enquiries').doc(enquiryId).collection('history').add({
        'field_changed': fieldChanged,
        'old_value': oldValue,
        'new_value': newValue,
        'user_id': changeUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'user_email': currentUser?.email ?? 'unknown',
      });

      Log.d('AuditService: recorded change', data: {'field': fieldChanged, 'enquiryId': enquiryId});
    } catch (e, st) {
      Log.e('AuditService: error recording change', error: e, stackTrace: st);
    }
  }

  /// Record multiple changes at once (for bulk updates)
  Future<void> recordMultipleChanges({
    required String enquiryId,
    required Map<String, Map<String, dynamic>> changes,
    String? userId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final changeUserId = userId ?? currentUser?.uid ?? 'unknown';
      final batch = _firestore.batch();

      for (final entry in changes.entries) {
        final fieldChanged = entry.key;
        final changeData = entry.value;

        final historyRef = _firestore
            .collection('enquiries')
            .doc(enquiryId)
            .collection('history')
            .doc();

        batch.set(historyRef, {
          'field_changed': fieldChanged,
          'old_value': changeData['old_value'],
          'new_value': changeData['new_value'],
          'user_id': changeUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'user_email': currentUser?.email ?? 'unknown',
        });
      }

      await batch.commit();
      Log.d(
        'AuditService: recorded multiple changes',
        data: {'count': changes.length, 'enquiryId': enquiryId},
      );
    } catch (e, st) {
      Log.e('AuditService: error recording multiple changes', error: e, stackTrace: st);
    }
  }

  /// Get change history for an enquiry (real-time stream)
  Stream<List<Map<String, dynamic>>> getEnquiryHistoryStream(String enquiryId) {
    try {
      // Try subcollection approach first (simpler, doesn't require index)
      return _firestore
          .collection('enquiries')
          .doc(enquiryId)
          .collection('history')
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

            // Manual sorting since orderBy might require index
            final docs = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();

            // Sort by timestamp if available (most recent first)
            docs.sort((a, b) {
              final aTime = a['timestamp'];
              final bTime = b['timestamp'];

              // Handle null timestamps - put them at the end
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              // Handle different timestamp formats
              DateTime? aDateTime;
              DateTime? bDateTime;

              if (aTime is Timestamp) {
                aDateTime = aTime.toDate();
              } else if (aTime is DateTime) {
                aDateTime = aTime;
              }

              if (bTime is Timestamp) {
                bDateTime = bTime.toDate();
              } else if (bTime is DateTime) {
                bDateTime = bTime;
              }

              if (aDateTime != null && bDateTime != null) {
                return bDateTime.compareTo(aDateTime); // Descending order (newest first)
              }

              // Fallback: compare by document ID if timestamps are invalid
              return (a['id'] as String? ?? '').compareTo(b['id'] as String? ?? '');
            });

            Log.d(
              'AuditService: returning sorted history items',
              data: {'enquiryId': enquiryId, 'count': docs.length},
            );
            return docs;
          })
          .handleError((error) {
            Log.e(
              'AuditService: history stream error',
              error: error,
              data: {'enquiryId': enquiryId},
            );
            // Try one-time fetch as fallback on error
            return getEnquiryHistory(enquiryId).asStream();
          })
          .handleError((error) {
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
      return getEnquiryHistory(enquiryId).asStream().handleError((error) {
        Log.e(
          'AuditService: fallback fetch failed in catch',
          error: error,
          data: {'enquiryId': enquiryId},
        );
        return <Map<String, dynamic>>[];
      });
    }
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
          .limit(100) // Limit to prevent performance issues
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

      await _firestore.collection('admin_audit').add({
        'action': action,
        'user_id': currentUser?.uid ?? 'unknown',
        'user_email': currentUser?.email ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
        'app_version': '1.0.1+10', // TODO: Get from package_info
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
      case 'description':
        return 'Description';
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

/// Extension to convert string to title case
extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
