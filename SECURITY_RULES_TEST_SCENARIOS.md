# Firestore Security Rules - Test Scenarios

## Quick Reference

### ✅ Allowed Operations

| Operation | Admin | Staff (Assigned) | Staff (Unassigned) |
|-----------|-------|------------------|---------------------|
| Read enquiry | ✅ All | ✅ Assigned only | ❌ Denied |
| Create enquiry | ✅ Yes | ❌ No | ❌ No |
| Update non-financial fields | ✅ Yes | ✅ Assigned only | ❌ Denied |
| Update financial fields | ✅ Yes | ❌ No | ❌ No |
| Delete enquiry | ✅ Yes | ❌ No | ❌ No |

## Detailed Test Scenarios

### Scenario 1: Admin Reads Any Enquiry
**User:** Admin  
**Action:** Read enquiry `enquiry123`  
**Expected:** ✅ **ALLOWED**  
**Reason:** Admins have full read access to all enquiries

```javascript
// Rule: allow read: if isAdmin()
// Result: ALLOWED
```

---

### Scenario 2: Staff Reads Assigned Enquiry
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff123"`  
**Action:** Read enquiry  
**Expected:** ✅ **ALLOWED**  
**Reason:** Staff can read enquiries assigned to them

```javascript
// Rule: allow read: if isAdmin() || (isSignedIn() && resource.data.assignedTo == request.auth.uid)
// Result: ALLOWED (second condition matches)
```

---

### Scenario 3: Staff Reads Unassigned Enquiry
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff456"`  
**Action:** Read enquiry  
**Expected:** ❌ **DENIED**  
**Reason:** Staff can only read assigned enquiries

```javascript
// Rule: allow read: if isAdmin() || (isSignedIn() && resource.data.assignedTo == request.auth.uid)
// Result: DENIED (neither condition matches)
```

---

### Scenario 4: Admin Creates Enquiry
**User:** Admin  
**Action:** Create new enquiry  
**Expected:** ✅ **ALLOWED**  
**Reason:** Only admins can create enquiries

```javascript
// Rule: allow create: if isAdmin()
// Result: ALLOWED
```

---

### Scenario 5: Staff Creates Enquiry
**User:** Staff  
**Action:** Create new enquiry  
**Expected:** ❌ **DENIED**  
**Reason:** Staff cannot create enquiries

```javascript
// Rule: allow create: if isAdmin()
// Result: DENIED
```

---

### Scenario 6: Admin Updates Enquiry (Financial Fields)
**User:** Admin  
**Enquiry:** Any enquiry  
**Action:** Update `totalCost: 50000`, `advancePaid: 10000`  
**Expected:** ✅ **ALLOWED**  
**Reason:** Admins can modify all fields including financial

```javascript
// Rule: allow update: if isAdmin() || (isStaff() && ...)
// Result: ALLOWED (first condition matches)
```

---

### Scenario 7: Staff Updates Assigned Enquiry (Non-Financial)
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff123"`  
**Action:** Update `status: "confirmed"`, `notes: "Customer confirmed"`  
**Expected:** ✅ **ALLOWED**  
**Reason:** Staff can update non-financial fields of assigned enquiries

```javascript
// Rule: allow update: if isAdmin() || (isStaff() && resource.data.assignedTo == request.auth.uid && isModifyingOnlyNonFinancialFields())
// Result: ALLOWED (all conditions match)
```

---

### Scenario 8: Staff Updates Assigned Enquiry (Financial Field)
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff123"`  
**Action:** Update `totalCost: 50000`  
**Expected:** ❌ **DENIED**  
**Reason:** Staff cannot modify financial fields

```javascript
// Rule: allow update: if isAdmin() || (isStaff() && resource.data.assignedTo == request.auth.uid && isModifyingOnlyNonFinancialFields())
// Result: DENIED (isModifyingOnlyNonFinancialFields() returns false)
```

---

### Scenario 9: Staff Updates Assigned Enquiry (Mixed Fields)
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff123"`  
**Action:** Update `status: "confirmed"` AND `totalCost: 50000`  
**Expected:** ❌ **DENIED**  
**Reason:** If ANY financial field is modified, entire update is denied

```javascript
// Rule: allow update: if isAdmin() || (isStaff() && resource.data.assignedTo == request.auth.uid && isModifyingOnlyNonFinancialFields())
// Result: DENIED (isModifyingOnlyNonFinancialFields() returns false because totalCost is modified)
```

