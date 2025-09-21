# RBAC Operations Runbook

## 🔧 Operational Procedures for Role-Based Access Control

This runbook provides step-by-step procedures for maintaining, troubleshooting, and extending the RBAC system in We Decor Enquiries.

---

## 🚀 Quick Start Guide

### **Adding a New Admin-Only Action**

Follow this checklist to properly secure any new admin-only feature:

#### **1. UI Layer Implementation**
```dart
// ✅ Proper admin-only UI gating
if (isAdmin(ref)) ...[ 
  ElevatedButton(
    onPressed: () => _performAdminAction(context),
    child: Text('Admin Action'),
  ),
] else ...[
  // Optional: Show disabled state with tooltip
  Tooltip(
    message: 'Admin access required',
    child: ElevatedButton(
      onPressed: null, // Disabled
      child: Text('Admin Action'),
    ),
  ),
],
```

#### **2. Service Layer Implementation**
```dart
// ✅ Proper service-layer protection
Future<void> performAdminAction(WidgetRef ref, String targetId) async {
  // REQUIRED: Admin role validation
  requireAdmin(ref);
  
  // REQUIRED: Audit logging
  await logAdminAction(ref, 'admin_action_performed', {
    'targetId': targetId,
    'timestamp': DateTime.now().toIso8601String(),
    'actionType': 'admin_operation',
  });
  
  try {
    // Perform the actual operation
    await _doAdminOperation(targetId);
    
    Logger.info('Admin action completed successfully', tag: 'AdminAction');
  } catch (e) {
    Logger.error('Admin action failed', tag: 'AdminAction');
    rethrow;
  }
}
```

#### **3. Database Rules Update**
```javascript
// ✅ Firestore rules for new admin-only collection
match /admin_only_collection/{docId} {
  allow read, write: if isAdmin();
}

// ✅ Audit rule for new action type
match /admin_audit/{auditId} {
  allow read: if isAdmin();
  allow create: if isSignedIn(); // For audit logging
}
```

#### **4. Testing Requirements**
```dart
// ✅ Unit test for role validation
test('requireAdmin throws for non-admin users', () {
  final staffContainer = ProviderContainer(
    overrides: [currentUserRoleProvider.overrideWith((ref) => 'staff')],
  );
  
  expect(
    () => requireAdmin(MockWidgetRef(staffContainer)),
    throwsA(isA<StateError>()),
  );
});

// ✅ Integration test for UI restrictions
testWidgets('admin action hidden from staff', (tester) async {
  // Launch as staff user
  await _launchAsStaff(tester);
  
  // Verify admin button is not visible
  expect(find.text('Admin Action'), findsNothing);
});
```

---

## 📊 Adding New CSV Export Columns

### **Column Classification Process**

#### **1. Classify Data Sensitivity**
```dart
// Data sensitivity levels
enum DataSensitivity {
  public,      // Customer name, event type, status
  staff,       // Phone numbers, event details, notes
  adminOnly,   // Email addresses, financial data
  financial,   // Costs, payments, budget information
}
```

#### **2. Update CSV Export Logic**
```dart
// ✅ Role-based column filtering
List<String> getExportColumns(WidgetRef ref) {
  final baseColumns = [
    'ID', 'Customer Name', 'Event Type', 'Status', 'Created At'
  ];
  
  if (isAdmin(ref)) {
    return [
      ...baseColumns,
      'Customer Email',    // PII - admin only
      'Total Cost',        // Financial - admin only
      'Payment Status',    // Financial - admin only
      'Budget Range',      // Financial - admin only
    ];
  } else {
    return [
      ...baseColumns,
      'Customer Phone',    // Staff can see phone
      'Event Location',    // Staff can see location
      'Staff Notes',       // Staff can see their notes
    ];
  }
}
```

#### **3. Update Documentation**
```markdown
# Update FEATURE_MATRIX.md
| New Field | Staff | Admin | Classification |
|-----------|-------|-------|----------------|
| newField  | ❌/✅  | ✅    | public/staff/adminOnly/financial |
```

#### **4. Add Tests**
```dart
test('new column respects role restrictions', () {
  // Test staff export excludes new sensitive field
  // Test admin export includes new field
});
```

---

## 🔍 Troubleshooting Guide

### **Common Issues & Solutions**

#### **🚨 "Access Denied" Errors**

**Symptoms**: User gets StateError with "Admin access required" message

**Diagnosis Steps**:
1. Check user's actual role in Firestore users collection
2. Verify role provider is returning correct value
3. Check if requireAdmin() is being called correctly
4. Review recent role changes in audit logs

**Solutions**:
```bash
# Check user role in Firestore
firebase firestore:get users/USER_ID

# Check audit logs for role changes
firebase firestore:query admin_audit --where userId==USER_ID

# Fix role assignment (admin only)
firebase firestore:set users/USER_ID '{"role": "staff", "updatedAt": "2024-09-21T10:00:00Z"}'
```

