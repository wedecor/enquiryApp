# Firestore Status Seeding

This document describes how to safely populate the production Firestore database with the exact set of status documents required by the WeDecor Enquiries application.

## Overview

The seeding script ensures that exactly 7 status documents exist in the `dropdowns/statuses/items` collection, removing any unwanted statuses (like "approved") and creating/updating the required ones.

### Target Statuses

The script will ensure these exact 7 statuses exist:

| ID | Label | Order |
|----|-------|-------|
| `new` | New | 1 |
| `in_talks` | In Talks | 2 |
| `confirmed` | Confirmed | 3 |
| `completed` | Completed | 4 |
| `cancelled` | Cancelled | 5 |
| `not_interested` | Not Interested | 6 |
| `quotation_sent` | Quotation Sent | 7 |

## Prerequisites

### 1. Service Account Credentials

You need a Firebase Service Account JSON file with admin privileges for the `wedecorenquries` project.

**Option A: Create via Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/project/wedecorenquries/settings/serviceaccounts/adminsdk)
2. Click "Generate new private key"
3. Save the JSON file as `serviceAccountKey.json` in your project root

**Option B: Use existing credentials**
If you already have a service account JSON file, place it in your project root.

### 2. Environment Setup

Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
```

## Safety Features

The script includes multiple safety mechanisms:

- **🔒 Production Confirmation**: Requires `CONFIRM_PROD=YES` for production runs
- **📦 Automatic Backup**: Creates timestamped backup before any changes
- **🔍 Dry Run Mode**: Preview changes without making them
- **📊 Verification**: Confirms final state matches expectations
- **🔄 Idempotent**: Safe to run multiple times
- **📦 Batched Operations**: Uses Firestore batch writes for efficiency

## Usage

### 1. Preview Changes (Dry Run)

See what the script would do without making any changes:

```bash
npm run seed:statuses:dry
```

This will:
- ✅ Show environment check results
- ✅ Create a backup of existing data
- ✅ Display the operations that would be performed
- ❌ Make no actual changes to the database

### 2. Apply Changes to Production

**⚠️ WARNING: This modifies the production Firestore database**

```bash
CONFIRM_PROD=YES npm run seed:statuses
```

This will:
- ✅ Verify all safety checks pass
- ✅ Create a backup of existing data
- ✅ Upsert all 7 required status documents
- ✅ Delete any unwanted status documents
- ✅ Verify the final state is correct

## Example Output

### Dry Run Example
```
🚀 WeDecor Enquiries - Status Population Script
==================================================
🔍 Environment Check:
  DRY_RUN: ✅ YES
  CONFIRM_PROD: ❌ NO
  GOOGLE_APPLICATION_CREDENTIALS: ✅ Set

✅ Firebase Admin initialized for project: wedecorenquries
📦 Creating backup of existing data...
✅ Backup created: backups/statuses-2025-09-23T02-45-30.json
   Documents backed up: 8

📖 Reading existing status documents...
📊 Found 8 existing documents

📋 Operation Summary:
  📝 Upserts: 7
  🗑️  Deletions: 1
  📦 Total operations: 8

🗑️  Documents to be deleted:
    - approved

🔍 DRY RUN - Operations that would be executed:
  📝 UPSERT: new -> {
    "id": "new",
    "label": "New",
    "order": 1,
    "active": true,
    "updatedAt": "serverTimestamp",
    "createdAt": "serverTimestamp"
  }
  ...

==================================================
📊 FINAL SUMMARY:
  📦 Backup file: backups/statuses-2025-09-23T02-45-30.json
  📝 Upserts: 0
  🗑️  Deletions: 0
  ❌ Errors: 0
  🎯 Target documents: 7

🔍 This was a DRY RUN - no changes were made
   To apply changes, run: CONFIRM_PROD=YES npm run seed:statuses

🎉 Script completed successfully!
```

### Production Run Example
```
🚀 WeDecor Enquiries - Status Population Script
==================================================
🔍 Environment Check:
  DRY_RUN: ❌ NO
  CONFIRM_PROD: ✅ YES
  GOOGLE_APPLICATION_CREDENTIALS: ✅ Set

✅ Firebase Admin initialized for project: wedecorenquries
📦 Creating backup of existing data...
✅ Backup created: backups/statuses-2025-09-23T02-47-15.json
   Documents backed up: 8

📖 Reading existing status documents...
📊 Found 8 existing documents

📋 Operation Summary:
  📝 Upserts: 7
  🗑️  Deletions: 1
  📦 Total operations: 8

🗑️  Documents to be deleted:
    - approved

📦 Executing batch 1/1 (8 operations)
✅ Batch committed successfully

==================================================
📊 FINAL SUMMARY:
  📦 Backup file: backups/statuses-2025-09-23T02-47-15.json
  📝 Upserts: 7
  🗑️  Deletions: 1
  ❌ Errors: 0
  🎯 Target documents: 7

✅ Production changes completed successfully!

🔍 Verifying final state...
✅ VERIFICATION PASSED: Database contains exactly the expected statuses
   Statuses: cancelled, completed, confirmed, in_talks, new, not_interested, quotation_sent

🎉 Script completed successfully!
```

## Recovery

If something goes wrong, you can restore from the backup:

### Manual Recovery via Firebase Console
1. Go to [Firestore Console](https://console.firebase.google.com/project/wedecorenquries/firestore/data)
2. Navigate to `dropdowns/statuses/items`
3. Delete all existing documents
4. Create new documents using the data from your backup JSON file

### Programmatic Recovery
You can create a recovery script using the backup JSON file to restore the previous state.

## Troubleshooting

### Common Issues

**❌ "GOOGLE_APPLICATION_CREDENTIALS environment variable is required"**
```bash
# Solution: Set the environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
```

**❌ "Production run requires CONFIRM_PROD=YES"**
```bash
# Solution: Add the confirmation flag
CONFIRM_PROD=YES npm run seed:statuses
```

**❌ "Credentials file not found"**
```bash
# Solution: Ensure the JSON file exists and path is correct
ls -la serviceAccountKey.json
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
```

**❌ "Failed to initialize Firebase Admin"**
- Check that your service account has the necessary permissions
- Verify the project ID is correct (`wedecorenquries`)
- Ensure the JSON file is valid

### Verification

After running the script, verify the results:

1. **Firebase Console**: Check that exactly 7 documents exist in `dropdowns/statuses/items`
2. **Application**: Test that the status dropdown shows the correct options
3. **Backup**: Confirm the backup file was created successfully

## Security Notes

- 🔒 Never commit the service account JSON file to version control
- 🔒 The backup files contain sensitive data - store them securely
- 🔒 Use the dry-run mode first to verify the changes
- 🔒 The script requires explicit confirmation for production runs

## File Structure

After running the script, you'll have:

```
project-root/
├── backups/
│   └── statuses-2025-09-23T02-47-15.json  # Automatic backup
├── scripts/
│   └── populate_statuses.ts               # The seeding script
├── serviceAccountKey.json                 # Your credentials (DO NOT COMMIT)
└── docs/
    └── SEEDING.md                         # This documentation
```
