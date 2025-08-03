import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Audit Service Logic Tests', () {
    group('Change tracking logic', () {
      test('should detect field changes correctly', () {
        // Test that changes are detected
        expect(_hasFieldChanged('New', 'In Progress'), isTrue);
        expect(_hasFieldChanged('New', 'New'), isFalse);
        expect(_hasFieldChanged(null, 'New'), isTrue);
        expect(_hasFieldChanged('New', null), isTrue);
        expect(_hasFieldChanged(null, null), isFalse);
      });

      test('should handle different data types', () {
        // Test string changes
        expect(_hasFieldChanged('Old Value', 'New Value'), isTrue);
        expect(_hasFieldChanged('Same Value', 'Same Value'), isFalse);
        
        // Test numeric changes
        expect(_hasFieldChanged(100, 200), isTrue);
        expect(_hasFieldChanged(100, 100), isFalse);
        
        // Test boolean changes
        expect(_hasFieldChanged(true, false), isTrue);
        expect(_hasFieldChanged(false, false), isFalse);
        
        // Test mixed type changes
        expect(_hasFieldChanged('100', 100), isTrue);
        expect(_hasFieldChanged(100, '100'), isTrue);
      });

      test('should handle edge cases', () {
        // Test empty strings
        expect(_hasFieldChanged('', 'New'), isTrue);
        expect(_hasFieldChanged('Old', ''), isTrue);
        expect(_hasFieldChanged('', ''), isFalse);
        
        // Test whitespace - after trimming, these should be considered the same
        expect(_hasFieldChanged('  Old  ', 'Old'), isFalse);
        expect(_hasFieldChanged('Old', '  Old  '), isFalse);
        expect(_hasFieldChanged('  Old  ', '  Old  '), isFalse);
        
        // Test actual whitespace differences
        expect(_hasFieldChanged('Old ', 'Old'), isFalse);
        expect(_hasFieldChanged('Old', ' Old'), isFalse);
        expect(_hasFieldChanged('Old', 'Old '), isFalse);
      });
    });

    group('Change description formatting', () {
      test('should format change descriptions correctly', () {
        final change = {
          'field_changed': 'status',
          'old_value': 'New',
          'new_value': 'In Progress',
          'user_email': 'test@example.com',
          'timestamp': Timestamp.now(),
        };

        final description = _formatChangeDescription(change);
        expect(description, equals('test@example.com changed Status from "New" to "In Progress"'));
      });

      test('should handle null values in change descriptions', () {
        final change = {
          'field_changed': 'assignedTo',
          'old_value': null,
          'new_value': 'user123',
          'user_email': 'test@example.com',
          'timestamp': Timestamp.now(),
        };

        final description = _formatChangeDescription(change);
        expect(description, equals('test@example.com changed Assignment from "Not Set" to "user123"'));
      });

      test('should handle empty string values', () {
        final change = {
          'field_changed': 'description',
          'old_value': '',
          'new_value': 'Some description',
          'user_email': 'test@example.com',
          'timestamp': Timestamp.now(),
        };

        final description = _formatChangeDescription(change);
        expect(description, equals('test@example.com changed Description from "Empty" to "Some description"'));
      });

      test('should handle timestamp values', () {
        final oldDate = DateTime(2024, 1, 15);
        final newDate = DateTime(2024, 1, 20);
        final change = {
          'field_changed': 'eventDate',
          'old_value': Timestamp.fromDate(oldDate),
          'new_value': Timestamp.fromDate(newDate),
          'user_email': 'test@example.com',
          'timestamp': Timestamp.now(),
        };

        final description = _formatChangeDescription(change);
        expect(description, contains('15/1/2024'));
        expect(description, contains('20/1/2024'));
      });
    });

    group('Field display name formatting', () {
      test('should return correct display names for known fields', () {
        expect(_getFieldDisplayName('status'), equals('Status'));
        expect(_getFieldDisplayName('assignedTo'), equals('Assignment'));
        expect(_getFieldDisplayName('priority'), equals('Priority'));
        expect(_getFieldDisplayName('totalCost'), equals('Total Cost'));
        expect(_getFieldDisplayName('advancePaid'), equals('Advance Paid'));
        expect(_getFieldDisplayName('paymentStatus'), equals('Payment Status'));
        expect(_getFieldDisplayName('customerName'), equals('Customer Name'));
        expect(_getFieldDisplayName('customerPhone'), equals('Customer Phone'));
        expect(_getFieldDisplayName('eventType'), equals('Event Type'));
        expect(_getFieldDisplayName('eventDate'), equals('Event Date'));
        expect(_getFieldDisplayName('eventLocation'), equals('Event Location'));
        expect(_getFieldDisplayName('description'), equals('Description'));
      });

      test('should format unknown fields with title case', () {
        expect(_getFieldDisplayName('custom_field'), equals('Custom Field'));
        expect(_getFieldDisplayName('someOtherField'), equals('Someotherfield'));
        expect(_getFieldDisplayName('new_field_name'), equals('New Field Name'));
      });

      test('should handle edge cases', () {
        expect(_getFieldDisplayName(''), equals(''));
        expect(_getFieldDisplayName('a'), equals('A'));
        expect(_getFieldDisplayName('A'), equals('A'));
        expect(_getFieldDisplayName('123'), equals('123'));
      });
    });

    group('Value formatting', () {
      test('should format different value types correctly', () {
        // Test null values
        expect(_formatValue(null), equals('Not Set'));
        
        // Test timestamp values
        final date = DateTime(2024, 1, 15);
        expect(_formatValue(Timestamp.fromDate(date)), equals('15/1/2024'));
        
        // Test numeric values
        expect(_formatValue(100), equals('100'));
        expect(_formatValue(100.5), equals('100.5'));
        
        // Test string values
        expect(_formatValue('Test String'), equals('Test String'));
        expect(_formatValue(''), equals('Empty'));
        
        // Test boolean values
        expect(_formatValue(true), equals('true'));
        expect(_formatValue(false), equals('false'));
      });

      test('should handle edge cases in value formatting', () {
        // Test empty string
        expect(_formatValue(''), equals('Empty'));
        
        // Test whitespace string
        expect(_formatValue('   '), equals('   '));
        
        // Test zero values
        expect(_formatValue(0), equals('0'));
        expect(_formatValue(0.0), equals('0.0'));
      });
    });

    group('Change summary logic', () {
      test('should calculate change summary correctly', () {
        final changes = [
          {
            'field_changed': 'status',
            'user_email': 'user1@example.com',
            'timestamp': Timestamp.now(),
          },
          {
            'field_changed': 'priority',
            'user_email': 'user2@example.com',
            'timestamp': Timestamp.now(),
          },
          {
            'field_changed': 'status',
            'user_email': 'user1@example.com',
            'timestamp': Timestamp.now(),
          },
        ];

        final summary = _calculateChangeSummary(changes);
        
        expect(summary['total_changes'], equals(3));
        expect(summary['fields_changed'], containsAll(['status', 'priority']));
        expect(summary['users_involved'], containsAll(['user1@example.com', 'user2@example.com']));
        expect(summary['last_modified_by'], equals('user1@example.com'));
      });

      test('should handle empty change list', () {
        final summary = _calculateChangeSummary([]);
        
        expect(summary['total_changes'], equals(0));
        expect(summary['last_modified'], isNull);
        expect(summary['last_modified_by'], isNull);
        expect(summary['fields_changed'], isEmpty);
        expect(summary['users_involved'], isEmpty);
      });

      test('should handle single change', () {
        final changes = [
          {
            'field_changed': 'status',
            'user_email': 'user1@example.com',
            'timestamp': Timestamp.now(),
          },
        ];

        final summary = _calculateChangeSummary(changes);
        
        expect(summary['total_changes'], equals(1));
        expect(summary['fields_changed'], equals(['status']));
        expect(summary['users_involved'], equals(['user1@example.com']));
        expect(summary['last_modified_by'], equals('user1@example.com'));
      });
    });

    group('Timestamp formatting', () {
      test('should format relative timestamps correctly', () {
        final now = DateTime.now();
        
        // Test "just now"
        final justNow = now.subtract(const Duration(seconds: 30));
        expect(_formatRelativeTimestamp(Timestamp.fromDate(justNow)), equals('Just now'));
        
        // Test minutes ago
        final minutesAgo = now.subtract(const Duration(minutes: 5));
        expect(_formatRelativeTimestamp(Timestamp.fromDate(minutesAgo)), equals('5m ago'));
        
        // Test hours ago
        final hoursAgo = now.subtract(const Duration(hours: 2));
        expect(_formatRelativeTimestamp(Timestamp.fromDate(hoursAgo)), equals('2h ago'));
        
        // Test days ago
        final daysAgo = now.subtract(const Duration(days: 3));
        expect(_formatRelativeTimestamp(Timestamp.fromDate(daysAgo)), equals('3d ago'));
      });

      test('should handle future timestamps', () {
        final now = DateTime.now();
        final future = now.add(const Duration(hours: 1));
        expect(_formatRelativeTimestamp(Timestamp.fromDate(future)), equals('Just now'));
      });
    });
  });
}

