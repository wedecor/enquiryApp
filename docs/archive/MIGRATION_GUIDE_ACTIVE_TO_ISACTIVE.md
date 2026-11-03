# Migration Guide: Standardize `active` → `isActive`

## Overview

This migration standardizes the user document field naming from `active` to `isActive` across the entire codebase and Firestore database.

## Why This Migration?

- **Consistency**: Some code used `active`, some used `isActive`
- **Bug Prevention**: Inconsistent field names caused notification bugs
- **Maintainability**: Single source of truth for field naming

## Files Changed

### Flutter Code (Dart)

1. **`lib/features/admin/users/domain/user_model.dart`**
   - Changed field from `active` to `isActive`
   - Updated `fromFirestore()` to read both fields (backward compatible)
   - Updated `toFirestore()` to write only `isActive`

2. **`lib/features/admin/users/data/users_repository.dart`**
   - Updated queries to use `isActive`
   - Updated `toggleActive()` to write `isActive`

3. **`lib/core/services/notification_service.dart`**
   - Updated to read both fields (backward compatible)
   - Updated debug logging

4. **`lib/core/services/firestore_service.dart`**
   - Updated `createUser()` to write `isActive`

5. **`lib/features/admin/users/presentation/user_management_screen.dart`**
   - Updated all `user.active` references to `user.isActive`

6. **`lib/features/admin/users/presentation/widgets/user_form_dialog.dart`**
   - Updated to use `user.isActive`

### Cloud Functions (TypeScript)

1. **`functions/src/index.ts`**
   - Updated `isAdmin()` to check both fields (backward compatible)
   - Updated `inviteUser()` to set `isActive`

2. **`functions/src/notifyOverdueInTalks.ts`**
   - Updated `fetchAdminProfiles()` to filter by both fields (backward compatible)

## Migration Steps

### Step 1: Regenerate Code (Required)

After code changes, regenerate Freezed/JSON serializable files:

```bash
cd /Users/mohammedilyas/Desktop/AppDevelopment/wedecorEnquries
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 2: Test Locally

1. Run the app locally
2. Verify user management screen works
3. Test creating/editing users
4. Test notifications still work

### Step 3: Deploy Code Changes

```bash
# Deploy Flutter app (if needed)
flutter build apk --release

# Deploy Cloud Functions
cd functions
npm run build
firebase deploy --only functions
```

### Step 4: Run Migration Script (Dry Run First)

```bash
# Dry run to preview changes
cd /Users/mohammedilyas/Desktop/AppDevelopment/wedecorEnquries
npx ts-node scripts/migrate-active-to-isactive.ts --dry-run

# Review the output, then run for real
npx ts-node scripts/migrate-active-to-isactive.ts
```

### Step 5: Verify Migration

1. Check Firestore console - all user documents should have `isActive` field
2. Test notifications - admins should still receive notifications
3. Test user management - activate/deactivate should work
4. Monitor Cloud Functions logs for 24-48 hours

### Step 6: Optional Cleanup (After Verification)

After confirming everything works, you can optionally remove the `active` field:

```bash
# This script would remove 'active' field (not provided, create if needed)
# Only do this after 1-2 weeks of stable operation
```

## Rollback Strategy

If migration causes issues:

### Step 1: Run Rollback Script

```bash
# Dry run first
npx ts-node scripts/rollback-isactive-to-active.ts --dry-run

# Then rollback
npx ts-node scripts/rollback-isactive-to-active.ts
```

### Step 2: Revert Code Changes

```bash
git revert <commit-hash>
# Or manually revert the files listed above
```

### Step 3: Redeploy

```bash
flutter pub run build_runner build --delete-conflicting-outputs
cd functions && npm run build && firebase deploy --only functions
```

## Backward Compatibility

The code is designed to work during migration:

- **Reading**: Code checks both `isActive` and `active` fields, preferring `isActive`
- **Writing**: Code writes only `isActive` field
- **Queries**: During migration, queries use `isActive` but filter in memory for backward compatibility

This means:
- ✅ Old documents with `active` still work
- ✅ New documents use `isActive`
- ✅ Migration can be done gradually
- ✅ No downtime required

## Safety Features

1. **Dry Run Mode**: Test migration without making changes
2. **Batch Processing**: Processes documents in batches to avoid timeouts
3. **Error Handling**: Continues on errors, logs them for review
4. **Rollback Script**: Easy rollback if issues occur
5. **Backward Compatible Code**: Works with both field names during migration

## Monitoring

After migration, monitor:

1. **Cloud Functions Logs**: Check for errors in `notifyOverdueInTalks` and `inviteUser`
2. **Notification Delivery**: Verify admins still receive notifications
3. **User Management**: Test activate/deactivate functionality
4. **Firestore Reads**: Monitor for increased read costs (temporary during migration)

## Timeline

- **Day 1**: Deploy code changes, run migration script
- **Day 2-3**: Monitor and verify everything works
- **Week 2**: Optional cleanup of `active` field (if desired)

## Support

If you encounter issues:

1. Check Cloud Functions logs: `firebase functions:log`
2. Check Firestore console for document structure
3. Run rollback script if critical issues occur
4. Review migration script output for errors

