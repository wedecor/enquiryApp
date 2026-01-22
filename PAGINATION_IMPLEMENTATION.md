# Cursor-Based Pagination Implementation

## Summary

Implemented cursor-based pagination for enquiries using Firestore `startAfterDocument`. Default page size: 20. Existing streams preserved for backward compatibility.

## Files Created

### 1. `lib/features/enquiries/data/pagination_state.dart`
**Purpose:** Freezed state model for pagination  
**Key Fields:**
- `documents`: List of current page documents
- `lastDocument`: Cursor for next page
- `hasMore`: Whether more pages exist
- `isLoading` / `isLoadingMore`: Loading states
- `error`: Error message if any

### 2. `lib/features/enquiries/data/enquiry_pagination_provider.dart`
**Purpose:** Riverpod provider for paginated enquiries state  
**Key Features:**
- `PaginatedEnquiriesNotifier`: StateNotifier managing pagination
- `loadFirstPage()`: Reset and load first page
- `loadNextPage()`: Load next page using cursor
- `refresh()`: Reload first page (pull-to-refresh)

## Files Modified

### 3. `lib/features/enquiries/data/enquiry_repository.dart`
**Changes:** Added `getPaginatedEnquiries()` method  
**Method Signature:**
```dart
Future<PaginationState> getPaginatedEnquiries({
  required bool isAdmin,
  String? assignedTo,
  String? status,
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
  int pageSize = 20,
})
```

**Implementation:**
- Builds query with filters (admin/staff, status)
- Applies `startAfterDocument` cursor if provided
- Fetches `pageSize + 1` documents to detect `hasMore`
- Returns `PaginationState` with documents and cursor

### 4. `lib/features/enquiries/presentation/screens/enquiries_list_screen.dart`
**Changes:** Added import for pagination provider (ready for future use)  
**Note:** Existing stream-based implementation preserved. Pagination can be integrated later.

## Usage Example

```dart
// Get pagination provider
final paginationState = ref.watch(
  paginatedEnquiriesProvider(PaginationParams(status: null)),
);
final notifier = ref.read(
  paginatedEnquiriesProvider(PaginationParams(status: null)).notifier,
);

// Load first page
await notifier.loadFirstPage();

// Load next page
await notifier.loadNextPage();

// Refresh (pull-to-refresh)
await notifier.refresh();
```

## Integration Points

### Current State
- ✅ Repository layer: Pagination methods ready
- ✅ Provider layer: StateNotifier ready
- ⏳ UI layer: Streams still used (backward compatible)

### Future Integration
To switch UI to pagination:

1. Replace `StreamBuilder` with `ConsumerWidget` watching `paginatedEnquiriesProvider`
2. Call `loadFirstPage()` on mount
3. Add `RefreshIndicator` calling `refresh()`
4. Add "Load More" button or infinite scroll calling `loadNextPage()`
5. Display `paginationState.documents` instead of stream docs

## Key Features

### ✅ Cursor-Based Pagination
- Uses `startAfterDocument` for efficient pagination
- No offset-based pagination (better performance)

### ✅ Default Page Size: 20
- Configurable via `pageSize` parameter
- Fetches `pageSize + 1` to detect `hasMore`

### ✅ Pull-to-Refresh Support
- `refresh()` method resets pagination
- Reloads first page

### ✅ Backward Compatible
- Existing streams (`getEnquiries()`) still work
- No breaking changes to current UI

### ✅ Prepared for Infinite Scrolling
- `hasMore` flag indicates more pages
- `loadNextPage()` appends to existing documents
- Ready for ListView infinite scroll integration

## Query Structure

All pagination queries use:
- `orderBy('createdAt', descending: true)` - Consistent ordering
- `limit(pageSize + 1)` - Fetch extra to detect `hasMore`
- `startAfterDocument(cursor)` - Cursor-based pagination

## Next Steps

1. **Generate Freezed Files:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Test Pagination:**
   - Verify `loadFirstPage()` loads 20 documents
   - Verify `loadNextPage()` loads next 20
   - Verify `hasMore` is correct
   - Verify `refresh()` resets pagination

3. **Integrate UI (Optional):**
   - Replace streams with pagination provider
   - Add pull-to-refresh
   - Add infinite scroll or "Load More" button

## Notes

- Existing stream queries still use `.limit(50)` - safe for current usage
- Pagination uses `.limit(20)` - better for performance
- Both approaches can coexist until full migration
- No Firestore index changes required (uses existing `createdAt` index)

