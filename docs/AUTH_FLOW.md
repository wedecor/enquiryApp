# WeDecor Auth & Staff Onboarding – Current Flow & Gaps

## 1. TL;DR

- **Admin "Add User"** creates only Firestore `users/{uid}` documents, NOT Firebase Auth accounts
- **Staff cannot log in** unless a Firebase Auth account already exists (via Console/scripts/invite function)
- **Current login** uses `signInWithEmailAndPassword` requiring both Auth account + Firestore user doc
- **Password source**: Admin must create Auth accounts via Console or scripts, staff use "Forgot Password" to set initial password
- **Invite system exists** but calls a non-existent Cloud Function `inviteUser`

## 2. Current Login Flow (Staff)

**File**: `lib/features/auth/presentation/screens/login_screen.dart`

### Step-by-step:
1. **App Launch** → User sees login screen
2. **User enters** email + password
3. **Login validation** (lines 105-134): Basic email/password validation
4. **Firebase Auth call** (lines 37-41): 
   ```dart
   await authService.signInWithEmailAndPassword(
     email: _emailController.text.trim(),
     password: _passwordController.text,
   );
   ```
5. **Auth Service** (`lib/core/services/firebase_auth_service.dart:91-98`):
   ```dart
   Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
     return await _auth.signInWithEmailAndPassword(email: email, password: password);
   }
   ```
6. **User Sync** (`lib/core/services/user_firestore_sync_service.dart:103-108`):
   - Listens to Firebase Auth state changes
   - Fetches corresponding Firestore user document from `users/{uid}`
   - Provides combined user data to the app

### Critical Dependencies:
- **Firebase Auth account** must exist with valid credentials
- **Firestore user document** at `users/{uid}` must exist with `role` field
- Both are required for successful login and app functionality

## 3. Admin "Add User" Behavior

**File**: `lib/features/admin/users/presentation/widgets/user_form_dialog.dart`

### Form Inputs (lines 57-120):
- Name (required)
- Email (required, read-only for edits)
- Phone (optional)
- Role (staff/admin dropdown)
- Active status (checkbox)

### What It Creates (lines 131-152):
```dart
final user = UserModel(
  uid: widget.user?.uid ?? '', // Will be set by Firestore
  name: _nameController.text.trim(),
  email: _emailController.text.trim(),
  phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
  role: _selectedRole,
  active: _isActive,
  // NO PASSWORD OR AUTH CREATION
);
await formController.createUser(user);
```

### Repository Action (`lib/features/admin/users/data/users_repository.dart:56-64`):
```dart
Future<void> createUserDoc(UserModel input) async {
  final userData = input.toFirestore();
  userData['createdAt'] = FieldValue.serverTimestamp();
  userData['updatedAt'] = FieldValue.serverTimestamp();
  await _firestore.collection('users').doc(input.uid).set(userData);
}
```

**❌ NO Firebase Auth account is created** - only Firestore document

## 4. Does the system send invites or reset links?

### Invite System Present:
**File**: `lib/features/admin/users/presentation/invite_user_dialog.dart`

- **UI exists** with form for name, email, role (lines 42-99)
- **Calls Cloud Function** `inviteUser` (lines 198-205):
  ```dart
  final callable = functions.httpsCallable('inviteUser');
  final result = await callable.call({
    'email': _emailController.text.trim(),
    'name': _nameController.text.trim(),
    'role': _selectedRole.name,
  });
  ```
- **Expects reset link** in response (lines 207-213)

### ❌ Cloud Function Missing:
**File**: `functions/src/index.ts` - **No `inviteUser` function exists**

Only contains `notifyOnEnquiryChange` for push notifications.

## 5. Where passwords come from

### Current Sources:
1. **Scripts/Console**: `scripts/create_admin_user.js` creates Auth account with password
2. **Seeding**: `lib/shared/seed_data.dart:216` uses `createUserWithEmailAndPassword`
3. **Manual Console**: Admin creates Auth users manually in Firebase Console
4. **Missing**: No automated invite system with password reset links

### Password Reset:
- **No explicit "Forgot Password" UI** in login screen
- Users would need to use Firebase Auth's built-in password reset via Console

## 6. Gaps & Risks

### Critical Gap:
- **Admin "Add User" creates orphaned Firestore documents** without corresponding Auth accounts
- **Staff cannot log in** with just a Firestore user document
- **No automated onboarding flow** for new staff members

