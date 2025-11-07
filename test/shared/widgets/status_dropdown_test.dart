import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Status Dropdown Duplication Prevention Logic Tests', () {
    group('Case-insensitive duplication prevention', () {
      test('should detect duplicate statuses regardless of case', () {
        final existingStatuses = ['New', 'In Progress', 'Completed'];

        // Test exact match
        expect(_isDuplicate('New', existingStatuses), isTrue);

        // Test lowercase
        expect(_isDuplicate('new', existingStatuses), isTrue);

        // Test uppercase
        expect(_isDuplicate('NEW', existingStatuses), isTrue);

        // Test mixed case
        expect(_isDuplicate('NeW', existingStatuses), isTrue);

        // Test with spaces
        expect(_isDuplicate('  New  ', existingStatuses), isTrue);
      });

      test('should allow new unique statuses', () {
        final existingStatuses = ['New', 'In Progress'];

        // Test new unique statuses
        expect(_isDuplicate('Completed', existingStatuses), isFalse);
        expect(_isDuplicate('Cancelled', existingStatuses), isFalse);
        expect(_isDuplicate('On Hold', existingStatuses), isFalse);
      });

      test('should handle empty and whitespace-only inputs', () {
        final existingStatuses = ['New', 'In Progress'];

        // Test empty string
        expect(_isDuplicate('', existingStatuses), isFalse);

        // Test whitespace only
        expect(_isDuplicate('   ', existingStatuses), isFalse);
        expect(_isDuplicate('\t\n', existingStatuses), isFalse);
      });

      test('should handle edge cases', () {
        final existingStatuses = ['New', 'In Progress'];

        // Test null input
        expect(_isDuplicate(null, existingStatuses), isFalse);

        // Test empty list
        expect(_isDuplicate('New', []), isFalse);

        // Test with special characters
        expect(_isDuplicate('In Progress & Review', existingStatuses), isFalse);
        expect(_isDuplicate('In-Progress', existingStatuses), isFalse);
      });
    });

    group('Input validation and sanitization', () {
      test('should trim whitespace from input', () {
        final existingStatuses = ['New', 'In Progress'];

        // Test leading whitespace
        expect(_isDuplicate('  New', existingStatuses), isTrue);

        // Test trailing whitespace
        expect(_isDuplicate('New  ', existingStatuses), isTrue);

        // Test both leading and trailing whitespace
        expect(_isDuplicate('  New  ', existingStatuses), isTrue);
      });

      test('should handle case normalization', () {
        final existingStatuses = ['New', 'In Progress'];

        // Test various case combinations
        expect(_isDuplicate('new', existingStatuses), isTrue);
        expect(_isDuplicate('NEW', existingStatuses), isTrue);
        expect(_isDuplicate('NeW', existingStatuses), isTrue);
        expect(_isDuplicate('nEw', existingStatuses), isTrue);
      });

      test('should validate input format', () {
        // Test valid inputs
        expect(_isValidStatus('Completed'), isTrue);
        expect(_isValidStatus('In Progress & Review'), isTrue);
        expect(_isValidStatus('On-Hold'), isTrue);

        // Test invalid inputs
        expect(_isValidStatus(''), isFalse);
        expect(_isValidStatus('   '), isFalse);
        expect(_isValidStatus(null), isFalse);
      });
    });

    group('Business logic validation', () {
      test('should enforce uniqueness constraints', () {
        final existingStatuses = ['New', 'In Progress', 'Completed'];

        // Test that similar names are considered duplicates
        expect(_isDuplicate('New', existingStatuses), isTrue);
        expect(_isDuplicate('new', existingStatuses), isTrue);
        expect(_isDuplicate('New ', existingStatuses), isTrue);
        expect(_isDuplicate(' New', existingStatuses), isTrue);

        // Test that different names are not duplicates
        expect(_isDuplicate('New Review', existingStatuses), isFalse);
        expect(_isDuplicate('New Status', existingStatuses), isFalse);
        expect(_isDuplicate('New Pending', existingStatuses), isFalse);
      });

      test('should handle special characters and formatting', () {
        final existingStatuses = ['In Progress & Review', 'On-Hold', 'Completed'];

        // Test exact matches with special characters
        expect(_isDuplicate('In Progress & Review', existingStatuses), isTrue);
        expect(_isDuplicate('On-Hold', existingStatuses), isTrue);

        // Test case variations with special characters
        expect(_isDuplicate('in progress & review', existingStatuses), isTrue);
        expect(_isDuplicate('on-hold', existingStatuses), isTrue);

        // Test similar but different names
        expect(_isDuplicate('In Progress Review', existingStatuses), isFalse);
        expect(_isDuplicate('On Hold', existingStatuses), isFalse);
      });

      test('should validate status naming conventions', () {
        // Test valid status names
        expect(_isValidStatus('New'), isTrue);
        expect(_isValidStatus('In Progress'), isTrue);
        expect(_isValidStatus('Completed'), isTrue);
        expect(_isValidStatus('In Progress & Review'), isTrue);
        expect(_isValidStatus('On-Hold'), isTrue);
        expect(_isValidStatus('Cancelled'), isTrue);

        // Test invalid status names
        expect(_isValidStatus(''), isFalse);
        expect(_isValidStatus('   '), isFalse);
        expect(_isValidStatus('a'), isFalse); // Too short
        expect(_isValidStatus('A'), isFalse); // Too short
        expect(_isValidStatus('123'), isFalse); // Numbers only
        expect(_isValidStatus('!@#'), isFalse); // Special characters only
      });
    });

    group('Payment status specific logic', () {
      test('should handle payment status duplication prevention', () {
        final existingPaymentStatuses = ['Pending', 'Paid', 'Overdue'];

        // Test exact matches
        expect(_isDuplicate('Pending', existingPaymentStatuses), isTrue);
        expect(_isDuplicate('Paid', existingPaymentStatuses), isTrue);
        expect(_isDuplicate('Overdue', existingPaymentStatuses), isTrue);

        // Test case variations
        expect(_isDuplicate('pending', existingPaymentStatuses), isTrue);
        expect(_isDuplicate('PAID', existingPaymentStatuses), isTrue);
        expect(_isDuplicate('overdue', existingPaymentStatuses), isTrue);

        // Test new unique payment statuses
        expect(_isDuplicate('Partial', existingPaymentStatuses), isFalse);
        expect(_isDuplicate('Refunded', existingPaymentStatuses), isFalse);
        expect(_isDuplicate('Cancelled', existingPaymentStatuses), isFalse);
      });

      test('should validate payment status format', () {
        // Test valid payment status names
        expect(_isValidPaymentStatus('Pending'), isTrue);
        expect(_isValidPaymentStatus('Paid'), isTrue);
        expect(_isValidPaymentStatus('Overdue'), isTrue);
        expect(_isValidPaymentStatus('Partially Paid'), isTrue);
        expect(_isValidPaymentStatus('Payment Failed'), isTrue);

        // Test invalid payment status names
        expect(_isValidPaymentStatus(''), isFalse);
        expect(_isValidPaymentStatus('   '), isFalse);
        expect(_isValidPaymentStatus('p'), isFalse); // Too short
        expect(_isValidPaymentStatus('123'), isFalse); // Numbers only
      });
    });

    group('Role-based access control for status management', () {
      test('should enforce admin-only status creation', () {
        // Test that only admins can create new statuses
        expect(_canCreateStatus(true), isTrue); // Admin
        expect(_canCreateStatus(false), isFalse); // Staff

        // Test that staff cannot create statuses even with valid input
        expect(_canCreateStatusWithInput(false, 'New Status'), isFalse);
        expect(_canCreateStatusWithInput(true, 'New Status'), isTrue);
      });

      test('should validate status creation permissions', () {
        // Test admin permissions
        expect(_hasStatusCreationPermission(true), isTrue);
        expect(_hasStatusCreationPermission(false), isFalse);

        // Test that permission is required for all status types
        expect(_canCreateStatusType(true, 'statuses'), isTrue);
        expect(_canCreateStatusType(true, 'payment_statuses'), isTrue);
        expect(_canCreateStatusType(false, 'statuses'), isFalse);
        expect(_canCreateStatusType(false, 'payment_statuses'), isFalse);
      });
    });
  });
}

