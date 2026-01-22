# Firestore Security Rules Hardening

## Overview

Hardened Firestore security rules to prevent staff from modifying financial fields and deleting enquiries, while preserving all existing functionality for admins.

## Changes Made

### ✅ Updated `firestore.rules`

#### New Helper Functions

1. **`isStaff()`**
   - Checks if authenticated user has role "staff"
   - Used to identify staff members (non-admins)

2. **`isModifyingFinancialFields()`**
   - Checks if the update request modifies any financial fields
   - Financial fields: `totalCost`, `advancePaid`, `paymentStatus`, `paymentStatusValue`, `paymentStatusLabel`
   - Returns `true` if any financial field is being modified

3. **`isModifyingOnlyNonFinancialFields()`**
   - Checks if update modifies ONLY non-financial fields
   - Returns `true` if no financial fields are being modified
   - Used to allow staff updates to non-financial fields

#### Updated Enquiry Rules

**Before:**
```javascript
match /enquiries/{id} {
  allow read: if isAdmin()
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
  allow create, delete: if isAdmin();
  allow update: if isAdmin()
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
}
```

**After:**
```javascript
match /enquiries/{id} {
  // Read: Admins see all, Staff see only assigned enquiries
  allow read: if isAdmin()
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
  
  // Create: Admin only
  allow create: if isAdmin();
  
  // Delete: Admin only (staff cannot delete enquiries)
  allow delete: if isAdmin();
  
  // Update: Admin can update anything, Staff can only update non-financial fields
  allow update: if isAdmin()
    || (
      // Staff can update if:
      // 1. They are assigned to the enquiry
      // 2. They are NOT modifying financial fields
      isStaff()
      && resource.data.assignedTo == request.auth.uid
      && isModifyingOnlyNonFinancialFields()
    );
}
```

## Rule Explanations

### Read Access
```javascript
allow read: if isAdmin()
  || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
```
- **Admins**: Can read all enquiries
- **Staff**: Can only read enquiries assigned to them
- **Unauthenticated**: Denied

### Create Access
```javascript
allow create: if isAdmin();
```
- **Admins**: Can create enquiries
- **Staff**: Denied (already was admin-only)
- **Unauthenticated**: Denied

### Delete Access
```javascript
allow delete: if isAdmin();
```
- **Admins**: Can delete enquiries
- **Staff**: **DENIED** (hardened - was already admin-only, now explicit)
- **Unauthenticated**: Denied

### Update Access
```javascript
allow update: if isAdmin()
  || (
    isStaff()
    && resource.data.assignedTo == request.auth.uid
    && isModifyingOnlyNonFinancialFields()
  );
```

**Admins:**
- Can update any enquiry
- Can modify all fields including financial fields
- No restrictions

**Staff:**
- Can update ONLY if ALL conditions are met:
  1. User is staff (`isStaff()`)
  2. Enquiry is assigned to them (`resource.data.assignedTo == request.auth.uid`)
  3. NOT modifying financial fields (`isModifyingOnlyNonFinancialFields()`)

**Financial Fields Protected:**
- `totalCost`
- `advancePaid`
- `paymentStatus`
- `paymentStatusValue`
- `paymentStatusLabel`

**Staff CAN Update:**
- `customerName`, `customerEmail`, `customerPhone`
- `eventType`, `eventDate`, `eventLocation`
- `status`, `statusValue`, `statusLabel`
- `notes`, `description`
- `assignedTo` (if admin assigns)
- `images` (reference images)
- All other non-financial fields

## Test Scenarios

### ✅ Allowed Operations

#### Admin Operations
1. **Admin reads any enquiry**
   - ✅ **ALLOWED** - Admin has full read access

2. **Admin creates enquiry**
   - ✅ **ALLOWED** - Admin can create enquiries

3. **Admin updates enquiry (including financial fields)**
   - ✅ **ALLOWED** - Admin can modify all fields
   - Example: Update `totalCost`, `advancePaid`, `paymentStatus`

4. **Admin deletes enquiry**
   - ✅ **ALLOWED** - Admin can delete enquiries

#### Staff Operations (Allowed)
5. **Staff reads assigned enquiry**
   - ✅ **ALLOWED** - Staff can read enquiries assigned to them

6. **Staff updates assigned enquiry (non-financial fields)**
   - ✅ **ALLOWED** - Staff can update non-financial fields
   - Example: Update `status`, `notes`, `eventDate`

7. **Staff updates assigned enquiry (multiple non-financial fields)**
   - ✅ **ALLOWED** - Staff can update multiple non-financial fields at once
   - Example: Update `status`, `notes`, `customerPhone` together

### ❌ Denied Operations

#### Staff Operations (Denied)
8. **Staff reads unassigned enquiry**
   - ❌ **DENIED** - Staff can only read assigned enquiries

9. **Staff creates enquiry**
   - ❌ **DENIED** - Only admins can create enquiries

