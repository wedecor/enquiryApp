# We Decor Enquiries - Feature Matrix

## 📋 Roles & Capabilities

This document provides the authoritative reference for what Staff and Admin users can access and perform within the We Decor Enquiries application.

---

## 🔐 Data Access Permissions

| Feature | Staff | Admin | Notes |
|---------|-------|-------|-------|
| **View own enquiries** | ✅ | ✅ | Staff constrained by assignment |
| **View all enquiries** | ❌ | ✅ | Admin sees system-wide data |
| **Create enquiries** | ❌ | ✅ | Only admins can create new enquiries |
| **Edit assigned enquiries** | ✅ | ✅ | Staff: assigned only (rules enforce) |
| **Edit any enquiry** | ❌ | ✅ | Admin can edit any enquiry |
| **Delete enquiries** | ❌ | ✅ | Only admins can delete |
| **View financial fields** | ❌ | ✅ | Total cost, advance paid, payment status |
| **Modify financial fields** | ❌ | ✅ | Staff cannot see/edit financial data |
| **Assign enquiries** | ❌ | ✅ | Only admins can assign to staff |
| **Change history access** | ✅ | ✅ | Both can view audit trails |

---

## 🏗️ System Access Permissions

| Feature | Staff | Admin | Notes |
|---------|-------|-------|-------|
| **User management** | ❌ | ✅ | Invite, edit roles, activate/deactivate |
| **Send user invitations** | ❌ | ✅ | Email invitations via Firebase Functions |
| **Analytics dashboard** | ❌ | ✅ | KPIs, trends, breakdowns, top lists |
| **System configuration** | ❌ | ✅ | Dropdowns, dashboard defaults |
| **Dropdown management** | ❌ | ✅ | Event types, statuses, priorities, sources |
| **Export data** | ✅ (assigned only) | ✅ (all) | Staff export redacts sensitive fields |
| **App configuration** | ❌ | ✅ | System-wide settings and preferences |

---

## 🎨 User Experience Features

| Feature | Staff | Admin | Notes |
|---------|-------|-------|-------|
| **Dark/Light theme** | ✅ | ✅ | Implemented - Settings → Preferences |
| **Push notifications** | ✅ | ✅ | Implemented - Firebase Cloud Messaging |
| **In-app feedback** | ✅ | ✅ | Implemented - Settings → Privacy |
| **Change notifications** | ✅ | ✅ | Notifications for enquiry updates |
| **Advanced filters** | ✅ | ✅ | Implemented - Faceted search |
| **Saved views** | ✅ | ✅ | Implemented - User-specific filter presets |
| **Manual update check** | ✅ | ✅ | Implemented - Settings → Account |
| **Accessibility support** | ✅ | ✅ | Implemented - Screen reader, tap targets |
| **Language/Timezone** | 🔜 | 🔜 | Planned (i18n scaffold) |

---

## 📱 Screen Access Matrix

### **Dashboard & Navigation**
| Screen | Staff Access | Admin Access |
|--------|-------------|-------------|
| **Dashboard** | ✅ Assigned enquiries only | ✅ All enquiries |
| **Enquiries List** | ✅ "My Enquiries" | ✅ "All Enquiries" |
| **Enquiry Details** | ✅ Assigned only | ✅ Any enquiry |
| **Enquiry Form** | ❌ Create, ✅ Edit assigned | ✅ Full CRUD |

### **Administrative Screens**
| Screen | Staff Access | Admin Access |
|--------|-------------|-------------|
| **User Management** | ❌ Hidden | ✅ Full access |
| **Analytics** | ❌ Hidden | ✅ Full access |
| **Dropdown Management** | ❌ Hidden | ✅ Full access |
| **Admin Settings** | ❌ Hidden | ✅ Full access |

### **Settings Screens**
| Tab | Staff Access | Admin Access |
|-----|-------------|-------------|
| **Account** | ✅ Profile, password, updates | ✅ Full access |
| **Preferences** | ✅ Theme, language, timezone | ✅ Full access |
| **Notifications** | ✅ Personal preferences | ✅ Full access |
| **Privacy** | ✅ Data consent, feedback | ✅ Full access |
| **Dashboard Defaults** | ✅ Personal defaults | ✅ System defaults |
| **Admin Panel** | ❌ Hidden | ✅ System configuration |

---

## 🔧 Technical Implementation

### **Role Detection**
```dart
// Current user role detection
final userRole = ref.watch(currentUserRoleProvider);
final isAdmin = userRole == 'admin';
final isStaff = userRole == 'staff';
```

### **Firestore Security Rules**
```javascript
// Enquiries access control
match /enquiries/{id} {
  allow read: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
  allow create, delete: if isAdmin();
  allow update: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
}

// User management (admin only)
match /users/{uid} {
  allow read: if isSignedIn();
  allow create, update, delete: if isAdmin();
}
```

### **UI Conditional Rendering**
```dart
// Example: Hide admin-only features
if (userRole == UserRole.admin) ...[
  // Admin-only widgets
  AdminAnalyticsCard(),
  UserManagementButton(),
],

// Example: Conditional navigation
ListTile(
  title: Text('Analytics'),
  onTap: userRole == UserRole.admin ? () => navigateToAnalytics() : null,
  enabled: userRole == UserRole.admin,
),
```

---

## 📊 Data Visibility Rules

### **Enquiry Fields Visibility**

| Field | Staff | Admin | Implementation |
|-------|-------|-------|----------------|
| **Customer Info** | ✅ | ✅ | Name, phone, email, location |
| **Event Details** | ✅ | ✅ | Type, date, priority, status |
| **Assignment** | ✅ Own only | ✅ All | Staff sees if assigned to them |
| **Financial Data** | ❌ | ✅ | Total cost, advance paid, payment status |
| **Audit Trail** | ✅ | ✅ | Change history for assigned/all |
| **System Metadata** | ✅ | ✅ | Created/updated timestamps |

### **Export Data Restrictions**

#### **Staff Export (Assigned Only)**
```csv
id,customerName,eventDate,eventType,status,priority,assignedTo,notes
```

#### **Admin Export (Full Access)**
```csv
id,customerName,eventDate,eventType,status,priority,assignedTo,notes,totalCost,advancePaid,paymentStatus,createdBy,createdAt,updatedAt
```

---

## 🚀 Future Enhancements

### **Planned Features**
- 🔜 **Granular Permissions**: Field-level access control
- 🔜 **Department Roles**: Team lead, specialist roles
- 🔜 **Approval Workflows**: Multi-step enquiry approval
- 🔜 **Advanced Analytics**: Role-based analytics views
- 🔜 **Audit Dashboard**: Comprehensive change tracking UI

### **Security Enhancements**
- 🔜 **Session Management**: Advanced session controls
- 🔜 **IP Restrictions**: Location-based access controls
- 🔜 **MFA Support**: Multi-factor authentication
- 🔜 **Data Encryption**: Field-level encryption for sensitive data

---

## 📝 Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| **Role-based UI** | ✅ Implemented | Conditional rendering based on role |
| **Firestore Rules** | ✅ Implemented | Enforced at database level |
| **Authentication** | ✅ Implemented | Firebase Auth with custom claims |
| **Audit Logging** | ✅ Implemented | Change history tracking |
| **CSV Export** | ✅ Implemented | Role-based data filtering |
| **Runtime Guards** | 🔄 In Progress | Adding comprehensive role guards |

---

*Last Updated: September 21, 2024*  
*Version: v1.0.1+10*
