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
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final changeUserId = userId ?? currentUser?.uid ?? 'unknown';

      await _firestore
          .collection('enquiries')
          .doc(enquiryId)
          .collection('history')
          .add({
        'field_changed': fieldChanged,
        'old_value': oldValue,
        'new_value': newValue,
        'user_id': changeUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'user_email': currentUser?.email ?? 'unknown',
      });

      print('AuditService: Recorded change to $fieldChanged for enquiry $enquiryId');
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

  /// Get change history for an enquiry
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
        return {
          'id': doc.id,
          ...data,
        };
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
        return {
          'id': doc.id,
          ...data,
        };
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
        return {
          'id': doc.id,
          'enquiry_id': doc.reference.parent.parent?.id,
          ...data,
        };
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
        return {
          'id': doc.id,
          'enquiry_id': doc.reference.parent.parent?.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('AuditService: Error getting recent changes: $e');
      return [];
    }
  }

  /// Format change description for display
  String formatChangeDescription(Map<String, dynamic> change) {
    final fieldChanged = change['field_changed'] as String? ?? 'Unknown Field';
    final oldValue = change['old_value'];
    final newValue = change['new_value'];
    final userEmail = change['user_email'] as String? ?? 'Unknown User';
    final timestamp = change['timestamp'];

    String fieldDisplayName = _getFieldDisplayName(fieldChanged);
    String oldValueDisplay = _formatValue(oldValue);
    String newValueDisplay = _formatValue(newValue);

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
      
      final summary = {
        'total_changes': history.length,
        'last_modified': history.isNotEmpty ? history.first['timestamp'] : null,
        'last_modified_by': history.isNotEmpty ? history.first['user_email'] : null,
        'fields_changed': <String>[],
        'users_involved': <String>[],
      };

      for (final change in history) {
        final fieldChanged = change['field_changed'] as String?;
        final userEmail = change['user_email'] as String?;

        if (fieldChanged != null && !summary['fields_changed'].contains(fieldChanged)) {
          summary['fields_changed'].add(fieldChanged);
        }

        if (userEmail != null && !summary['users_involved'].contains(userEmail)) {
          summary['users_involved'].add(userEmail);
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
}

/// Extension to convert string to title case
extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
} 