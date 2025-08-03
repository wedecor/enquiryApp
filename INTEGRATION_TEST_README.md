# Integration Tests with Firebase Emulator Suite

This document explains how to run the integration tests for the We Decor Enquiries app using Firebase Emulator Suite.

## Prerequisites

1. **Firebase CLI**: Make sure you have Firebase CLI installed
   ```bash
   npm install -g firebase-tools
   ```

2. **Flutter**: Ensure Flutter is properly installed and configured

3. **Firebase Project**: You should have a Firebase project set up (for emulator configuration)

4. **CocoaPods** (for macOS): Required for iOS/macOS plugins
   ```bash
   sudo gem install cocoapods
   ```

## Setup

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase** (if not already done):
   ```bash
   firebase init
   ```

4. **Install CocoaPods** (for macOS users):
   ```bash
   sudo gem install cocoapods
   ```

## Running Integration Tests

### Option 1: Simple Integration Tests (Recommended)

For a quick test without complex UI interactions:

```bash
# Start Firebase emulators
firebase emulators:start --only auth,firestore,storage

# In another terminal, run the simple integration test
flutter test test_integration_simple.dart
```

### Option 2: Full Integration Tests

For complete integration tests with UI interactions:

```bash
# Start Firebase emulators
firebase emulators:start --only auth,firestore,storage

# In another terminal, run the full integration test
flutter test integration_test/app_test.dart
```

### Option 3: Using the Automated Script

The easiest way to run integration tests is using the provided script:

```bash
./run_integration_tests.sh
```

This script will:
- Start Firebase emulators (Auth, Firestore, Storage)
- Wait for emulators to be ready
- Run the integration tests
- Clean up emulators when done

## Test Coverage

The integration tests cover the complete enquiry workflow:

1. **App Startup**: Verifies the app starts correctly
2. **Authentication Flow**: Tests authentication state handling
3. **Dashboard Navigation**: Ensures dashboard loads without errors
4. **Enquiry Creation**: Tests creating enquiries through database operations
5. **Enquiry Assignment**: Tests assigning enquiries to staff members
6. **Enquiry Completion**: Tests marking enquiries as completed
7. **Database Operations**: Tests basic CRUD operations with the emulator

## Test Data

The tests automatically set up the following test data:

- **Test Admin User**: `admin@test.com` (role: admin)
- **Test Staff User**: `staff@test.com` (role: staff)
- **Default Dropdowns**: Event types, statuses, and payment statuses

## Emulator Configuration

The integration tests are configured to use:
- **Auth Emulator**: Port 9099
- **Firestore Emulator**: Port 8080
- **Storage Emulator**: Port 9199
- **Emulator UI**: Port 4000

## Troubleshooting

### Common Issues

1. **CocoaPods not installed**:
   ```bash
   sudo gem install cocoapods
   ```

2. **Emulators not starting**:
   - Check if ports are already in use
   - Ensure Firebase CLI is properly installed
   - Try running `firebase emulators:start` manually first

3. **Tests failing**:
   - Ensure emulators are running before starting tests
   - Check that the app can connect to emulators
   - Verify Firebase configuration in the app

4. **Port conflicts**:
   - Modify the ports in `firebase.json` if needed
   - Update the integration test to use the new ports

### Debug Mode

To run tests in debug mode with more verbose output:

```bash
flutter test test_integration_simple.dart --verbose
```

### Emulator UI

You can access the Firebase Emulator UI at `http://localhost:4000` to:
- View Firestore data
- Monitor authentication
- Debug emulator issues

## Test Structure

The integration tests are organized as follows:

```
├── test_integration_simple.dart    # Simple integration tests (no UI)
├── integration_test/
│   ├── app_test.dart              # Full integration test file
│   ├── firebase.json              # Firebase emulator configuration
│   ├── firestore.rules            # Firestore security rules
│   └── firestore.indexes.json     # Firestore indexes
└── run_integration_tests.sh       # Automated test runner
```

## Continuous Integration

For CI/CD pipelines, you can run the integration tests using:

```bash
# Start emulators in background
firebase emulators:start --only auth,firestore,storage &
EMULATOR_PID=$!

# Wait for emulators
sleep 10

# Run simple tests (recommended for CI)
flutter test test_integration_simple.dart

# Cleanup
kill $EMULATOR_PID
```

## Alternative Testing Approaches

### 1. Simple Database Tests

If you encounter issues with the full integration tests, you can run simple database tests:

```bash
flutter test test_integration_simple.dart
```

### 2. Unit Tests

For faster feedback during development, run unit tests:

```bash
flutter test
```

### 3. Widget Tests

For UI component testing:

```bash
flutter test test/features/
```

## Notes

- The simple integration tests use direct database operations rather than UI interactions to ensure reliability
- Tests are designed to be independent and clean up after themselves
- The emulator configuration allows for fast, isolated testing without affecting production data
- All tests should pass consistently when run against the emulator suite
- If you encounter CocoaPods issues, use the simple integration tests instead 