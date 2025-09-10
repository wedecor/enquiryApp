# Emulator E2E Test

Run with emulators managed for you:

```bash
npm run e2e:emu
```

## What it validates:

- Signup (admin/partner/staff), admin approval via callable
- Enquiry create → timestamps + derived balance
- Confirm → balance recompute + confirmedAt
- Assign → history growth (≥3 entries)

## Requirements:

- Firebase CLI installed
- Functions + rules match WeDecor implementation

## Test Flow:

1. **Admin Setup**: Creates admin user with proper claims
2. **User Creation**: Creates partner and staff users via Auth emulator
3. **User Approval**: Uses `approveUser` callable to approve users
4. **Event Type**: Ensures at least one event type exists
5. **Enquiry Creation**: Creates enquiry as partner user
6. **Balance Validation**: Verifies initial balance calculation
7. **Status Update**: Updates to confirmed with payment amounts
8. **Balance Recalculation**: Verifies trigger corrects balance
9. **Assignment**: Assigns enquiry to staff member
10. **History Check**: Verifies EnquiryHistory has ≥3 entries
11. **Cleanup**: Removes test data

## Expected Output:

```
== E2E starting for project: wedecorenquiries
approve partner: { ok: true }
approve staff: { ok: true }
✅ E2E passed. Enquiry: <id> History: 3
```

## Troubleshooting:

- Ensure emulators are running on default ports
- Check that Cloud Functions are deployed to emulator
- Verify Firestore rules allow the test operations
- Check console for any Firebase initialization errors
