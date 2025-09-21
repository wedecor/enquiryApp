# RBAC Quick Reference Guide

## 🔐 Role-Based Access Control (RBAC) Implementation

This guide provides a quick reference for implementing and maintaining role-based access control in the We Decor Enquiries application.

---

## 🎯 Three-Layer Security Model

Every restricted action MUST be protected at all three layers:

### **1. UI Gating (First Line of Defense)**
Hide or disable admin-only buttons, menus, and screens for non-admin users.

```dart
// Example: Conditional UI rendering
if (userRole == UserRole.admin) ...[
  IconButton(
    icon: Icon(Icons.delete),
    onPressed: () => deleteEnquiry(),
    tooltip: 'Delete Enquiry',
  ),
] else ...[
  // Show disabled state or alternative action
  IconButton(
    icon: Icon(Icons.delete),
    onPressed: null, // Disabled
    tooltip: 'Admin only',
  ),
],
```

### **2. Service/Provider Gating (Business Logic)**
Call `requireAdmin(ref)` at action entry points before executing sensitive operations.

```dart
// Example: Service-level protection
Future<void> deleteEnquiry(String enquiryId, WidgetRef ref) async {
  requireAdmin(ref); // Throws if not admin
  await logAdminAction(ref, 'delete_enquiry', {'enquiryId': enquiryId});
  
  // Proceed with deletion
  await FirebaseFirestore.instance
    .collection('enquiries')
    .doc(enquiryId)
    .delete();
}
```

### **3. Firestore Rules (Final Enforcement)**
Enforce least privilege at the database level, even if UI/service layers are bypassed.

```javascript
// Example: Database-level enforcement
match /enquiries/{id} {
  allow read: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
  allow create, delete: if isAdmin();
  allow update: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
}
```

---

## 🛡️ Role Guard Functions

### **Core Guards**
```dart
// Check if current user is admin
bool isAdmin(WidgetRef ref) => ref.read(isAdminValueProvider);

// Require admin role (throws if not admin)
void requireAdmin(WidgetRef ref) {
  if (!isAdmin(ref)) throw StateError('Admin only');
}

// Check if user can edit specific enquiry
bool canEditEnquiry(WidgetRef ref, {required String? assigneeId}) {
  if (isAdmin(ref)) return true;
  final uid = ref.watch(firebaseAuthUserProvider).valueOrNull?.uid;
  return uid != null && assigneeId == uid;
}
```

### **Audit Logging**
```dart
// Log admin actions for compliance
await logAdminAction(ref, 'action_name', {
  'targetId': 'resource_id',
  'details': 'action_details',
});
```

---

## 📋 Implementation Checklist

### **For Every Admin-Only Feature:**

#### **☑️ UI Layer**
- [ ] Hide/disable admin-only buttons for staff users
- [ ] Show appropriate tooltips ("Admin only")
- [ ] Redirect staff users away from admin screens
- [ ] Display role-appropriate empty states

#### **☑️ Service Layer** 
- [ ] Add `requireAdmin(ref)` at method entry
- [ ] Log admin actions with `logAdminAction()`
- [ ] Validate permissions before database operations
- [ ] Return appropriate error messages for unauthorized access

#### **☑️ Database Layer**
- [ ] Firestore rules enforce admin-only operations
- [ ] Test rules with Firebase Emulator
- [ ] Verify rules handle edge cases
- [ ] Document rule changes in security reviews

---

## 🔍 Common Patterns

### **Admin-Only Screen Access**
```dart
class AdminOnlyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAdmin(ref)) {
      return Scaffold(
        appBar: AppBar(title: Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 64),
              Text('Admin access required'),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Admin content here
    return AdminContent();
  }
}
```

### **Conditional Menu Items**
```dart
PopupMenuButton<String>(
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'export',
      child: ListTile(
        leading: Icon(Icons.download),
        title: Text('Export CSV'),
      ),
    ),
    if (isAdmin(ref)) ...[
      PopupMenuItem(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete),
          title: Text('Delete'),
        ),
      ),
      PopupMenuItem(
        value: 'analytics',
        child: ListTile(
          leading: Icon(Icons.analytics),
          title: Text('View Analytics'),
        ),
      ),
    ],
  ],
)
```

### **Data Filtering by Role**
```dart
// Staff sees only assigned enquiries
Stream<QuerySnapshot> getEnquiriesStream(UserRole? role, String userId) {
  if (role == UserRole.admin) {
    return FirebaseFirestore.instance
        .collection('enquiries')
        .orderBy('createdAt', descending: true)
        .snapshots();
  } else {
    return FirebaseFirestore.instance
        .collection('enquiries')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
```

---

## 🔒 Firestore Security Rules Reference

### **User Collection**
```javascript
match /users/{uid} {
  allow read: if isSignedIn();                     // All can read profiles
  allow create, update, delete: if isAdmin();      // Only admin can manage users
}
```