#### **🚨 CSV Export Issues**

**Symptoms**: Staff user exports contain financial data or unassigned enquiries

**Diagnosis Steps**:
1. Check if role validation is working in export service
2. Verify filtering logic in CSV export function
3. Review exported file contents and column headers
4. Check audit logs for export activity

**Solutions**:
```dart
// Verify export filtering
final exportedData = await CsvExport.exportEnquiries(enquiries, ref);
// Should automatically filter based on role
```

#### **🚨 Firestore Permission Denied**

**Symptoms**: Firestore operations fail with permission denied errors

**Diagnosis Steps**:
1. Test rules with Firebase emulator
2. Check if user authentication token is valid
3. Verify rule logic matches application expectations
4. Review rule deployment status

**Solutions**:
```bash
# Test rules locally
firebase emulators:start --only firestore
# Run rules tests
cd rules-tests && npm test

# Deploy updated rules
firebase deploy --only firestore:rules
```

#### **🚨 Role Provider Issues**

**Symptoms**: Role checks return incorrect values or null

**Diagnosis Steps**:
1. Check Firebase Auth user state
2. Verify user document exists in Firestore
3. Check if role field is properly set
4. Review provider dependencies and overrides

**Solutions**:
```dart
// Debug role provider
final authUser = ref.read(firebaseAuthUserProvider);
final userDoc = ref.read(currentUserDocProvider);
final userRole = ref.read(currentUserRoleProvider);

print('Auth: $authUser, Doc: $userDoc, Role: $userRole');
```

---

## 🧪 Testing Procedures

### **Manual Security Testing**

#### **Staff User Testing Checklist**
```bash
# 1. Login as staff user
# 2. Verify restricted access
- [ ] Cannot see "User Management" in navigation
- [ ] Cannot see "Analytics" in navigation  
- [ ] Cannot see "Delete" buttons on enquiries
- [ ] Cannot see financial fields in enquiry details
- [ ] CSV export only includes assigned enquiries
- [ ] CSV export excludes financial columns

# 3. Attempt unauthorized actions
- [ ] Try to access /admin routes (should redirect)
- [ ] Try to export all data (should be filtered)
- [ ] Try to modify unassigned enquiries (should fail)
```

#### **Admin User Testing Checklist**
```bash
# 1. Login as admin user
# 2. Verify full access
- [ ] Can see all navigation options
- [ ] Can see all enquiries regardless of assignment
- [ ] Can see financial fields and modify them
- [ ] Can access user management features
- [ ] Can export all data with all columns
- [ ] All admin actions are logged in audit trail

# 3. Verify admin capabilities
- [ ] Can create/edit/delete enquiries
- [ ] Can invite and manage users
- [ ] Can modify system configuration
- [ ] Can access analytics dashboard
```

### **Automated Testing**

#### **Run Full Test Suite**
```bash
# Unit tests
flutter test

# Integration tests  
flutter test integration_test/rbac_smoke_test.dart

# Firestore rules tests
cd rules-tests && npm test

# Coverage analysis
bash tools/coverage_gate.sh
```

#### **CI Pipeline Verification**
```bash
# Trigger CI pipeline
git push origin feature/new-admin-feature

# Monitor CI results
# - Analyzer: 0 errors
# - Tests: All passing
# - Rules tests: All security boundaries validated
# - Coverage: ≥30% on critical components
```

---

## 🔧 Maintenance Procedures

### **Regular Maintenance Tasks**

#### **Weekly Security Review**
```bash
# 1. Review admin audit logs
firebase firestore:query admin_audit --orderBy timestamp --limit 50

# 2. Check for unusual export activity
firebase firestore:query admin_audit --where action==csv_export

# 3. Verify user role assignments
firebase firestore:query users --where role==admin
```

#### **Monthly Security Audit**
```bash
# 1. Run comprehensive rules tests
cd rules-tests && npm test

# 2. Review user access patterns
# Check for: inactive users, role changes, permission denials

# 3. Update security documentation
# Review and update threat model, add new scenarios
```

#### **Quarterly Security Assessment**
```bash
# 1. Full security code review
# Focus on: new admin features, export logic, role validation

# 2. Penetration testing
# Test: UI bypass attempts, API manipulation, role escalation

# 3. Security training update
# Update team on: new threats, best practices, incident response
```

---

## 🛠️ Common Operations

### **User Role Management**

#### **Promote Staff to Admin**
```bash
# 1. Verify user eligibility
firebase firestore:get users/USER_ID

# 2. Update role (requires current admin)
firebase firestore:update users/USER_ID '{"role": "admin", "updatedAt": "TIMESTAMP"}'

# 3. Verify audit log created
firebase firestore:query admin_audit --where targetUserId==USER_ID --orderBy timestamp --limit 1
```

