# Status Field Migration - Standardization to statusValue

## Overview
This migration standardizes all status-related fields to use **`statusValue`** as the single source of truth, eliminating confusion and potential bugs from maintaining multiple fields.

## Problem
Previously, the codebase maintained multiple status fields for backward compatibility:
- `statusValue` - intended standard field
- `eventStatus` - legacy field  
- `status` - another legacy field
- `status_slug` - older legacy field

This caused:
- Confusion about which field to use
- Potential bugs when queries checked only one field
- Maintenance overhead
- Risk of data inconsistency

## Solution
Standardized on **`statusValue`** as the single status field.

## Changes Made

### 1. Migration Script
Created `scripts/migrate_status_fields.dart` to:
- Find all enquiries with old status fields
- Copy values to `statusValue` if missing
- Remove old fields (`eventStatus`, `status`, `status_slug`)

**To run migration:**
```bash
dart scripts/migrate_status_fields.dart
```

### 2. Updated Write Operations
All status updates now only write to `statusValue`:
- `lib/features/enquiries/data/enquiry_repository.dart` - Repository updates
- `lib/features/enquiries/presentation/screens/enquiry_details_screen.dart` - Status dropdown updates
- `lib/features/enquiries/presentation/screens/enquiry_form_screen.dart` - Form updates

**Old code:**
```dart
'status': nextStatus,
'eventStatus': nextStatus,
'statusValue': nextStatus,
```

**New code:**
```dart
'statusValue': nextStatus, // Standardized field - only write to this
// Remove old fields
'eventStatus': FieldValue.delete(),
'status': FieldValue.delete(),
'status_slug': FieldValue.delete(),
```

### 3. Updated Queries
All Firestore queries now use `statusValue`:
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/enquiries/data/enquiry_repository.dart`
- `lib/core/services/firestore_service.dart`
- `lib/features/admin/analytics/data/analytics_repository.dart`

**Old code:**
```dart
query.where('eventStatus', isEqualTo: status)
```

**New code:**
```dart
query.where('statusValue', isEqualTo: status)
```

### 4. Updated Read Operations
Read operations prioritize `statusValue` but include fallbacks for migration period:
- `lib/features/enquiries/domain/enquiry.dart` - Domain model
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/core/services/past_enquiry_cleanup_service.dart`
- All other read operations

**Pattern used:**
```dart
(data['statusValue'] ?? data['eventStatus'] ?? data['status']) as String?
```

This ensures backward compatibility during migration period.

### 5. Updated Audit Trail
Audit trail now records changes to `statusValue` instead of `eventStatus`:
- `lib/features/enquiries/data/enquiry_repository.dart`
- `lib/features/enquiries/presentation/screens/enquiry_details_screen.dart`
- `lib/features/enquiries/presentation/screens/enquiry_form_screen.dart`

## Migration Steps

1. **Run the migration script** (one-time):
   ```bash
   dart scripts/migrate_status_fields.dart
   ```

2. **Verify migration**:
   - Check Firestore console to ensure all records have `statusValue`
   - Verify old fields are removed

3. **Deploy code changes**:
   - All code changes are already in place
   - Code will work with both old and new data during transition
   - After migration, old fields will be automatically removed on next update

## Firestore Indexes

No new indexes needed - we're using the same field name pattern, just standardizing to `statusValue`.

Existing indexes that use `eventStatus` should be updated to use `statusValue`:
- Check `firestore.indexes.json` for any `eventStatus` references
- Update composite indexes if needed

## Backward Compatibility

During the migration period, read operations include fallbacks:
```dart
(data['statusValue'] ?? data['eventStatus'] ?? data['status']) as String?
```

This ensures:
- Old records still work
- New records use `statusValue` only
- Gradual migration without breaking changes

## Benefits

✅ **Single source of truth** - Only `statusValue` field  
✅ **No confusion** - Clear which field to use  
✅ **Fewer bugs** - Queries won't miss records  
✅ **Easier maintenance** - One field to manage  
✅ **Data consistency** - No risk of fields getting out of sync  

## Testing Checklist

- [ ] Run migration script
- [ ] Verify all enquiries have `statusValue`
- [ ] Test status updates work correctly
- [ ] Test queries return correct results
- [ ] Test In Talks tab filtering
- [ ] Test Reminders tab filtering
- [ ] Test automatic cleanup service
- [ ] Verify old fields are removed on updates

## Rollback Plan

If issues occur:
1. Code still reads from old fields as fallback
2. Migration script can be reverted by restoring old fields
3. No data loss - values are preserved in `statusValue`

---

**Migration Date**: 2025-01-14  
**Status**: ✅ Code changes complete, ready for migration script execution