### **Enquiries Collection**
```javascript
match /enquiries/{id} {
  allow read: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
  allow create, delete: if isAdmin();
  allow update: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
    
  // History subcollection
  match /history/{historyId} {
    allow read: if isAdmin()
      || (isSignedIn() && get(/databases/$(database)/documents/enquiries/$(id)).data.assignedTo == request.auth.uid);
    allow create, update: if isAdmin()
      || (isSignedIn() && get(/databases/$(database)/documents/enquiries/$(id)).data.assignedTo == request.auth.uid);
    allow delete: if isAdmin();
  }
}
```

### **Admin-Only Collections**
```javascript
match /analytics/{doc=**} {
  allow read: if isAdmin();
}

match /dropdowns/{group}/items/{value} {
  allow read: if isSignedIn();
  allow create, update, delete: if isAdmin();
}
```

---

## 🧪 Testing Guidelines

### **Role-Based Testing**
```dart
// Test admin access
testWidgets('Admin can access user management', (tester) async {
  await tester.pumpWidget(AppWithAdminUser());
  expect(find.text('User Management'), findsOneWidget);
});

// Test staff restrictions
testWidgets('Staff cannot access analytics', (tester) async {
  await tester.pumpWidget(AppWithStaffUser());
  expect(find.text('Analytics'), findsNothing);
});
```

### **Security Rule Testing**
```bash
# Test Firestore rules
firebase emulators:exec --only firestore "npm run test:rules"
```

---

## 🚨 Security Best Practices

### **Never Trust the Client**
- Always validate permissions on the server (Firestore rules)
- UI hiding is for UX, not security
- Assume malicious clients will try to bypass UI restrictions

### **Principle of Least Privilege**
- Grant minimum permissions required for role function
- Regularly audit and review role assignments
- Log all admin actions for compliance

### **Defense in Depth**
- Multiple layers of protection (UI + Service + Database)
- Fail securely (deny by default)
- Monitor and alert on permission violations

---

## 🧪 Quick Rules Check Procedure

### **Firestore Rules Validation**

To verify that Firestore security rules are working correctly, follow this procedure:

```bash
# 1. Start Firebase emulators
firebase emulators:start --only firestore &

# 2. In another terminal, run basic rule tests
# Test staff reading assigned doc (should succeed)
curl -X GET "http://localhost:8080/v1/projects/test-project/databases/(default)/documents/enquiries/test-enquiry-1" \
  -H "Authorization: Bearer $(firebase auth:print-access-token)"

# Test staff reading unassigned doc (should fail with permission denied)
curl -X GET "http://localhost:8080/v1/projects/test-project/databases/(default)/documents/enquiries/unassigned-enquiry" \
  -H "Authorization: Bearer $(firebase auth:print-access-token)"

# Test staff deleting enquiry (should fail with permission denied)
curl -X DELETE "http://localhost:8080/v1/projects/test-project/databases/(default)/documents/enquiries/test-enquiry-1" \
  -H "Authorization: Bearer $(firebase auth:print-access-token)"

# Test admin deleting enquiry (should succeed)
curl -X DELETE "http://localhost:8080/v1/projects/test-project/databases/(default)/documents/enquiries/admin-test-enquiry" \
  -H "Authorization: Bearer $(firebase auth:print-access-token)"
```

### **Manual Testing Checklist**

#### **Staff User Testing**
- [ ] Can only see enquiries with `assignedTo == currentUserId`
- [ ] Can update status of assigned enquiries
- [ ] Cannot create new enquiries
- [ ] Cannot delete enquiries
- [ ] Cannot see financial fields in enquiry details
- [ ] CSV export only includes assigned enquiries
- [ ] CSV export excludes financial columns

#### **Admin User Testing**
- [ ] Can see all enquiries regardless of assignment
- [ ] Can create, update, delete any enquiry
- [ ] Can see all financial fields
- [ ] Can manage users (invite, role changes, activate/deactivate)
- [ ] Can access analytics dashboard
- [ ] Can configure system settings (dropdowns, defaults)
- [ ] CSV export includes all enquiries and all columns

#### **Security Boundary Testing**
- [ ] Staff cannot access `/admin/*` routes
- [ ] Staff cannot modify `assignedTo` field
- [ ] Staff cannot access other users' data
- [ ] Admin actions are logged in `admin_audit` collection
- [ ] Firestore rules block unauthorized access attempts

### **Automated Rules Testing**

For comprehensive rules testing, create a test script:

```bash
# test_firestore_rules.sh
#!/bin/bash

echo "🔥 Testing Firestore Security Rules..."

# Start emulator
firebase emulators:start --only firestore --project test-project &
EMULATOR_PID=$!

# Wait for emulator to start
sleep 5

# Run test cases
echo "✅ Testing staff permissions..."
# Add your test cases here

echo "✅ Testing admin permissions..."
# Add your test cases here

# Stop emulator
kill $EMULATOR_PID

echo "🎉 Rules testing complete!"
```

---

## 📚 Related Documentation

- [Feature Matrix](FEATURE_MATRIX.md) - Complete capabilities comparison
- [Planned Features](PLANNED_FEATURES.md) - Future role enhancements
- [Firestore Security Rules](../FIRESTORE_SECURITY_RULES.md) - Complete rules documentation
- [Authentication Flow](AUTH_FLOW.md) - User authentication and role assignment

---

*Last Updated: September 21, 2024*  
*Version: v1.0.1+10*