#### **Demote Admin to Staff**
```bash
# 1. Ensure not removing last admin
firebase firestore:query users --where role==admin

# 2. Update role
firebase firestore:update users/USER_ID '{"role": "staff", "updatedAt": "TIMESTAMP"}'

# 3. Review user's assigned enquiries
firebase firestore:query enquiries --where assignedTo==USER_ID
```

### **Security Incident Response**

#### **Immediate Response (< 1 hour)**
```bash
# 1. Disable affected user account
firebase firestore:update users/AFFECTED_USER_ID '{"active": false}'

# 2. Review recent audit logs
firebase firestore:query admin_audit --where adminUserId==AFFECTED_USER_ID --orderBy timestamp

# 3. Check for data exposure
# Review export logs, access patterns, modified documents
```

#### **Investigation (< 4 hours)**
```bash
# 1. Analyze full audit trail
# Look for: unusual patterns, bulk operations, off-hours activity

# 2. Verify system integrity
# Check: user roles, enquiry assignments, configuration changes

# 3. Document findings
# Create incident report with timeline and impact assessment
```

#### **Recovery (< 24 hours)**
```bash
# 1. Patch security vulnerability
# Update: UI guards, service validation, Firestore rules

# 2. Restore affected data
# From: backup, audit trail, known good state

# 3. Strengthen controls
# Add: additional validation, monitoring, alerts
```

---

## 📋 Operational Checklists

### **New Feature Deployment**

#### **Pre-Deployment Security Check**
- [ ] All admin-only features have `requireAdmin()` guards
- [ ] Audit logging implemented for admin actions
- [ ] Firestore rules updated and tested
- [ ] UI properly hides admin features from staff
- [ ] CSV export logic respects new data classifications
- [ ] Integration tests cover new security boundaries
- [ ] Documentation updated with new capabilities

#### **Post-Deployment Verification**
- [ ] Monitor audit logs for new action types
- [ ] Verify role-based access works in production
- [ ] Check export functionality with both user types
- [ ] Confirm no unauthorized access attempts
- [ ] Validate performance impact of new security checks

### **User Onboarding Security**

#### **New Staff User**
- [ ] Create user with 'staff' role
- [ ] Assign to appropriate enquiries
- [ ] Verify limited dashboard access
- [ ] Test CSV export scope
- [ ] Document user access grant

#### **New Admin User**
- [ ] Verify business justification for admin access
- [ ] Create user with 'admin' role
- [ ] Test full system access
- [ ] Add to admin notification lists
- [ ] Document admin access grant and approval

---

## 🔍 Monitoring & Alerting

### **Key Metrics to Monitor**

#### **Security Metrics**
- Failed permission checks per hour
- Admin actions per day by user
- Large export operations (>50 records)
- Off-hours admin activity
- Role change frequency

#### **Performance Metrics**
- Role validation response time
- Export generation time by scope
- Firestore rule evaluation latency
- UI rendering time with role checks

### **Alert Thresholds**

#### **🚨 Critical Alerts**
- **Multiple failed admin access**: >3 attempts in 1 hour
- **Large staff export**: >100 records exported by staff user
- **Off-hours admin activity**: Admin actions between 10 PM - 6 AM
- **Role escalation**: Staff user role changed to admin

#### **⚠️ Warning Alerts**
- **High export volume**: >10 exports per day by single user
- **Frequent permission denials**: >5 denials per hour per user
- **Unusual access patterns**: Access from new devices/locations

---

## 📞 Escalation Procedures

### **Security Incident Escalation Matrix**

| Severity | Response Time | Escalation Path | Actions Required |
|----------|---------------|-----------------|------------------|
| **Critical** | < 1 hour | → Security Team → Management | Immediate containment |
| **High** | < 4 hours | → Development Lead → Security Team | Rapid investigation |
| **Medium** | < 24 hours | → Development Team | Standard investigation |
| **Low** | < 72 hours | → Assigned Developer | Documentation update |

### **Contact Information**

#### **Primary Contacts**
- **Development Lead**: Immediate security issues
- **DevOps Engineer**: Infrastructure and deployment issues
- **Firebase Admin**: Database and rules issues

#### **Escalation Contacts**
- **Security Officer**: Data breach or compliance issues
- **Legal Team**: Privacy violations or regulatory concerns
- **Management**: Business impact or public disclosure

---

## 🛠️ Development Workflows

### **Feature Development with RBAC**

#### **Planning Phase**
1. **Security Design Review**
   - Classify feature as staff/admin/both
   - Identify data sensitivity levels
   - Plan three-layer security implementation

