# Firestore Status Seeder

This document describes how to safely populate the Firestore database with the required status values for the WeDecor Enquiries app.

## Overview

The seeder ensures exactly 7 status values are present in the `dropdowns/statuses/items` collection:
- `new` → "New"
- `in_talks` → "In Talks" 
- `confirmed` → "Confirmed"
- `completed` → "Completed"
- `cancelled` → "Cancelled"
- `not_interested` → "Not Interested"
- `quotation_sent` → "Quotation Sent"

## Prerequisites

1. **Service Account Key**: Download from [Firebase Console](https://console.firebase.google.com/project/wedecorenquries/settings/serviceaccounts/adminsdk)
2. **Save as**: `serviceAccountKey.json` in project root
3. **Set Environment**: `export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"`

## Safety Features

- ✅ **Dry-run mode**: Preview changes without writing
- ✅ **Production guard**: Requires `CONFIRM_PROD=YES` for production writes
- ✅ **Automatic backup**: Creates timestamped backup before any changes
- ✅ **Batch operations**: Handles large datasets efficiently
- ✅ **Verification**: Confirms final state matches expectations
- ✅ **Probe tool**: Tests credentials and permissions

## Commands

### 1. Test Connection (Probe)
```bash
npm run seed:probe
```
Expected output:
```
[Probe] projectId: wedecorenquries
[Probe] path: dropdowns/statuses/items
[Probe] creds: /path/to/serviceAccountKey.json
WRITE_OK
DELETE_OK
```

### 2. Preview Changes (Dry Run)
```bash
npm run seed:statuses:dry
```
Expected output:
```
[Seeder] projectId: wedecorenquries
[Seeder] path: dropdowns/statuses/items
[Seeder] creds: /path/to/serviceAccountKey.json
[Seeder] DRY_RUN: true CONFIRM_PROD: false
[Seeder] Existing count: 8 IDs: ['new', 'approved', 'cancelled', ...]
[Seeder] Backup saved: backups/statuses-20241201T120000.json
[Seeder] To upsert: ['new', 'in_talks', 'confirmed', 'completed', 'cancelled', 'not_interested', 'quotation_sent']
[Seeder] To delete: ['approved']
[Seeder] DRY RUN complete. No writes performed.
```

### 3. Apply Changes (Production)
```bash
CONFIRM_PROD=YES npm run seed:statuses
```
Expected output:
```
[Seeder] projectId: wedecorenquries
[Seeder] path: dropdowns/statuses/items
[Seeder] creds: /path/to/serviceAccountKey.json
[Seeder] DRY_RUN: false CONFIRM_PROD: true
[Seeder] Existing count: 8 IDs: ['new', 'approved', 'cancelled', ...]
[Seeder] Backup saved: backups/statuses-20241201T120000.json
[Seeder] To upsert: ['new', 'in_talks', 'confirmed', 'completed', 'cancelled', 'not_interested', 'quotation_sent']
[Seeder] To delete: ['approved']
[Seeder] Batch 1/1 committed
[Seeder] DONE. Upserts: 7 Deletions: 1 Backup: backups/statuses-20241201T120000.json
[Seeder] Final IDs: ['cancelled', 'completed', 'confirmed', 'in_talks', 'new', 'not_interested', 'quotation_sent']
[Seeder] SUCCESS: All statuses match expected state
```

## Customization

### Override Project ID
```bash
npm run seed:statuses:dry -- --project=my-project-id
```

### Override Collection Path
```bash
npm run seed:statuses:dry -- --path=my/statuses/path
```

### Combined Overrides
```bash
npm run seed:statuses:dry -- --project=my-project --path=my/statuses
```

## Troubleshooting

### Error: "GOOGLE_APPLICATION_CREDENTIALS not set"
- Ensure you've downloaded the service account key
- Verify the environment variable is set correctly
- Check the file path is absolute or relative to current directory

### Error: "Refusing to modify production without CONFIRM_PROD=YES"
- This is a safety feature preventing accidental production writes
- Add `CONFIRM_PROD=YES` to your command for production runs
- Always run dry-run first to preview changes

### Error: "Permission denied"
- Verify the service account has Firestore Admin permissions
- Check the service account key is valid and not expired
- Ensure the Firebase project ID is correct

### Unexpected Results
- Check the backup file in `backups/` directory
- Verify the collection path is correct
- Run the probe command to test basic connectivity

## File Locations

- **Scripts**: `scripts/populate_statuses.ts`, `scripts/probe_firestore.ts`
- **Backups**: `backups/statuses-{timestamp}.json`
- **Service Account**: `serviceAccountKey.json` (not committed to git)

## Security Notes

- Service account keys are sensitive - never commit to version control
- Backups contain production data - store securely
- Use dry-run mode extensively before production changes
- Verify results after each run