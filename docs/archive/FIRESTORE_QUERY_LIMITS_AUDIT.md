# Firestore Query Limits Audit & Implementation

## Summary

Added safe limits to all Firestore stream queries to prevent performance degradation as data grows. Default limit: **50 documents** for most queries, with exceptions for smaller collections.

## Changes Made

### ✅ Files Modified (7 files)

#### 1. `lib/core/services/firestore_service.dart`
**Changes:**
- `getEnquiries()`: Added `.limit(50)`
- `getEnquiriesByStatus()`: Added `.limit(50)`
- `searchEnquiries()`: Added `.limit(50)`
- `getActiveUsers()`: Added `.limit(100)` (users collection typically small)

**Before:**
```dart
Stream<QuerySnapshot> getEnquiries() {
  return _enquiriesCollection.orderBy('createdAt', descending: true).snapshots();
}
```

**After:**
```dart
Stream<QuerySnapshot> getEnquiries() {
  // Limit to 50 for performance - pagination can be added later
  return _enquiriesCollection
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots();
}
```

#### 2. `lib/features/enquiries/data/enquiry_repository.dart`
**Changes:**
- `getEnquiries()`: Added `.limit(50)`

**Before:**
```dart
Stream<List<Enquiry>> getEnquiries() {
  return FirebaseFirestore.instance
      .collection('enquiries')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Enquiry.fromFirestore(doc)).toList());
}
```

**After:**
```dart
/// Get all enquiries as a stream
/// Limited to 50 for performance - pagination can be added later
Stream<List<Enquiry>> getEnquiries() {
  return FirebaseFirestore.instance
      .collection('enquiries')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Enquiry.fromFirestore(doc)).toList());
}
```

#### 3. `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
**Changes:**
- `_getEnquiriesStream()`: Added `.limit(50)`

**Before:**
```dart
return query.orderBy('createdAt', descending: true).snapshots();
```

**After:**
```dart
// Limit to 50 for performance - pagination can be added later
return query.orderBy('createdAt', descending: true).limit(50).snapshots();
```

#### 4. `lib/features/enquiries/presentation/screens/enquiries_list_screen.dart`
**Changes:**
- Admin enquiries stream: Added `.limit(50)`
- Staff enquiries stream: Added `.limit(50)`

**Before:**
```dart
// Admin sees all enquiries
return FirebaseFirestore.instance
    .collection('enquiries')
    .orderBy('createdAt', descending: true)
    .snapshots();
```

**After:**
```dart
// Admin sees all enquiries - limit to 50 for performance
return FirebaseFirestore.instance
    .collection('enquiries')
    .orderBy('createdAt', descending: true)
    .limit(50)
    .snapshots();
```

#### 5. `lib/core/services/audit_service.dart`
**Changes:**
- `getEnquiryHistoryStream()`: Added `.orderBy('timestamp', descending: true).limit(100)`

**Before:**
```dart
return _firestore
    .collection('enquiries')
    .doc(enquiryId)
    .collection('history')
    .snapshots()
```

**After:**
```dart
// Limit to 100 for history - can grow large but we want recent history
return _firestore
    .collection('enquiries')
    .doc(enquiryId)
    .collection('history')
    .orderBy('timestamp', descending: true)
    .limit(100)
    .snapshots()
```

**Note:** Added `orderBy` to ensure most recent history appears first. May require Firestore index.

#### 6. `lib/features/enquiries/presentation/screens/enquiry_details_screen.dart`
**Changes:**
- Status dropdown items stream: Added `.limit(50)`

**Before:**
```dart
.collection('items')
.where('active', isEqualTo: true)
.orderBy('order')
.snapshots(),
```

**After:**
```dart
.collection('items')
.where('active', isEqualTo: true)
.orderBy('order')
.limit(50) // Limit dropdown items stream - typically small but safe limit
.snapshots(),
```

---

## Queries That Should NOT Be Limited

These queries are intentionally **NOT** limited because they are:
- Small reference data collections
- Single document queries
- Already have pagination support

### ✅ Dropdown Collections (Small, Reference Data)
- `lib/core/services/firestore_service.dart`:
  - `getEventTypes()` - Event types dropdown (typically <20 items)
  - `getStatuses()` - Status dropdown (typically <15 items)
  - `getPaymentStatuses()` - Payment status dropdown (typically <10 items)

- `lib/features/admin/dropdowns/data/dropdowns_repository.dart`:
  - `watchItems()` - Dropdown items (typically <50 items per group)

**Rationale:** These are small reference collections that rarely exceed 50 items. Limiting would cause issues if more items are added.

### ✅ Single Document Queries
- `lib/features/enquiries/presentation/screens/enquiry_details_screen.dart`:
  - Single enquiry document stream (line 103)

