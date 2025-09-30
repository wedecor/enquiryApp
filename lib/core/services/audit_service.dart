import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    String? notes,
    String? changeType, // 'status_update', 'assignment', 'edit', 'create', 'delete'
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final changeUserId = userId ?? currentUser?.uid ?? 'unknown';

      // Enhanced audit record with more context
      final auditRecord = {
        'field_changed': fieldChanged,
        'old_value': oldValue,
        'new_value': newValue,
        'user_id': changeUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'user_email': currentUser?.email ?? 'unknown',
        'change_type': changeType ?? 'edit',
        'session_id': _generateSessionId(),
        'device_info': {
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
        },
        if (notes != null) 'notes': notes,
        if (additionalContext != null) 'context': additionalContext,
      };

      await _firestore.collection('enquiries').doc(enquiryId).collection('history').add(auditRecord);

      // Also log to admin audit for important changes
      if (_isImportantChange(fieldChanged, changeType)) {
        await _logToAdminAudit('enquiry_change', {
          'enquiry_id': enquiryId,
          'field_changed': fieldChanged,
          'change_type': changeType,
          'old_value': oldValue,
          'new_value': newValue,
        });
      }

      print('AuditService: Recorded change to $fieldChanged for enquiry $enquiryId (type: ${changeType ?? 'edit'})');
    } catch (e) {
      print('AuditService: Error recording change: $e');
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
      print('AuditService: Recorded ${changes.length} changes for enquiry $enquiryId');
    } catch (e) {
      print('AuditService: Error recording multiple changes: $e');
    }
  }

  /// Get change history for an enquiry (real-time stream)
  Stream<List<Map<String, dynamic>>> getEnquiryHistoryStream(String enquiryId) {
    try {
      print('AuditService: Starting history stream for enquiry $enquiryId');

      // Try subcollection approach first (simpler, doesn't require index)
      return _firestore
          .collection('enquiries')
          .doc(enquiryId)
          .collection('history')
          .snapshots()
          .timeout(const Duration(seconds: 10))
          .map((snapshot) {
            print(
              'AuditService: Received ${snapshot.docs.length} history documents for $enquiryId',
            );

            if (snapshot.docs.isEmpty) {
              print('AuditService: No history found for enquiry $enquiryId');
              return <Map<String, dynamic>>[];
            }

            // Manual sorting since orderBy might require index
            final docs = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();

            // Sort by timestamp if available
            docs.sort((a, b) {
              final aTime = a['timestamp'];
              final bTime = b['timestamp'];

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.compareTo(aTime); // Descending order
              }

              return 0;
            });

            print('AuditService: Returning ${docs.length} sorted history items');
            return docs;
          })
          .handleError((error) {
            print('AuditService: History stream error for $enquiryId: $error');
            // Return empty list on error instead of propagating
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      print('AuditService: Failed to create history stream for $enquiryId: $e');
      // Return a stream with empty list if setup fails
      return Stream.value(<Map<String, dynamic>>[]);
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
    } catch (e) {
      print('AuditService: Error getting enquiry history: $e');
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
    } catch (e) {
      print('AuditService: Error getting field history: $e');
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
    } catch (e) {
      print('AuditService: Error getting user changes: $e');
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
    } catch (e) {
      print('AuditService: Error getting recent changes: $e');
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

      print('AuditService: Admin action logged - $action');
    } catch (e) {
      print('AuditService: Error logging admin action: $e');
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
    } catch (e) {
      print('AuditService: Error getting change summary: $e');
      return {
        'total_changes': 0,
        'last_modified': null,
        'last_modified_by': null,
        'fields_changed': <String>[],
        'users_involved': <String>[],
      };
    }
  }

  /// Generate a unique session ID for tracking related changes
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? 'anonymous'}';
  }

  /// Check if a change is important enough to log to admin audit
  bool _isImportantChange(String fieldChanged, String? changeType) {
    final importantFields = ['status', 'assignedTo', 'priority', 'totalCost', 'paymentStatus'];
    final importantTypes = ['status_update', 'assignment', 'payment_change'];
    
    return importantFields.contains(fieldChanged) || importantTypes.contains(changeType);
  }

  /// Log to admin audit collection
  Future<void> _logToAdminAudit(String action, Map<String, Object?> data) async {
    try {
      final currentUser = _auth.currentUser;

      await _firestore.collection('admin_audit').add({
        'action': action,
        'user_id': currentUser?.uid ?? 'unknown',
        'user_email': currentUser?.email ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
        'session_id': _generateSessionId(),
        'app_version': '1.0.1+10', // TODO: Get from package_info
      });
    } catch (e) {
      print('AuditService: Error logging to admin audit: $e');
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
