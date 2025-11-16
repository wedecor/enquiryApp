# Test Coverage Improvement Guide

## Current Status
- **Current Coverage**: 12% (120/938 lines)
- **Target Coverage**: 30%+
- **Test Files**: 23 files
- **Gap**: Need to add ~180+ lines of tested code

## Priority Areas (Based on Coverage Report)

### 🔴 Critical (High Priority)
1. **Core Authentication** - Security-critical, needs comprehensive tests
2. **User Management** - RBAC logic must be tested
3. **Enquiry Features** - Core business logic
4. **Settings System** - User preferences and configuration

### 🟡 Important (Medium Priority)
5. **CSV Export System** - Data export functionality
6. **Shared Components** - Reusable widgets

---

## Step-by-Step Improvement Strategy

### Phase 1: Core Services (Target: +50 lines coverage)

#### 1.1 FirestoreService Tests
**File**: `test/core/services/firestore_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  late FirestoreService firestoreService;
  late MockFirestore mockFirestore;
  
  setUp(() {
    mockFirestore = MockFirestore();
    firestoreService = FirestoreService();
  });

  group('FirestoreService', () {
    group('createUser', () {
      test('creates user successfully', () async {
        // Test implementation
      });

      test('throws exception on failure', () async {
        // Test error handling
      });
    });

    group('createEnquiry', () {
      test('creates enquiry with all fields', () async {
        // Test successful creation
      });

      test('validates required fields', () async {
        // Test validation
      });
    });

    group('getEnquiries', () {
      test('returns stream of enquiries', () {
        // Test stream functionality
      });
    });
  });
}
```

**Coverage Target**: +30 lines

#### 1.2 FirebaseAuthService Tests
**File**: `test/core/services/firebase_auth_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:we_decor_enquiries/core/services/firebase_auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late FirebaseAuthService authService;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    authService = FirebaseAuthService();
  });

  group('FirebaseAuthService', () {
    group('signInWithEmailAndPassword', () {
      test('signs in successfully', () async {
        // Test successful sign in
      });

      test('handles invalid credentials', () async {
        // Test error handling
      });

      test('handles user not found', () async {
        // Test specific error cases
      });
    });

    group('signOut', () {
      test('signs out successfully', () async {
        // Test sign out flow
      });
    });

    group('currentUser', () {
      test('returns current user when signed in', () {
        // Test user retrieval
      });

      test('returns null when signed out', () {
        // Test null case
      });
    });
  });
}
```

**Coverage Target**: +25 lines

#### 1.3 SessionService Tests
**File**: `test/core/services/session_service_test.dart` (Expand existing)

Add tests for:
- Session state transitions
- Profile loading
- Error handling
- Network connectivity handling

**Coverage Target**: +20 lines

---

### Phase 2: Feature Tests (Target: +80 lines coverage)

#### 2.1 Enquiry Repository Tests
**File**: `test/features/enquiries/data/enquiry_repository_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/enquiry.dart';

void main() {
  group('EnquiryRepository', () {
    group('createEnquiry', () {
      test('creates enquiry successfully', () async {
        // Test creation
      });

      test('validates enquiry data', () async {
        // Test validation
      });
    });

    group('updateEnquiry', () {
      test('updates enquiry successfully', () async {
        // Test update
      });

      test('handles non-existent enquiry', () async {
        // Test error case
      });
    });

    group('getEnquiry', () {
      test('retrieves enquiry by ID', () async {
        // Test retrieval
      });
    });
  });
}
```

**Coverage Target**: +30 lines

#### 2.2 Settings Service Tests
**File**: `test/features/settings/data/user_settings_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/settings/data/user_settings_service.dart';

void main() {
  group('UserSettingsService', () {
    group('loadSettings', () {
      test('loads user settings successfully', () async {
        // Test loading
      });

      test('returns default settings when none exist', () async {
        // Test defaults
      });
    });

    group('saveSettings', () {
      test('saves settings successfully', () async {
        // Test saving
      });
    });
  });
}
```

**Coverage Target**: +20 lines

#### 2.3 CSV Export Tests
**File**: `test/core/export/csv_export_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/export/csv_export.dart';

void main() {
  group('CSVExport', () {
    group('exportEnquiries', () {
      test('exports enquiries to CSV format', () {
        // Test CSV generation
      });

      test('filters columns based on user role', () {
        // Test RBAC filtering
      });

      test('handles empty enquiry list', () {
        // Test edge case
      });
    });
  });
}
```

**Coverage Target**: +30 lines

---

### Phase 3: Widget Tests (Target: +50 lines coverage)

