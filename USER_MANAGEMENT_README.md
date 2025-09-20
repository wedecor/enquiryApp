# User Management Module - WeDecor Enquiries App

## Overview

A complete, production-ready User Management module for the WeDecor Enquiries app with list, search, filters, pagination, create/edit, role assignment, and activate/deactivate functionality, wired to Firestore.

## Features

### ✅ Core Functionality
- **User List**: Paginated table (desktop) and card layout (mobile)
- **Search**: Real-time search by name and email with debouncing
- **Filters**: Filter by role (All/Admin/Staff) and status (All/Active/Inactive)
- **Pagination**: Load more functionality with stable sorting
- **Create User**: Add new users with validation
- **Edit User**: Update user details (email is read-only after creation)
- **Role Management**: Assign admin or staff roles
- **Activate/Deactivate**: Toggle user access without deletion

### ✅ Security & Permissions
- **Admin-only operations**: Only admins can create, edit, or deactivate users
- **Role-based UI**: Non-admin users see read-only interface
- **Firestore Security Rules**: Enforce admin-only writes to user documents
- **Email immutability**: Email cannot be changed after user creation

### ✅ User Experience
- **Responsive Design**: Adapts to different screen sizes
- **Material 3 Design**: Consistent with app's design system
- **Loading States**: Proper loading indicators and error handling
- **Form Validation**: Client-side validation for all inputs
- **Confirmation Dialogs**: Safe activation/deactivation with confirmation
- **Success/Error Feedback**: Clear snackbar messages for all operations

## Technical Implementation

### Architecture
- **Riverpod 2.x**: State management with code generation
- **Freezed**: Immutable data classes with JSON serialization
- **Firestore**: Real-time data synchronization
- **Material 3**: Modern Flutter UI components

### File Structure
```
lib/features/admin/users/
├── domain/
│   └── user_model.dart              # UserModel with Freezed
├── data/
│   └── users_repository.dart        # Firestore operations
├── presentation/
│   ├── users_providers.dart         # Riverpod providers
│   ├── user_management_screen.dart  # Main screen
│   └── widgets/
│       ├── user_form_dialog.dart    # Create/Edit dialog
│       └── confirm_dialog.dart      # Confirmation dialog
```

### Data Model
```dart
{
  "uid": "string",           // Firebase Auth UID
  "name": "string",          // Display name
  "email": "string",         // Email (immutable after creation)
  "phone": "string|null",    // Optional phone number
  "role": "admin|staff",     // User role
  "active": true,            // Access status
  "fcmToken": null,          // Push notification token
  "createdAt": Timestamp,    // Creation timestamp
  "updatedAt": Timestamp     // Last update timestamp
}
```

## Setup Instructions

### 1. Prerequisites
- Flutter 3.8.1+
- Firebase project with Firestore enabled
- Admin user with role "admin" in Firestore

### 2. Navigation
The User Management screen is accessible from the main dashboard sidebar:
- Click the hamburger menu (☰)
- Select "User Management"
- Screen opens at `/admin/users`

### 3. Admin Setup
Ensure you have an admin user in Firestore:
```json
{
  "uid": "your-admin-uid",
  "name": "Admin User",
  "email": "admin@wedecorevents.com",
  "role": "admin",
  "active": true,
  "createdAt": "2023-01-01T00:00:00Z",
  "updatedAt": "2023-01-01T00:00:00Z"
}
```

## Usage Guide

### For Admins

#### Adding Users
1. Click "Add User" button
2. Fill in required fields:
   - **Name**: User's display name
   - **Email**: User's email address (will be used for login)
   - **Phone**: Optional phone number
   - **Role**: Admin or Staff
   - **Active**: Enable/disable access
3. Click "Create"
4. User will be created in Firestore (Auth sync requires Cloud Functions)

#### Editing Users
1. Click edit icon (✏️) next to any user
2. Modify fields (email is read-only)
3. Click "Update"
4. Changes are saved to Firestore

#### Managing Access
1. Click activate/deactivate icon (✓/🚫) next to any user
2. Confirm the action in the dialog
3. User's access is toggled immediately

#### Filtering & Search
- **Search**: Type in the search box to filter by name or email
- **Role Filter**: Select "All Roles", "Admin", or "Staff"
- **Status Filter**: Select "All Status", "Active", or "Inactive"
- **Pagination**: Click "Load More..." to see additional users

### For Non-Admin Users
- Can view the user list (read-only)
- Cannot create, edit, or deactivate users
- Add User button is hidden
- Action buttons are disabled

## Security Rules

The module uses Firestore security rules to enforce permissions:

```javascript
// Users collection - Admin only writes
match /users/{uid} {
  allow read: if isSignedIn();
  allow create, update, delete: if isAdmin();
}

function isAdmin() {
  return isSignedIn()
    && exists(/databases/$(database)/documents/users/$(request.auth.uid))
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
}
```

## Optional: Cloud Functions (Auth Sync)

For complete Auth ↔ Firestore synchronization, deploy the optional Cloud Functions:

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

Functions provided:
- `onUserCreated`: Creates Auth user when Firestore doc is created
- `onUserUpdated`: Updates Auth user when role/status changes
- `onUserDeleted`: Deletes Auth user when Firestore doc is deleted

## Testing

Run the test suite:
```bash
flutter test test/features/admin/users/
```

Test coverage includes:
- ✅ UserModel serialization and utilities
- ✅ Filter state management
- ✅ Pagination logic
- ✅ Widget rendering and interactions
- ✅ Error handling

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure current user has `role: "admin"` in Firestore
   - Check Firestore security rules are deployed

2. **Users Not Loading**
   - Verify Firestore connection
   - Check browser console for errors
   - Ensure user has read permissions

3. **Create/Edit Not Working**
   - Verify admin role in current user document
   - Check Firestore write permissions
   - Ensure security rules are deployed

4. **Search Not Working**
   - Search is client-side only
   - Check for typos in search terms
   - Verify users have name/email data

### Debug Mode
Enable debug logging by checking browser console for:
- Provider state changes
- Firestore query results
- Form validation errors

## Future Enhancements

Potential improvements for future versions:
- **Bulk Operations**: Select multiple users for batch actions
- **Advanced Search**: Server-side search with Firestore indexes
- **User Import/Export**: CSV import/export functionality
- **Audit Trail**: Track all user management actions
- **Profile Pictures**: Avatar support for users
- **Custom Roles**: Beyond admin/staff roles
- **User Groups**: Organize users into teams/departments

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firestore security rules
3. Verify admin user setup
4. Check browser console for errors

---

## Recent Updates (December 2024)

### ✅ Fixed Role Consistency Issue
- **Issue**: InviteUserDialog was using `UserRole` enum from shared models while admin users use string-based roles
- **Solution**: Updated InviteUserDialog to use string-based roles ('admin', 'staff') for consistency
- **Impact**: Resolved compilation errors and improved type safety

### ✅ Code Quality Improvements
- Fixed all Flutter analyzer warnings including:
  - Type inference issues with Cloud Functions calls
  - Deprecated `withOpacity()` usage (replaced with `withValues()`)
  - Untyped error parameters in catch blocks
  - Missing type arguments for dialog functions
- **Result**: Clean codebase with zero linter warnings

### ✅ Enhanced User Invitation Flow
- Improved type safety in Cloud Functions integration
- Better error handling for invitation process
- Cleaner UI with proper role selection dropdown

---

**Status**: ✅ Production Ready  
**Last Updated**: December 2024  
**Version**: 1.1.0 (Updated with bug fixes and improvements)

