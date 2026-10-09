# 🔐 Firestore Security Rules & Schema Verification

## 📋 Overview

This document covers the comprehensive Firestore security rules implementation and automated schema verification system for the We Decor Enquiries application.

## 🛡️ Security Rules Architecture

### **Core Security Principles**

1. **Authentication Required**: All operations require valid authentication
2. **Role-Based Access Control**: Different permissions for admin and staff users
3. **Data Validation**: Schema validation at the rules level
4. **Audit Trail**: Immutable history tracking
5. **Least Privilege**: Users can only access data they need

### **Helper Functions**

#### **Authentication Functions**
```javascript
// Check if user is authenticated
function isAuthenticated() {
  return request.auth != null;
}

// Check if user is admin
function isAdmin() {
  return isAuthenticated() && 
         exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

// Check if user is staff
function isStaff() {
  return isAuthenticated() && 
         exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'staff';
}
```

#### **Schema Validation Functions**
```javascript
// Validate user document schema
function validateUserSchema(data) {
  return data.keys().hasAll(['name', 'email', 'phone', 'role']) &&
         data.name is string && data.name.size() > 0 &&
         data.email is string && data.email.matches('^[^@]+@[^@]+\\.[^@]+$') &&
         data.phone is string && data.phone.size() > 0 &&
         data.role in ['admin', 'staff'] &&
         (data.fcmToken == null || data.fcmToken is string);
}

// Validate enquiry document schema
function validateEnquirySchema(data) {
  return data.keys().hasAll(['customerName', 'customerPhone', 'location', 'eventDate', 'eventType', 'eventStatus', 'notes', 'referenceImages', 'createdBy', 'createdAt']) &&
         data.customerName is string && data.customerName.size() > 0 &&
         data.customerPhone is string && data.customerPhone.size() > 0 &&
         data.location is string && data.location.size() > 0 &&
         data.eventDate is timestamp &&
         data.eventType is string && data.eventType.size() > 0 &&
         data.eventStatus is string && data.eventStatus.size() > 0 &&
         data.notes is string &&
         data.referenceImages is list &&
         data.createdBy is string && data.createdBy.size() > 0 &&
         data.createdAt is timestamp &&
         (data.assignedTo == null || data.assignedTo is string);
}
```

### **Collection-Specific Rules**

#### **Users Collection**
```javascript
match /users/{userId} {
  allow read: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
  allow create: if isAuthenticated() && request.auth.uid == userId && validateUserSchema(resource.data);
  allow update: if isAuthenticated() && request.auth.uid == userId && validateUserSchema(resource.data);
  allow delete: if isAdmin();
}
```

**Permissions:**
- **Read**: Own data or admin access
- **Create**: Self-registration with schema validation
- **Update**: Own data with schema validation
- **Delete**: Admin only

#### **Enquiries Collection**
```javascript
match /enquiries/{enquiryId} {
  allow read: if isAuthenticated() && canAccessEnquiry(resource.data);
  allow create: if isAuthenticated() && validateEnquirySchema(resource.data);
  allow update: if isAuthenticated() && canModifyEnquiry(resource.data) && validateEnquirySchema(resource.data);
  allow delete: if isAdmin();
}
```

**Permissions:**
- **Read**: Assigned staff, creator, or admin
- **Create**: Any authenticated user with schema validation
- **Update**: Assigned staff, creator, or admin with schema validation
- **Delete**: Admin only

#### **Financial Subcollection**
```javascript
match /financial/{docId} {
  allow read: if isAuthenticated() && canAccessEnquiry(get(/databases/$(database)/documents/enquiries/$(enquiryId)).data);
  allow write: if isAuthenticated() && canModifyEnquiry(get(/databases/$(database)/documents/enquiries/$(enquiryId)).data) && validateFinancialSchema(resource.data);
}
```

**Permissions:**
- **Read/Write**: Assigned staff or admin with schema validation

#### **History Subcollection**
```javascript
match /history/{docId} {
  allow read: if isAuthenticated() && canAccessEnquiry(get(/databases/$(database)/documents/enquiries/$(enquiryId)).data);
  allow create: if isAuthenticated() && canModifyEnquiry(get(/databases/$(database)/documents/enquiries/$(enquiryId)).data) && validateHistorySchema(resource.data);
  allow update: if false; // History should be immutable
  allow delete: if false; // History should be immutable
}
```

**Permissions:**
- **Read**: Assigned staff, creator, or admin
- **Create**: Assigned staff, creator, or admin with schema validation
- **Update/Delete**: Disabled (immutable audit trail)

#### **Dropdowns Collection**
```javascript
match /dropdowns/{dropdownType} {
  allow read: if isAuthenticated();
  allow write: if isAdmin();
  
  match /items/{itemId} {
    allow read: if isAuthenticated();
    allow create: if isAdmin() && validateDropdownSchema(resource.data);
    allow update: if isAdmin() && validateDropdownSchema(resource.data);
    allow delete: if isAdmin();
  }
}
```