/// Helper function to check if a status is a duplicate
bool _isDuplicate(String? newStatus, List<String> existingStatuses) {
  if (newStatus == null || newStatus.trim().isEmpty) {
    return false;
  }

  final normalizedNewStatus = newStatus.trim().toLowerCase();

  return existingStatuses.any((existingStatus) {
    return existingStatus.trim().toLowerCase() == normalizedNewStatus;
  });
}

/// Helper function to validate status format
bool _isValidStatus(String? status) {
  if (status == null || status.trim().isEmpty) {
    return false;
  }

  final trimmedStatus = status.trim();

  // Must be at least 2 characters long
  if (trimmedStatus.length < 2) {
    return false;
  }

  // Must contain at least one letter
  if (!RegExp(r'[a-zA-Z]').hasMatch(trimmedStatus)) {
    return false;
  }

  return true;
}

/// Helper function to validate payment status format
bool _isValidPaymentStatus(String? paymentStatus) {
  if (paymentStatus == null || paymentStatus.trim().isEmpty) {
    return false;
  }

  final trimmedStatus = paymentStatus.trim();

  // Must be at least 2 characters long
  if (trimmedStatus.length < 2) {
    return false;
  }

  // Must contain at least one letter
  if (!RegExp(r'[a-zA-Z]').hasMatch(trimmedStatus)) {
    return false;
  }

  return true;
}

/// Helper function to check if user can create statuses
bool _canCreateStatus(bool isAdmin) {
  return isAdmin;
}

/// Helper function to check if user can create statuses with input validation
bool _canCreateStatusWithInput(bool isAdmin, String statusName) {
  if (!isAdmin) return false;
  return _isValidStatus(statusName);
}

/// Helper function to check if user has status creation permission
bool _hasStatusCreationPermission(bool isAdmin) {
  return isAdmin;
}

/// Helper function to check if user can create specific status type
bool _canCreateStatusType(bool isAdmin, String statusType) {
  if (!isAdmin) return false;

  // Validate status type
  return statusType == 'statuses' || statusType == 'payment_statuses';
}