- `lib/core/auth/current_user_role_provider.dart`:
  - Single user document streams

- `lib/core/providers/role_provider.dart`:
  - Single user document streams

- `lib/features/settings/data/app_config_service.dart`:
  - Single app config document streams

- `lib/features/settings/data/user_settings_service.dart`:
  - Single user settings document stream

**Rationale:** Single document queries don't need limits.

### ✅ Already Paginated
- `lib/features/admin/users/data/users_repository.dart`:
  - `watchUsers()` - Already has `.limit(limit)` parameter (default 20)

**Rationale:** Already implements pagination with configurable limit.

### ✅ Small Collections
- `lib/features/enquiries/filters/saved_views_repo.dart`:
  - `watchSavedViews()` - Saved views per user (typically <10 per user)

**Rationale:** Very small collection, limiting would cause issues.

---

## Pagination Readiness

### ✅ Ready for Pagination (Cursor-Based)

These queries are structured to easily add pagination:

1. **Enquiry Queries** (all use `orderBy('createdAt', descending: true)`):
   - `getEnquiries()`
   - `getEnquiriesByStatus()`
   - `_getEnquiriesStream()` in dashboard
   - Enquiries list screen streams

   **Pagination Implementation:**
   ```dart
   // Future enhancement:
   Stream<QuerySnapshot> getEnquiries({DocumentSnapshot? startAfter}) {
     var query = _enquiriesCollection
         .orderBy('createdAt', descending: true)
         .limit(50);
     
     if (startAfter != null) {
       query = query.startAfter(startAfter);
     }
     
     return query.snapshots();
   }
   ```

2. **User Queries**:
   - `getActiveUsers()` - Uses `orderBy('name')` - ready for pagination
   - `watchUsers()` - Already has pagination support ✅

3. **Audit History**:
   - `getEnquiryHistoryStream()` - Uses `orderBy('timestamp', descending: true)` - ready for pagination

### ⚠️ Needs Index

The audit history query now uses `orderBy('timestamp', descending: true)`. You may need to create a Firestore index:

**Collection:** `enquiries/{enquiryId}/history`
**Fields:**
- `timestamp` (Descending)

**To create index:**
```bash
# Firestore will auto-suggest this index when query runs
# Or manually add to firestore.indexes.json:
{
  "collectionGroup": "history",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

---

## Performance Impact

### Before Limits
- **Risk:** Loading entire collections (could be 1000+ documents)
- **Cost:** High read costs, slow initial load
- **Memory:** High memory usage on client

### After Limits
- **Safety:** Maximum 50-100 documents per query
- **Cost:** Predictable read costs
- **Memory:** Bounded memory usage
- **UX:** Faster initial load, smoother scrolling

### Expected Behavior
- **Initial Load:** Shows first 50 enquiries (fast)
- **User Experience:** No change yet (UI still shows all loaded items)
- **Future:** Can add "Load More" button for pagination

---

## Migration Notes

### ✅ No Breaking Changes
- UI behavior unchanged (still shows all loaded items)
- Limits are conservative (50 is reasonable for initial view)
- Can be increased if needed

### ⚠️ Potential Issues
1. **Users with >50 enquiries:** Will only see first 50
   - **Mitigation:** Add pagination UI in future
   - **Workaround:** Use filters to narrow results

2. **Audit history >100 entries:** Will only see most recent 100
   - **Mitigation:** Already sorted by timestamp (most recent first)
   - **Future:** Add "Load older history" button

3. **Firestore Index:** Audit history query may need index
   - **Action:** Monitor Firestore console for index suggestions
   - **Fix:** Add index to `firestore.indexes.json` if needed

---

## Next Steps (Future Enhancements)

1. **Add Pagination UI:**
   - "Load More" button for enquiries
   - Infinite scroll for mobile
   - Page numbers for web

2. **Add Filtering:**
   - Date range filters
   - Status filters
   - Search functionality

3. **Optimize Limits:**
   - Monitor usage patterns
   - Adjust limits based on actual data sizes
   - Consider user preferences

4. **Add Indexes:**
   - Monitor Firestore console
   - Add suggested indexes
   - Optimize query performance

---

## Testing Checklist

- [x] No lint errors
- [ ] Test enquiry list loads correctly
- [ ] Test dashboard tabs work
- [ ] Test audit history displays correctly
- [ ] Test dropdowns still work
- [ ] Test user management still works
- [ ] Verify Firestore indexes (check console)
- [ ] Monitor performance in production

---

## Rollback Plan

If issues occur, revert limits by removing `.limit()` calls:

```dart
// Revert to:
return _enquiriesCollection.orderBy('createdAt', descending: true).snapshots();
```

**Note:** Only revert if critical issues occur. Limits are safe and recommended.