---

### Scenario 10: Staff Updates Unassigned Enquiry
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff456"`  
**Action:** Update `status: "confirmed"`  
**Expected:** ❌ **DENIED**  
**Reason:** Staff can only update assigned enquiries

```javascript
// Rule: allow update: if isAdmin() || (isStaff() && resource.data.assignedTo == request.auth.uid && isModifyingOnlyNonFinancialFields())
// Result: DENIED (resource.data.assignedTo != request.auth.uid)
```

---

### Scenario 11: Admin Deletes Enquiry
**User:** Admin  
**Enquiry:** Any enquiry  
**Action:** Delete enquiry  
**Expected:** ✅ **ALLOWED**  
**Reason:** Only admins can delete enquiries

```javascript
// Rule: allow delete: if isAdmin()
// Result: ALLOWED
```

---

### Scenario 12: Staff Deletes Assigned Enquiry
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff123"`  
**Action:** Delete enquiry  
**Expected:** ❌ **DENIED**  
**Reason:** Staff cannot delete enquiries (even if assigned)

```javascript
// Rule: allow delete: if isAdmin()
// Result: DENIED
```

---

### Scenario 13: Staff Updates Payment Status
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff123"`  
**Action:** Update `paymentStatus: "paid"`  
**Expected:** ❌ **DENIED**  
**Reason:** Payment status is a financial field

```javascript
// Financial fields: ['totalCost', 'advancePaid', 'paymentStatus', 'paymentStatusValue', 'paymentStatusLabel']
// Result: DENIED
```

---

### Scenario 14: Staff Updates Advance Paid
**User:** Staff (uid: `staff123`)  
**Enquiry:** `enquiry123` with `assignedTo: "staff123"`  
**Action:** Update `advancePaid: 5000`  
**Expected:** ❌ **DENIED**  
**Reason:** Advance paid is a financial field

```javascript
// Financial fields: ['totalCost', 'advancePaid', 'paymentStatus', 'paymentStatusValue', 'paymentStatusLabel']
// Result: DENIED
```

---

### Scenario 15: Unauthenticated User Reads Enquiry
**User:** Not signed in  
**Action:** Read enquiry  
**Expected:** ❌ **DENIED**  
**Reason:** Must be authenticated

```javascript
// Rule: allow read: if isAdmin() || (isSignedIn() && resource.data.assignedTo == request.auth.uid)
// Result: DENIED (isSignedIn() returns false)
```

---

## Financial Fields List

The following fields are protected from staff modification:

1. `totalCost` - Total cost of the event
2. `advancePaid` - Advance payment amount
3. `paymentStatus` - Payment status value
4. `paymentStatusValue` - Payment status value (alternative field name)
5. `paymentStatusLabel` - Human-readable payment status label

## Testing Checklist

Use this checklist to verify rules work correctly:

- [ ] Admin can read any enquiry
- [ ] Admin can create enquiry
- [ ] Admin can update enquiry (including financial fields)
- [ ] Admin can delete enquiry
- [ ] Staff can read assigned enquiry
- [ ] Staff cannot read unassigned enquiry
- [ ] Staff cannot create enquiry
- [ ] Staff can update assigned enquiry (non-financial fields)
- [ ] Staff cannot update assigned enquiry (financial fields)
- [ ] Staff cannot update assigned enquiry (mixed: financial + non-financial)
- [ ] Staff cannot update unassigned enquiry
- [ ] Staff cannot delete enquiry (even if assigned)
- [ ] Unauthenticated users cannot access enquiries

## Automated Testing

To test rules programmatically, use Firebase Emulator:

```bash
# Start emulator
firebase emulators:start --only firestore

# Run tests
firebase emulators:exec --only firestore "npm test"
```

Sample test structure:
```javascript
describe('Enquiry Security Rules', () => {
  it('should allow admin to update financial fields', async () => {
    const adminAuth = getAuth(adminApp);
    const db = getFirestore(adminApp);
    
    await firebase.assertSucceeds(
      updateDoc(doc(db, 'enquiries', 'enquiry123'), {
        totalCost: 50000,
        advancePaid: 10000
      })
    );
  });
  
  it('should deny staff from updating financial fields', async () => {
    const staffAuth = getAuth(staffApp);
    const db = getFirestore(staffApp);
    
    await firebase.assertFails(
      updateDoc(doc(db, 'enquiries', 'enquiry123'), {
        totalCost: 50000
      })
    );
  });
});
```