### Security Risk:
- **Manual Auth account creation** required via Console/scripts
- **No standardized password policy** enforcement
- **No audit trail** for user creation process

### UX Issues:
- **Confusing for admins**: "Add User" appears to work but user cannot actually log in
- **No self-service capability** for staff to set passwords
- **Manual coordination required** between Firestore and Auth systems

## 7. Safe Options to Close Gaps

### Option A (Recommended): Admin 'Invite User' Function
**Flow**: 
1. Admin enters name/email/role in invite dialog
2. Call `inviteUser` Cloud Function (admin-only)
3. Function: `admin.auth().createUser({email, disabled:false})`
4. Function: `generatePasswordResetLink(email)`
5. Function: Create/update Firestore `users/{uid}` document
6. Function: Return reset link to admin
7. Admin shares reset link with staff
8. Staff sets password via Firebase Auth
9. Staff logs in normally

**Implementation**: Create missing Cloud Function in `functions/src/index.ts`

### Option B: Email-link Sign-in
**Flow**:
1. Admin creates Firestore user document (current flow)
2. Staff uses "Sign in with Email Link" option
3. System sends magic link to email
4. Staff clicks link and completes sign-in
5. Auto-creates Auth account on first successful link sign-in

**Implementation**: Add `sendSignInLinkToEmail` and `signInWithEmailLink` to auth service

### Option C: Self-signup + Approval
**Flow**:
1. Add "Request Access" page for staff
2. Staff enters email/name and submits
3. Creates Auth account as `disabled:true`
4. Creates Firestore document with `active:false`
5. Admin receives notification to approve
6. Admin activates user in admin panel
7. System enables Auth account and sends welcome email

**Implementation**: Add signup page and approval workflow

## 8. Acceptance Checks (Today)

### Test Scenarios:

**❌ Scenario 1**: "Can a brand-new staff with only a Firestore doc log in?"
- **Expected**: No - Firebase Auth account required
- **Test**: Create user via Admin panel, attempt login
- **Result**: Authentication will fail at Firebase Auth level

**❌ Scenario 2**: "If an Auth user exists but no Firestore user doc, what happens?"
- **Expected**: Login succeeds but app functionality fails
- **Test**: Create Auth user via Console, attempt login
- **Result**: `user_firestore_sync_service.dart:103` will fail to find user document

**✅ Scenario 3**: "Forgot password path working?"
- **Expected**: No explicit UI, but Firebase Auth supports it
- **File**: No implementation in `login_screen.dart`
- **Manual**: Users can request reset via Firebase Console

**✅ Scenario 4**: "Admin can create Firestore user documents?"
- **Expected**: Yes
- **Files**: `user_form_dialog.dart:131-152`, `users_repository.dart:56-64`
- **Result**: Successfully creates Firestore documents

## 9. Appendix: Evidence Links

### Authentication Flow:
- **Login Screen**: `lib/features/auth/presentation/screens/login_screen.dart:37-41`
- **Auth Service**: `lib/core/services/firebase_auth_service.dart:91-98`
- **User Sync**: `lib/core/services/user_firestore_sync_service.dart:103-108`

### Admin User Creation:
- **Form Dialog**: `lib/features/admin/users/presentation/widgets/user_form_dialog.dart:131-152`
- **Repository**: `lib/features/admin/users/data/users_repository.dart:56-64`
- **Provider**: `lib/features/admin/users/presentation/users_providers.dart:70-78`

### Invite System:
- **Invite Dialog**: `lib/features/admin/users/presentation/invite_user_dialog.dart:198-205`
- **Missing Function**: `functions/src/index.ts` (only has `notifyOnEnquiryChange`)

### Scripts & Seeding:
- **Admin Creation**: `scripts/create_admin_user.js:24-29` (creates Auth + Firestore)
- **Seed Data**: `lib/shared/seed_data.dart:216-220` (creates Auth + Firestore)

### Security Rules:
- **User Access**: `firestore.rules:13-16` (requires Auth + Firestore doc for `isAdmin()`)
- **Auth Dependency**: `firestore.rules:6-10` (admin check requires both Auth UID and Firestore role)

---

**Analysis Date**: September 19, 2025  
**Status**: Documentation complete - gaps identified, solutions proposed
