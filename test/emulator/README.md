# Emulator Integration Tests

## Setup Required

1. **Start Firebase Emulators:**
   ```bash
   firebase emulators:start --only auth,firestore
   ```

2. **Run Integration Tests:**
   ```bash
   flutter test test/emulator/
   ```

## Test Coverage

- **Auth Flow**: User creation, sign-in, sign-out
- **Enquiry CRUD**: Create, read, update with security rules enforcement
- **Security Rules**: Verify RBAC (Role-Based Access Control)

## Note

These tests require Firebase emulators to be running. They test against localhost:8080 (Firestore) and localhost:9099 (Auth).

For CI/CD, these tests should be run in a Docker container with Firebase emulators or skipped if emulators are not available.
