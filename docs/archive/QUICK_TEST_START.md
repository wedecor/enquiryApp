# Quick Start: Improving Test Coverage

## 🎯 Goal: Increase from 12% to 30%+ coverage

## 📋 Step-by-Step Action Plan

### Step 1: Run Current Tests
```bash
flutter test
```

### Step 2: Generate Coverage Report
```bash
flutter test --coverage
./test/coverage.sh  # If available
```

### Step 3: Identify Gaps
Check `coverage/html/index.html` to see which files have low coverage.

### Step 4: Start with Easy Wins

#### A. Test Utility Functions (Quick Win)
```bash
# Run the new utility tests
flutter test test/utils/event_colors_test.dart
flutter test test/shared/extensions/string_extension_test.dart
```

#### B. Expand Existing Tests
Look at existing test files and add more test cases:
- `test/core/services/audit_service_test.dart` - Add more edge cases
- `test/shared/widgets/status_dropdown_test.dart` - Add interaction tests
- `test/features/enquiries/presentation/screens/enquiry_form_screen_test.dart` - Add validation tests

### Step 5: Add Tests for Core Services

Priority order:
1. **FirestoreService** - Core data operations
2. **FirebaseAuthService** - Authentication logic
3. **SessionService** - User session management
4. **NetworkService** - Connectivity handling

### Step 6: Add Widget Tests

Focus on:
- Shared widgets (reusable components)
- Form validation widgets
- Status display widgets

### Step 7: Add Integration Tests

For critical user flows:
- User login flow
- Enquiry creation flow
- Status update flow

## 🛠️ Tools & Commands

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/utils/event_colors_test.dart

# With coverage
flutter test --coverage

# Watch mode (auto-rerun on changes)
flutter test --watch
```

### View Coverage
```bash
# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser (macOS)
open coverage/html/index.html

# Open in browser (Linux)
xdg-open coverage/html/index.html
```

### Check Coverage Threshold
```bash
# If coverage gate script exists
./tools/coverage_gate.sh
```

## 📊 Coverage Targets

| Component | Current | Target | Priority |
|-----------|---------|--------|----------|
| Core Services | ~10% | 50% | 🔴 High |
| Features | ~8% | 40% | 🔴 High |
| Widgets | ~15% | 30% | 🟡 Medium |
| Utils | ~5% | 40% | 🟡 Medium |

## ✅ Checklist

- [ ] Run existing tests to ensure they pass
- [ ] Generate baseline coverage report
- [ ] Add tests for utility functions
- [ ] Add tests for core services
- [ ] Add tests for feature repositories
- [ ] Add widget tests for shared components
- [ ] Add integration tests for critical flows
- [ ] Set up CI coverage checks
- [ ] Document test patterns

## 📚 Resources

- See `docs/TEST_COVERAGE_GUIDE.md` for detailed guide
- Flutter Testing: https://docs.flutter.dev/testing
- Mocktail: https://pub.dev/packages/mocktail

## 🚀 Quick Commands Reference

```bash
# Setup
flutter pub get
flutter pub run build_runner build

# Testing
flutter test                    # Run all tests
flutter test --coverage         # With coverage
flutter test --watch            # Watch mode

# Coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```
