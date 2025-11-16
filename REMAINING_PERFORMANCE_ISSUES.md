# Remaining Performance Issues

## Summary
After implementing the high-priority improvements, there are a few remaining medium/low-priority performance issues that could be addressed.

---

## 🟡 Medium Priority - Still Pending

### 1. **Status Dropdown Widget** (`lib/shared/widgets/status_dropdown.dart`)
**Current Issue:**
- Line 281: Uses `ref.watch(currentUserIsAdminProvider)` 
- Admin-only "Add" button might have slight delays
- Used frequently in forms (enquiry form, enquiry details)

**Impact:** Medium - Used in multiple forms, could cause minor delays

**Fix:**
```dart
// Replace:
final isAdmin = ref.watch(currentUserIsAdminProvider);

// With:
final roleAsync = ref.watch(roleProvider);
final isAdmin = roleAsync.when(
  data: (role) => role == UserRole.admin,
  loading: () => false,
  error: (_, __) => false,
);
```

---

### 2. **Event Type Autocomplete** (`lib/shared/widgets/event_type_autocomplete.dart`)
**Current Issue:**
- Line 366: Uses `ref.watch(currentUserIsAdminProvider)`
- Admin-only "Add new event type" feature might have delays
- Used in enquiry form

**Impact:** Medium - Used in enquiry form, could cause minor delays

**Fix:**
```dart
// Replace:
final isAdmin = ref.watch(currentUserIsAdminProvider);

// With:
final roleAsync = ref.watch(roleProvider);
final isAdmin = roleAsync.when(
  data: (role) => role == UserRole.admin,
  loading: () => false,
  error: (_, __) => false,
);
```

---

## 🟢 Low Priority - Optional Improvements

### 3. **User Form Dialog** (`lib/features/admin/users/presentation/widgets/user_form_dialog.dart`)
**Current Issue:**
- Line 48: Uses `ref.watch(isAdminProvider)`
- Used in a dialog (less critical)
- Only shown when admin is already confirmed

**Impact:** Low - Dialog is only shown to admins, so delay is minimal

**Fix:** Same pattern as above

---

### 4. **Role Guards** (`lib/core/auth/role_guards.dart`)
**Current Issue:**
- Uses `ref.watch(isAdminProvider)` in utility functions
- Used for one-time checks (not in build methods)

**Impact:** Very Low - Utility functions, not in build methods, so no UI delays

**Note:** This is acceptable as-is since it's used in utility functions, not in build methods.

---

## 📊 Impact Assessment

### High Impact (Already Fixed ✅)
- Analytics Screen
- Dashboard Screen  
- Enquiry Details Screen
- User Management Screen
- Dropdown Management Screen
- Settings Screen
- Enquiry Form Screen (Assign To dropdown)

### Medium Impact (Remaining)
- Status Dropdown Widget - Used in forms, could cause minor delays
- Event Type Autocomplete - Used in forms, could cause minor delays

### Low Impact (Optional)
- User Form Dialog - Only shown to admins, minimal impact
- Role Guards - Utility functions, no UI impact

---

## 🎯 Recommendation

**Priority 1 (Recommended):**
- Fix Status Dropdown Widget
- Fix Event Type Autocomplete

**Priority 2 (Optional):**
- Fix User Form Dialog (if you want consistency)

**Priority 3 (Not Needed):**
- Role Guards are fine as-is (utility functions)

---

## ✅ Already Optimized

All major screens and critical user flows have been optimized:
- ✅ Analytics Screen
- ✅ Dashboard Screen
- ✅ Enquiry Details Screen
- ✅ Enquiry Form Screen (Assign To dropdown)
- ✅ User Management Screen
- ✅ Dropdown Management Screen
- ✅ Settings Screen

---

## 📝 Notes

The remaining issues are minor compared to what we've already fixed. The Status Dropdown and Event Type Autocomplete widgets are the only ones that could still cause noticeable delays, but they're less critical since:

1. They're used in forms (not main navigation)
2. The delay would be minimal (just the "Add" button appearing)
3. They don't block core functionality

However, fixing them would provide:
- Consistency across the codebase
- Slightly better UX
- Complete optimization coverage