#### 3.1 Shared Widget Tests
**File**: `test/shared/widgets/enquiry_history_widget_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_decor_enquiries/shared/widgets/enquiry_history_widget.dart';

void main() {
  group('EnquiryHistoryWidget', () {
    testWidgets('displays history items', (tester) async {
      // Test widget rendering
    });

    testWidgets('shows empty state when no history', (tester) async {
      // Test empty state
    });

    testWidgets('formats timestamps correctly', (tester) async {
      // Test formatting
    });
  });
}
```

**Coverage Target**: +20 lines

#### 3.2 Status Dropdown Tests
**File**: `test/shared/widgets/status_dropdown_test.dart` (Expand existing)

Add tests for:
- Dropdown selection
- Status change callbacks
- Disabled state handling

**Coverage Target**: +15 lines

#### 3.3 Event Type Autocomplete Tests
**File**: `test/shared/widgets/event_type_autocomplete_test.dart` (Expand existing)

Add tests for:
- Autocomplete filtering
- Selection handling
- Empty state

**Coverage Target**: +15 lines

---

## Testing Best Practices

### 1. Test Structure
```dart
void main() {
  group('ClassName', () {
    group('methodName', () {
      test('description of what is tested', () {
        // Arrange
        // Act
        // Assert
      });
    });
  });
}
```

### 2. Use Mocks for Dependencies
```dart
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockAuth extends Mock implements FirebaseAuth {}
```

### 3. Test Edge Cases
- Null values
- Empty collections
- Error conditions
- Boundary values

### 4. Test Error Handling
```dart
test('handles network errors gracefully', () async {
  when(() => mockService.getData())
      .thenThrow(NetworkException());
  
  expect(() => service.getData(), throwsA(isA<NetworkException>()));
});
```

### 5. Use setUp and tearDown
```dart
setUp(() {
  // Initialize test dependencies
});

tearDown(() {
  // Clean up after tests
});
```

---

## Running Tests and Coverage

### Run All Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Generate Coverage Report
```bash
# Using the existing script
./test/coverage.sh

# Or manually
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Check Coverage Threshold
```bash
# The coverage gate script checks for 30% minimum
./tools/coverage_gate.sh
```

---

## Quick Wins (Start Here)

### 1. Add Tests for Utility Functions
**File**: `test/utils/event_colors_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/utils/event_colors.dart';

void main() {
  group('EventColors', () {
    test('resolves colors for known event types', () {
      // Test color resolution
    });

    test('returns fallback for unknown types', () {
      // Test fallback
    });
  });
}
```

**Estimated Coverage**: +10 lines

### 2. Add Tests for Validators
**File**: `test/features/enquiries/domain/status_validator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/status_validator.dart';

void main() {
  group('StatusValidator', () {
    test('validates valid status', () {
      expect(StatusValidator.isValid('pending'), isTrue);
    });

    test('rejects invalid status', () {
      expect(StatusValidator.isValid('invalid'), isFalse);
    });
  });
}
```

**Estimated Coverage**: +15 lines

### 3. Add Tests for Extensions
**File**: `test/shared/extensions/string_extension_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/shared/widgets/enquiry_history_widget.dart';

void main() {
  group('StringExtension', () {
    test('converts to title case', () {
      expect('hello world'.toTitleCase(), 'Hello World');
    });

    test('handles empty string', () {
      expect(''.toTitleCase(), '');
    });
  });
}
```

**Estimated Coverage**: +10 lines

---

## Coverage Goals by Component

| Component | Current | Target | Gap | Priority |
|-----------|---------|--------|-----|----------|
| Core Authentication | Low | 60% | High | 🔴 Critical |
| User Management | Low | 50% | High | 🔴 Critical |
| Enquiry Features | Low | 40% | Medium | 🔴 Critical |
| Settings System | Low | 40% | Medium | 🔴 Critical |
| CSV Export | Low | 50% | Medium | 🟡 Important |
| Shared Components | Low | 30% | Low | 🟡 Important |

---

## CI/CD Integration

### Add Coverage Check to CI
Update `.github/workflows/ci.yml`:

```yaml
- name: Run tests with coverage
  run: |
    flutter test --coverage
    ./tools/coverage_gate.sh
```

### Coverage Badge
Add coverage badge to README:
```markdown
![Coverage](https://img.shields.io/badge/coverage-30%25-green)
```

---

## Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Test-Driven Development](https://en.wikipedia.org/wiki/Test-driven_development)

---

## Next Steps

1. ✅ **Week 1**: Add tests for Core Services (FirestoreService, AuthService)
2. ✅ **Week 2**: Add tests for Feature Repositories (Enquiry, Settings)
3. ✅ **Week 3**: Add tests for Widgets and Utilities
4. ✅ **Week 4**: Review and improve existing tests

**Target**: Reach 30% coverage within 4 weeks

