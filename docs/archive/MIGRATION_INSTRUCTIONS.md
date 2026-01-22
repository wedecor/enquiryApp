# Status Field Migration - Ready to Run ✅

## What Was Done

1. ✅ **Code Standardization Complete**
   - All code now uses only `statusValue` field
   - All old fields (`eventStatus`, `status`, `status_slug`) are removed on write
   - All queries updated to use `statusValue`
   - All read operations use `statusValue` only (no fallbacks)

2. ✅ **Cloud Function Deployed**
   - Function name: `migrateStatusFields`
   - Region: `asia-south1`
   - Status: ✅ Deployed and ready

3. ✅ **Migration Button Added**
   - Location: Admin → User Management screen
   - Button: "Migrate Status" (orange button in top right)
   - Only visible to admins

## How to Run the Migration

### Option 1: Via Admin UI (Recommended)
1. Open the app
2. Go to **Admin → User Management**
3. Click the **"Migrate Status"** button (orange button with sync icon)
4. Confirm the migration
5. Wait for completion (may take a few minutes)
6. Review the results

### Option 2: Via Firebase Console
1. Go to Firebase Console → Functions
2. Find `migrateStatusFields`
3. Click "Test" and run it

### Option 3: Via Flutter Code
Call this from anywhere in your admin code:
```dart
final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
final callable = functions.httpsCallable('migrateStatusFields');
final result = await callable.call();
```

## What the Migration Does

1. **Fetches all enquiries** from Firestore
2. **For each enquiry:**
   - Checks if `statusValue` exists
   - If missing, copies value from old fields (`eventStatus` → `status` → `status_slug`)
   - Sets `statusValue` to the determined value
   - Removes all old fields (`eventStatus`, `status`, `status_slug`)
3. **Processes in batches** of 500 records (Firestore limit)
4. **Returns summary** with counts of migrated/errors

## Expected Results

After migration, you'll see:
- ✅ **Migrated**: Number of records that were updated
- ✓ **Already migrated**: Records that already had `statusValue`
- ❌ **Errors**: Any records that failed (should be 0)
- **Total**: Total records processed

## After Migration

Once migration completes:
1. ✅ All old records will have `statusValue` set
2. ✅ All old fields will be removed
3. ✅ Your app code is already using `statusValue` only
4. ✅ Everything will be consistent!

## Next Steps

1. **Run the migration** using one of the options above
2. **Verify results** - check a few records in Firestore Console
3. **Deploy Firestore indexes** (if needed):
   ```bash
   firebase deploy --only firestore:indexes
   ```

## Notes

- Migration is **safe** - it only reads and updates, never deletes records
- Migration is **idempotent** - safe to run multiple times
- Migration processes **all records** - no limits
- Old fields are **removed** - not just set to null

---

**Status**: ✅ Ready to run  
**Date**: 2025-01-14
