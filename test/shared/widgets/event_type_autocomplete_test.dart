import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Event Type Duplication Prevention Logic Tests', () {
    group('Case-insensitive duplication prevention', () {
      test('should detect duplicate event types regardless of case', () {
        final existingEventTypes = [
          'Wedding',
          'Birthday Party',
          'Corporate Event',
        ];

        // Test exact match
        expect(_isDuplicate('Wedding', existingEventTypes), isTrue);

        // Test lowercase
        expect(_isDuplicate('wedding', existingEventTypes), isTrue);

        // Test uppercase
        expect(_isDuplicate('WEDDING', existingEventTypes), isTrue);

        // Test mixed case
        expect(_isDuplicate('WeDdInG', existingEventTypes), isTrue);

        // Test with spaces
        expect(_isDuplicate('  Wedding  ', existingEventTypes), isTrue);
      });

      test('should allow new unique event types', () {
        final existingEventTypes = ['Wedding', 'Birthday Party'];

        // Test new unique types
        expect(_isDuplicate('Corporate Event', existingEventTypes), isFalse);
        expect(_isDuplicate('Anniversary', existingEventTypes), isFalse);
        expect(_isDuplicate('Graduation', existingEventTypes), isFalse);
      });

      test('should handle empty and whitespace-only inputs', () {
        final existingEventTypes = ['Wedding', 'Birthday Party'];

        // Test empty string
        expect(_isDuplicate('', existingEventTypes), isFalse);

        // Test whitespace only
        expect(_isDuplicate('   ', existingEventTypes), isFalse);
        expect(_isDuplicate('\t\n', existingEventTypes), isFalse);
      });

      test('should handle edge cases', () {
        final existingEventTypes = ['Wedding', 'Birthday Party'];

        // Test null input
        expect(_isDuplicate(null, existingEventTypes), isFalse);

        // Test empty list
        expect(_isDuplicate('Wedding', []), isFalse);

        // Test with special characters
        expect(
          _isDuplicate('Wedding & Reception', existingEventTypes),
          isFalse,
        );
        expect(_isDuplicate('Wedding-Reception', existingEventTypes), isFalse);
      });
    });

    group('Input validation and sanitization', () {
      test('should trim whitespace from input', () {
        final existingEventTypes = ['Wedding', 'Birthday Party'];

        // Test leading whitespace
        expect(_isDuplicate('  Wedding', existingEventTypes), isTrue);

        // Test trailing whitespace
        expect(_isDuplicate('Wedding  ', existingEventTypes), isTrue);

        // Test both leading and trailing whitespace
        expect(_isDuplicate('  Wedding  ', existingEventTypes), isTrue);
      });

      test('should handle case normalization', () {
        final existingEventTypes = ['Wedding', 'Birthday Party'];

        // Test various case combinations
        expect(_isDuplicate('wedding', existingEventTypes), isTrue);
        expect(_isDuplicate('WEDDING', existingEventTypes), isTrue);
        expect(_isDuplicate('WeDdInG', existingEventTypes), isTrue);
        expect(_isDuplicate('wEdDiNg', existingEventTypes), isTrue);
      });

      test('should validate input format', () {
        // Test valid inputs
        expect(_isValidEventType('Corporate Event'), isTrue);
        expect(_isValidEventType('Wedding & Reception'), isTrue);
        expect(_isValidEventType('Birthday-Party'), isTrue);

        // Test invalid inputs
        expect(_isValidEventType(''), isFalse);
        expect(_isValidEventType('   '), isFalse);
        expect(_isValidEventType(null), isFalse);
      });
    });

    group('Business logic validation', () {
      test('should enforce uniqueness constraints', () {
        final existingEventTypes = [
          'Wedding',
          'Birthday Party',
          'Corporate Event',
        ];

        // Test that similar names are considered duplicates
        expect(_isDuplicate('Wedding', existingEventTypes), isTrue);
        expect(_isDuplicate('wedding', existingEventTypes), isTrue);
        expect(_isDuplicate('Wedding ', existingEventTypes), isTrue);
        expect(_isDuplicate(' Wedding', existingEventTypes), isTrue);

        // Test that different names are not duplicates
        expect(_isDuplicate('Wedding Reception', existingEventTypes), isFalse);
        expect(_isDuplicate('Wedding Party', existingEventTypes), isFalse);
        expect(_isDuplicate('Wedding Ceremony', existingEventTypes), isFalse);
      });

      test('should handle special characters and formatting', () {
        final existingEventTypes = [
          'Wedding & Reception',
          'Birthday-Party',
          'Corporate Event',
        ];

        // Test exact matches with special characters
        expect(_isDuplicate('Wedding & Reception', existingEventTypes), isTrue);
        expect(_isDuplicate('Birthday-Party', existingEventTypes), isTrue);

        // Test case variations with special characters
        expect(_isDuplicate('wedding & reception', existingEventTypes), isTrue);
        expect(_isDuplicate('birthday-party', existingEventTypes), isTrue);

        // Test similar but different names
        expect(_isDuplicate('Wedding Reception', existingEventTypes), isFalse);
        expect(_isDuplicate('Birthday Party', existingEventTypes), isFalse);
      });

      test('should validate event type naming conventions', () {
        // Test valid event type names
        expect(_isValidEventType('Wedding'), isTrue);
        expect(_isValidEventType('Birthday Party'), isTrue);
        expect(_isValidEventType('Corporate Event'), isTrue);
        expect(_isValidEventType('Wedding & Reception'), isTrue);
        expect(_isValidEventType('Birthday-Party'), isTrue);
        expect(_isValidEventType('Graduation Ceremony'), isTrue);

        // Test invalid event type names
        expect(_isValidEventType(''), isFalse);
        expect(_isValidEventType('   '), isFalse);
        expect(_isValidEventType('a'), isFalse); // Too short
        expect(_isValidEventType('A'), isFalse); // Too short
        expect(_isValidEventType('123'), isFalse); // Numbers only
        expect(_isValidEventType('!@#'), isFalse); // Special characters only
      });
    });
  });
}

/// Helper function to check if an event type is a duplicate
bool _isDuplicate(String? newEventType, List<String> existingEventTypes) {
  if (newEventType == null || newEventType.trim().isEmpty) {
    return false;
  }

  final normalizedNewType = newEventType.trim().toLowerCase();

  return existingEventTypes.any((existingType) {
    return existingType.trim().toLowerCase() == normalizedNewType;
  });
}

/// Helper function to validate event type format
bool _isValidEventType(String? eventType) {
  if (eventType == null || eventType.trim().isEmpty) {
    return false;
  }

  final trimmedType = eventType.trim();

  // Must be at least 2 characters long
  if (trimmedType.length < 2) {
    return false;
  }

  // Must contain at least one letter
  if (!RegExp(r'[a-zA-Z]').hasMatch(trimmedType)) {
    return false;
  }

  return true;
}