**Permissions:**
- **Read**: Any authenticated user
- **Write**: Admin only with schema validation

## 🔍 Schema Verification System

### **Automated Verification Service**

The `SchemaVerificationService` provides comprehensive schema validation:

#### **Features**
- **Multi-collection verification**: Users, Enquiries, Dropdowns, Financial, History
- **Detailed error reporting**: Field-level validation errors
- **Performance metrics**: Verification timing and document counts
- **Export capabilities**: Generate detailed reports

#### **Validation Rules**

**User Document Validation:**
- Required fields: `name`, `email`, `phone`, `role`
- Email format validation
- Role validation (`admin` or `staff`)
- Optional `fcmToken` field

**Enquiry Document Validation:**
- Required fields: `customerName`, `customerPhone`, `location`, `eventDate`, `eventType`, `eventStatus`, `notes`, `referenceImages`, `createdBy`, `createdAt`
- Field type validation (string, timestamp, list)
- Non-empty string validation
- Optional `assignedTo` field

**Financial Document Validation:**
- Required fields: `totalCost`, `advancePaid`, `paymentStatus`
- Numeric validation for costs (non-negative)
- String validation for payment status

**History Document Validation:**
- Required fields: `fieldChanged`, `oldValue`, `newValue`, `changedBy`, `timestamp`
- String validation for all fields
- Timestamp validation

### **Usage Examples**

#### **Run Full Schema Verification**
```bash
dart run scripts/verify_schema.dart
```

#### **Quick Verification**
```bash
dart run scripts/verify_schema.dart quick
```

#### **Generate Report**
```bash
dart run scripts/verify_schema.dart report schema_report.txt
```

## 📦 Data Export/Import System

### **Firebase Data Manager**

The `FirebaseDataManager` provides comprehensive data backup and restore capabilities:

#### **Export Features**
- **Complete data export**: All collections and subcollections
- **Schema verification**: Include validation reports
- **JSON format**: Human-readable export format
- **Timestamp handling**: Proper Firestore timestamp conversion

#### **Import Features**
- **Data restoration**: Complete data import from backup
- **Subcollection support**: Financial and history data
- **Error handling**: Graceful failure handling
- **Progress reporting**: Import status updates

### **Usage Examples**

#### **Export All Data**
```bash
dart run scripts/firebase_data_manager.dart export
dart run scripts/firebase_data_manager.dart export ./my_backup
```

#### **Import Data**
```bash
dart run scripts/firebase_data_manager.dart import ./my_backup
```

## 🚀 Deployment

### **Deploy Security Rules**
```bash
firebase deploy --only firestore:rules
```

### **Deploy Indexes**
```bash
firebase deploy --only firestore:indexes
```

### **Verify Deployment**
```bash
# Check rules deployment
firebase firestore:rules:get

# Check indexes status
firebase firestore:indexes
```

## 🔧 Testing

### **Local Testing with Emulator**
```bash
# Start emulator
firebase emulators:start

# Run schema verification
dart run scripts/verify_schema.dart

# Export/import data
dart run scripts/firebase_data_manager.dart export
```

### **Production Testing**
```bash
# Deploy rules
firebase deploy --only firestore:rules

# Verify schema
dart run scripts/verify_schema.dart

# Test data operations
dart run scripts/test_database.dart
```

## 📊 Monitoring

### **Security Rules Monitoring**
- Monitor rule evaluation in Firebase Console
- Check for permission denied errors
- Review rule performance metrics

### **Schema Compliance Monitoring**
- Regular schema verification runs
- Automated error reporting
- Data quality metrics

## 🛠️ Troubleshooting

### **Common Issues**

#### **Permission Denied Errors**
- Verify user authentication status
- Check user role assignments
- Review rule logic for specific collections

#### **Schema Validation Failures**
- Check required field presence
- Verify field data types
- Review field value constraints

#### **Import/Export Issues**
- Verify file permissions
- Check JSON format validity
- Review timestamp conversion

### **Debug Commands**
```bash
# Test security rules
firebase firestore:rules:test

# Verify schema
dart run scripts/verify_schema.dart quick

# Check data integrity
dart run scripts/test_database.dart
```

## 📚 Related Files

- `firestore.rules` - Security rules configuration
- `lib/core/services/schema_verification_service.dart` - Schema verification service
- `scripts/verify_schema.dart` - Schema verification script
- `scripts/firebase_data_manager.dart` - Data export/import script
- `firestore.indexes.json` - Database indexes configuration

## 🔄 Version History

- **v1.0**: Initial security rules implementation
- **v1.1**: Added schema validation functions
- **v1.2**: Enhanced helper functions and permissions
- **v1.3**: Added automated schema verification system
- **v1.4**: Added data export/import capabilities 