2. **Threat Assessment**
   - What could go wrong if security fails?
   - What data could be exposed?
   - What actions could be abused?

#### **Implementation Phase**
1. **UI Layer**
   - Implement role-based conditional rendering
   - Add appropriate error states and messaging
   - Test with both user roles

2. **Service Layer**
   - Add `requireAdmin()` calls at entry points
   - Implement `logAdminAction()` for audit trail
   - Add comprehensive error handling

3. **Database Layer**
   - Update Firestore security rules
   - Test rules with emulator
   - Verify no data leakage

#### **Testing Phase**
1. **Unit Tests**
   - Test role validation logic
   - Test data filtering functions
   - Test audit logging

2. **Integration Tests**
   - Test UI restrictions with both roles
   - Test end-to-end workflows
   - Test error handling

3. **Security Tests**
   - Test Firestore rules with emulator
   - Test unauthorized access attempts
   - Test data export restrictions

#### **Deployment Phase**
1. **Pre-Deployment**
   - Run full test suite
   - Deploy rules to staging
   - Verify CI pipeline passes

2. **Deployment**
   - Deploy code and rules together
   - Monitor for security alerts
   - Verify functionality with test users

3. **Post-Deployment**
   - Monitor audit logs
   - Check for permission errors
   - Verify performance metrics

---

## 🚨 Emergency Procedures

### **Data Breach Response**

#### **Immediate Actions (0-15 minutes)**
```bash
# 1. Disable affected user accounts
firebase firestore:update users/AFFECTED_USER '{"active": false}'

# 2. Check scope of potential exposure
firebase firestore:query admin_audit --where adminUserId==AFFECTED_USER

# 3. Notify security team
# Send alert with: user ID, timestamp, potential impact
```

#### **Investigation (15 minutes - 1 hour)**
```bash
# 1. Analyze audit trail
firebase firestore:query admin_audit --orderBy timestamp --limit 100

# 2. Check export activity
grep "csv_export" audit_logs.txt

# 3. Verify system integrity
# Check: user roles, enquiry assignments, recent changes
```

#### **Containment (1-4 hours)**
```bash
# 1. Patch security vulnerability
# Update: code, rules, configuration

# 2. Reset affected passwords
# Force password reset for compromised accounts

# 3. Review and strengthen controls
# Add: additional validation, monitoring, alerts
```

### **System Compromise Response**

#### **Detection Indicators**
- Multiple admin accounts created simultaneously
- Bulk data exports outside business hours
- Unusual role escalation patterns
- Failed authentication spikes
- Firestore rule violations

#### **Response Actions**
1. **Immediate**: Disable new admin accounts
2. **Short-term**: Reset all admin passwords
3. **Medium-term**: Review and patch vulnerabilities
4. **Long-term**: Strengthen monitoring and controls

---

## 📚 Reference Information

### **Role Capabilities Quick Reference**

| Action | Staff | Admin | Implementation |
|--------|-------|-------|----------------|
| **View Enquiries** | Assigned only | All | Firestore rules |
| **Edit Enquiries** | Assigned only | All | UI + Service + Rules |
| **Delete Enquiries** | ❌ | ✅ | UI + Service + Rules |
| **Create Enquiries** | ❌ | ✅ | UI + Service + Rules |
| **User Management** | ❌ | ✅ | UI + Service + Rules |
| **Analytics Access** | ❌ | ✅ | UI + Service |
| **System Config** | ❌ | ✅ | UI + Service + Rules |
| **CSV Export** | Assigned + Limited | All + Full | Service logic |

### **Security Rule Functions**

```javascript
// Helper functions available in firestore.rules
function isSignedIn() { return request.auth != null; }
function isAdmin() { return isSignedIn() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'; }
function isOwner(uid) { return isSignedIn() && request.auth.uid == uid; }
```

### **Critical File Locations**

| Component | File Path | Purpose |
|-----------|-----------|---------|
| **Role Guards** | `lib/core/auth/role_guards.dart` | Runtime permission checking |
| **CSV Export** | `lib/core/export/csv_export.dart` | Role-based data export |
| **Audit Service** | `lib/core/services/audit_service.dart` | Admin action logging |
| **Firestore Rules** | `firestore.rules` | Database security |
| **User Model** | `lib/shared/models/user_model.dart` | User data structure |

---

## 📞 Emergency Contacts & Procedures

### **Security Incident Hotline**
- **Primary**: Development Team Lead
- **Backup**: Firebase Administrator
- **Escalation**: Project Owner

### **After-Hours Response**
- **Severity 1**: Immediate response required
- **Severity 2**: Next business day response
- **Severity 3**: Weekly review cycle

---

*Last Updated: September 21, 2024*  
*Next Review: October 21, 2024*  
*Version: 1.0.0*
