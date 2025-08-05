# 🔥 Firestore Database Setup Guide

This guide explains how to set up and manage the Firestore database structure for the We Decor Enquiries application.

## 📋 Database Schema Overview

### Collections Structure

```
📁 users/
├── {uid}/
    ├── name (string)
    ├── email (string)
    ├── phone (string)
    ├── role ("admin" | "staff")
    └── fcmToken (string, optional)

📁 enquiries/
├── {auto-generated-id}/
    ├── customerName (string)
    ├── customerPhone (string)
    ├── location (string)
    ├── eventDate (timestamp)
    ├── eventType (string)
    ├── eventStatus (string) - default: "Enquired"
    ├── notes (string)
    ├── referenceImages (array of strings)
    ├── createdBy (uid reference)
    ├── assignedTo (uid reference, optional)
    ├── createdAt (timestamp)
    ├── 📁 financial/
    │   └── {auto-generated-id}/
    │       ├── totalCost (number)
    │       ├── advancePaid (number)
    │       └── paymentStatus (string)
    └── 📁 history/
        └── {auto-generated-id}/
            ├── fieldChanged (string)
            ├── oldValue (string)
            ├── newValue (string)
            ├── changedBy (uid)
            └── timestamp (server timestamp)

📁 dropdowns/
├── event_types/
│   └── items/
│       └── {lowercase-event-type}/
│           └── value (string)
├── statuses/
│   └── items/
│       └── {lowercase-status}/
│           └── value (string)
└── payment_statuses/
    └── items/
        └── {lowercase-payment-status}/
            └── value (string)
```

## 🚀 Setup Instructions

### Option 1: Using the Setup Script (Recommended)

1. **Start Firebase Emulators** (for local development):
   ```bash
   firebase emulators:start
   ```

2. **Run the Database Setup Script**:
   ```bash
   dart run scripts/setup_database.dart
   ```

3. **For Production Database**:
   ```bash
   dart run scripts/setup_database.dart --dart-define=USE_FIRESTORE_EMULATOR=false
   ```

### Option 2: Manual Setup

1. **Create Collections**:
   - `users/` - for user data
   - `enquiries/` - for enquiry data
   - `dropdowns/` - for dropdown options

2. **Initialize Dropdowns**:
   - Event Types: Wedding, Birthday Party, Corporate Event, Anniversary, Graduation, Baby Shower, Engagement, Other
   - Statuses: Enquired, In Progress, Quote Sent, Confirmed, Completed, Cancelled
   - Payment Statuses: Pending, Partial, Paid, Overdue

3. **Deploy Security Rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Deploy Indexes**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

## 🔐 Security Rules

The database is protected by Firestore security rules that enforce:

- **Users**: Can read/write their own data, admins can read all
- **Enquiries**: Staff can read assigned enquiries, admins can read all
- **Financial Data**: Only admins and assigned staff can access
- **History**: Read-only for assigned staff and admins
- **Dropdowns**: Read-only for all users, write for admins

## 📊 Default Data

### Event Types
- Wedding
- Birthday Party
- Corporate Event
- Anniversary
- Graduation
- Baby Shower
- Engagement
- Other

### Enquiry Statuses
- Enquired (default)
- In Progress
- Quote Sent
- Confirmed
- Completed
- Cancelled

### Payment Statuses
- Pending
- Partial
- Paid
- Overdue

## 🔄 Reset Database

To completely reset the database:

```bash
# Delete all data (use with caution!)
firebase firestore:delete --all-collections

# Re-run setup
dart run scripts/setup_database.dart
```

## ✅ Verification

After setup, verify the database structure:

```bash
dart run scripts/setup_database.dart
```

The script will:
1. ✅ Check if collections exist
2. ✅ Verify dropdown data is populated
3. ✅ Create a sample enquiry for testing
4. ✅ Display verification results

## 🛠️ Troubleshooting

### Common Issues

1. **Permission Denied**:
   - Ensure you're authenticated with Firebase
   - Check if you have admin privileges

2. **Collection Not Found**:
   - Run the setup script again
   - Check Firebase console for collection creation

3. **Index Errors**:
   - Deploy indexes: `firebase deploy --only firestore:indexes`
   - Wait for index creation to complete

### Debug Mode

Enable debug logging:

```bash
dart run scripts/setup_database.dart --verbose
```

## 📝 Notes

- The `users/` collection is preserved during reset to maintain user accounts
- All dropdown values are enforced for uniqueness
- Subcollections (`financial/` and `history/`) are created automatically when needed
- Timestamps use server timestamps for consistency
- Document IDs for dropdowns use lowercase with underscores for consistency

## 🔗 Related Files

- `lib/core/constants/firestore_schema.dart` - Schema definitions
- `lib/core/services/database_setup_service.dart` - Setup service
- `scripts/setup_database.dart` - Setup script
- `firestore.rules` - Security rules
- `firestore.indexes.json` - Database indexes 