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

## 📚 Related Documentation

- [Feature Matrix](FEATURE_MATRIX.md) - Complete capabilities comparison
- [Planned Features](PLANNED_FEATURES.md) - Future role enhancements
- [Firestore Security Rules](../FIRESTORE_SECURITY_RULES.md) - Complete rules documentation
- [Authentication Flow](AUTH_FLOW.md) - User authentication and role assignment

---

*Last Updated: September 21, 2024*  
*Version: v1.0.1+10*