10. **Staff deletes assigned enquiry**
    - ❌ **DENIED** - Staff cannot delete enquiries (even if assigned)

11. **Staff updates assigned enquiry (financial field)**
    - ❌ **DENIED** - Staff cannot modify financial fields
    - Example: Update `totalCost` → **DENIED**

12. **Staff updates assigned enquiry (paymentStatus)**
    - ❌ **DENIED** - Staff cannot modify payment status
    - Example: Update `paymentStatus` → **DENIED**

13. **Staff updates assigned enquiry (advancePaid)**
    - ❌ **DENIED** - Staff cannot modify advance paid
    - Example: Update `advancePaid` → **DENIED**

14. **Staff updates assigned enquiry (mixed: financial + non-financial)**
    - ❌ **DENIED** - If ANY financial field is modified, entire update is denied
    - Example: Update `status` + `totalCost` → **DENIED**

15. **Staff updates unassigned enquiry**
    - ❌ **DENIED** - Staff can only update assigned enquiries

#### Unauthenticated Operations
16. **Unauthenticated user reads enquiry**
    - ❌ **DENIED** - Must be signed in

17. **Unauthenticated user creates enquiry**
    - ❌ **DENIED** - Must be signed in

18. **Unauthenticated user updates enquiry**
    - ❌ **DENIED** - Must be signed in

19. **Unauthenticated user deletes enquiry**
    - ❌ **DENIED** - Must be signed in

## Financial Fields Protection

### Protected Fields
The following fields are protected from staff modification:

1. **`totalCost`** (double?)
   - Total cost of the event
   - Staff cannot modify

2. **`advancePaid`** (double?)
   - Advance payment amount
   - Staff cannot modify

3. **`paymentStatus`** / `paymentStatusValue`** (String?)
   - Payment status value (e.g., "paid", "pending", "unpaid")
   - Staff cannot modify

4. **`paymentStatusLabel`** (String?)
   - Human-readable payment status label
   - Staff cannot modify

### Why These Fields?
- **Financial integrity**: Prevents unauthorized changes to financial data
- **Audit compliance**: Financial fields should only be modified by authorized personnel
- **Business logic**: Payment status affects business workflows
- **Data accuracy**: Prevents accidental or malicious modification of financial records

## Edge Cases Handled

### 1. Partial Updates
If staff tries to update multiple fields including one financial field:
- **Result**: Entire update is denied
- **Reason**: Security rules check ALL modified fields, not individual fields

### 2. Field Removal
If staff tries to remove a financial field (set to null):
- **Result**: Denied (if field exists in resource)
- **Reason**: Removing a financial field is still considered modification

### 3. New Financial Fields
If staff tries to add a financial field to an enquiry that doesn't have it:
- **Result**: Denied
- **Reason**: Adding financial fields is still modification

### 4. Non-Existent Enquiry
If staff tries to update an enquiry that doesn't exist:
- **Result**: Denied
- **Reason**: `resource.data` doesn't exist, so assignment check fails

## Backward Compatibility

### ✅ Preserved Functionality

1. **Admin full access**: Admins retain all permissions
2. **Staff read access**: Staff can still read assigned enquiries
3. **Staff update access**: Staff can still update non-financial fields
4. **History subcollection**: Rules unchanged (staff can still create history entries)
5. **Notifications**: Rules unchanged
6. **User management**: Rules unchanged
7. **Dropdowns**: Rules unchanged

### ⚠️ Breaking Changes

1. **Staff cannot delete enquiries**: Was already admin-only, now explicit
2. **Staff cannot modify financial fields**: New restriction
3. **Staff cannot create enquiries**: Was already admin-only

## Deployment Checklist

- [x] Rules syntax validated
- [ ] Test rules locally using Firebase Emulator
- [ ] Deploy to staging environment
- [ ] Test all scenarios listed above
- [ ] Deploy to production
- [ ] Monitor Firestore logs for denied requests
- [ ] Update UI to hide financial fields from staff (if not already done)

## Testing Commands

### Test Rules Locally
```bash
# Start emulator
firebase emulators:start --only firestore

# Run tests
firebase emulators:exec --only firestore "npm test"
```

### Deploy Rules
```bash
# Deploy to production
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules:get
```

## Monitoring

After deployment, monitor Firestore logs for:
- Denied update requests from staff trying to modify financial fields
- Denied delete requests from staff
- Any unexpected permission denials

## Rollback Plan

If issues occur, revert to previous rules:

```bash
git revert <commit-hash>
firebase deploy --only firestore:rules
```

## Related Documentation

- `FIRESTORE_SECURITY_RULES.md` - Original security rules documentation
- `docs/FEATURE_MATRIX.md` - Feature matrix showing staff/admin capabilities
- `APP_FUNCTIONALITY_DOCUMENTATION.md` - Complete app functionality docs

