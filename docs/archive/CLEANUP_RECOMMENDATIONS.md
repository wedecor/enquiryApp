# Script Cleanup Recommendations

## Files That Can Be Safely Removed

### 1. **Obsolete Cloud Functions** ❌
- `functions/src/notifyOverdueInTalks.ts`
  - **Reason**: Not exported in `index.ts`, commented as "removed - 4-hour scheduled reminders disabled"
  - **Status**: Safe to delete - functionality was intentionally removed

- `functions/src/dailyDigest.ts`
  - **Reason**: Not exported in `index.ts`, uses old `status` field instead of `statusValue`
  - **Status**: Safe to delete - not deployed and uses outdated schema

### 2. **Redundant Migration Scripts** ✅ (Already Archived)
- `scripts/migrate_status_fields.dart` - ✅ Already archived
  - **Reason**: Migration complete, functionality removed

### 3. **One-Time Migration Scripts** (Review if migrations are complete)
- `scripts/migrate-active-to-isactive.ts`
- `scripts/rollback-isactive-to-active.ts`
  - **Status**: Review if these migrations are complete. If yes, can be archived/deleted

### 4. **Documentation Files** (Can be consolidated)
- `STATUS_FIELD_MIGRATION.md` - Migration is complete, can archive
- `STATUS_FIELD_STANDARDIZATION_COMPLETE.md` - Can archive after review
- `MIGRATION_INSTRUCTIONS.md` - Can archive after migration is complete
- `MIGRATION_SUMMARY.md` - Can archive

## Files to Keep ✅

### Active Cloud Functions
- `functions/src/autoExpireEnquiries.ts` - ✅ Active (runs every 4 hours)
- `functions/src/index.ts` - ✅ Main exports file

### Utility Scripts (Keep for maintenance)
- `scripts/verify_schema.dart` - Useful for schema validation
- `scripts/setup_database.dart` - Useful for database setup
- `scripts/manage_indexes.dart` - Useful for index management
- `scripts/firebase_data_manager.dart` - Useful for data export/import

## Recommended Cleanup Steps

1. **Delete obsolete Cloud Functions:**
   ```bash
   rm functions/src/notifyOverdueInTalks.ts
   rm functions/src/dailyDigest.ts
   ```

2. **Archive migration scripts** (move to `scripts/archive/`):
   ```bash
   mkdir -p scripts/archive
   mv scripts/migrate_status_fields.dart scripts/archive/
   mv scripts/migrate-active-to-isactive.ts scripts/archive/
   mv scripts/rollback-isactive-to-active.ts scripts/archive/
   ```

3. **Archive documentation** (move to `docs/archive/`):
   ```bash
   mkdir -p docs/archive
   mv STATUS_FIELD_MIGRATION.md docs/archive/
   mv STATUS_FIELD_STANDARDIZATION_COMPLETE.md docs/archive/
   mv MIGRATION_INSTRUCTIONS.md docs/archive/
   mv MIGRATION_SUMMARY.md docs/archive/
   ```

4. **Update package.json deploy script** (already correct):
   - Current: `functions:inviteUser,functions:notifyOnEnquiryChange,functions:autoExpireEnquiries`
   - ✅ Correct - migration function removed

## Summary

**Safe to Delete:**
- 2 Cloud Function files (`notifyOverdueInTalks.ts`, `dailyDigest.ts`)
- 1 Dart migration script (`migrate_status_fields.dart`) - after migration confirmed

**Safe to Archive:**
- 2 TypeScript migration scripts
- 4 documentation files

**Total Cleanup:**
- ~8 files can be removed/archived
- Reduces codebase clutter
- Makes it clearer what's actively used