/// Helper function to check if a field has changed
bool _hasFieldChanged(dynamic oldValue, dynamic newValue) {
  if (oldValue == null && newValue == null) return false;
  if (oldValue == null || newValue == null) return true;
  
  // Handle string trimming for comparison
  if (oldValue is String && newValue is String) {
    final oldTrimmed = oldValue.trim();
    final newTrimmed = newValue.trim();
    
    // Both empty strings are considered the same
    if (oldTrimmed.isEmpty && newTrimmed.isEmpty) return false;
    
    // One empty and one non-empty are different
    if (oldTrimmed.isEmpty || newTrimmed.isEmpty) return true;
    
    // Compare trimmed strings
    return oldTrimmed != newTrimmed;
  }
  
  return oldValue != newValue;
}

/// Helper function to format change description
String _formatChangeDescription(Map<String, dynamic> change) {
  final fieldChanged = change['field_changed'] as String? ?? 'Unknown Field';
  final oldValue = change['old_value'];
  final newValue = change['new_value'];
  final userEmail = change['user_email'] as String? ?? 'Unknown User';

  String fieldDisplayName = _getFieldDisplayName(fieldChanged);
  String oldValueDisplay = _formatValue(oldValue);
  String newValueDisplay = _formatValue(newValue);

  return '$userEmail changed $fieldDisplayName from "$oldValueDisplay" to "$newValueDisplay"';
}

/// Helper function to get field display name
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

/// Helper function to format value for display
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

/// Helper function to calculate change summary
Map<String, dynamic> _calculateChangeSummary(List<Map<String, dynamic>> changes) {
  final summary = {
    'total_changes': changes.length,
    'last_modified': changes.isNotEmpty ? changes.first['timestamp'] : null,
    'last_modified_by': changes.isNotEmpty ? changes.first['user_email'] : null,
    'fields_changed': <String>[],
    'users_involved': <String>[],
  };

  for (final change in changes) {
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
}

/// Helper function to format relative timestamp
String _formatRelativeTimestamp(Timestamp timestamp) {
  final now = DateTime.now();
  final changeTime = timestamp.toDate();
  final difference = now.difference(changeTime);

  if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}

/// Extension to convert string to title case
extension StringExtension on String {
  String toTitleCase() {
    if (this.isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
} 