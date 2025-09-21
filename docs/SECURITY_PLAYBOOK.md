# Security Playbook - We Decor Enquiries

## 🛡️ RBAC Security Model & Threat Mitigation

This playbook outlines the security model, threat landscape, and mitigation strategies for the We Decor Enquiries application's Role-Based Access Control (RBAC) system.

---

## 🎯 Security Objectives

### **Primary Goals**
- **Data Confidentiality**: Protect customer PII and financial information
- **Access Control**: Ensure users can only access data appropriate to their role
- **Audit Trail**: Maintain comprehensive logs of all administrative actions
- **Defense in Depth**: Multiple layers of security (UI + Service + Database)

### **Compliance Requirements**
- **Data Protection**: Customer email and financial data restricted to admins
- **Audit Logging**: All admin actions logged with timestamps and user context
- **Least Privilege**: Staff users have minimal necessary permissions
- **Secure Export**: CSV exports respect role-based data restrictions

---

## ⚠️ Threat Model

### **🎭 Threat Actors**

#### **1. Insider Threats - Staff Role Escalation**
- **Threat**: Staff user attempts to gain admin privileges
- **Impact**: Access to all customer data, financial information, user management
- **Likelihood**: Medium
- **Mitigation**: Multi-layer role validation, immutable role assignment

#### **2. Data Exfiltration - Unauthorized Export**
- **Threat**: Staff user exports data beyond their assigned enquiries
- **Impact**: Customer PII and financial data breach
- **Likelihood**: High
- **Mitigation**: Role-based CSV filtering, audit logging, file access controls

#### **3. Privilege Abuse - Admin Account Compromise**
- **Threat**: Compromised admin account used for unauthorized actions
- **Impact**: Complete system compromise, data manipulation
- **Likelihood**: Low
- **Mitigation**: Admin action audit logging, session monitoring, MFA (planned)

#### **4. UI Bypass - Direct API Access**
- **Threat**: Bypassing UI restrictions via direct Firestore access
- **Impact**: Unauthorized data access and modification
- **Likelihood**: Medium
- **Mitigation**: Firestore security rules, service-layer validation

---

## 🛡️ Security Controls & Mitigations

### **Layer 1: UI Gating (Presentation Layer)**

#### **Implementation**
```dart
// Example: Conditional UI rendering based on role
if (isAdmin(ref)) ...[ 
  IconButton(
    icon: Icon(Icons.delete),
    onPressed: () => deleteEnquiry(enquiryId),
    tooltip: 'Delete Enquiry',
  ),
] else ...[
  // Staff users don't see delete button
],
```

#### **Controls**
- **Admin-only UI elements**: Hidden from staff users
- **Role-based navigation**: Different menu items per role
- **Conditional actions**: Delete, assign, financial fields
- **Export scope indicators**: "Assigned Only" vs "All Data"

#### **Limitations**
- **Client-side only**: Can be bypassed with developer tools
- **Not cryptographically secure**: Relies on proper implementation
- **UI bugs**: May accidentally expose admin features

### **Layer 2: Service/Provider Gating (Business Logic)**

#### **Implementation**
```dart
// Example: Service-layer role validation
Future<void> deleteEnquiry(String enquiryId, WidgetRef ref) async {
  requireAdmin(ref); // Throws if not admin
  await logAdminAction(ref, 'enquiry_deleted', {'enquiryId': enquiryId});
  
  // Proceed with deletion
  await firestoreService.deleteEnquiry(enquiryId);
}
```

#### **Controls**
- **`requireAdmin(ref)`**: Throws StateError if user lacks admin role
- **`canEditEnquiry(ref, assigneeId)`**: Validates enquiry access permissions
- **`logAdminAction(ref, action, data)`**: Audit trail for admin operations
- **Export filtering**: Role-based data filtering before CSV generation

#### **Audit Actions Logged**
- User role changes
- Enquiry assignments
- Data exports (with scope)
- User account modifications
- System configuration changes

### **Layer 3: Database Rules (Firestore Security)**

#### **Implementation**
```javascript
// Firestore Rules Example
match /enquiries/{id} {
  allow read: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
  allow create, delete: if isAdmin();
  allow update: if isAdmin() 
    || (isSignedIn() && resource.data.assignedTo == request.auth.uid);
}
```

#### **Controls**
- **Read access**: Staff only see assigned enquiries
- **Write access**: Staff can update assigned enquiries only
- **Admin privileges**: Full CRUD access to all data
- **Audit collection**: Admin-only read access, system write access

---

## 🔍 Security Review Checklist

### **For New Admin-Only Features**

#### **✅ UI Layer Checklist**
- [ ] Admin-only UI elements wrapped in `if (isAdmin(ref))` checks
- [ ] Staff users see appropriate alternative UI or disabled state
- [ ] Tooltips/help text indicate permission requirements
- [ ] Navigation guards prevent unauthorized route access

#### **✅ Service Layer Checklist**
- [ ] Entry point calls `requireAdmin(ref)` before proceeding
- [ ] Admin action logged via `logAdminAction(ref, 'action_name', data)`
- [ ] Proper error handling for permission denied scenarios
- [ ] Data filtering applied based on user role

#### **✅ Database Layer Checklist**
- [ ] Firestore rules updated to restrict access appropriately
- [ ] Rules tested with emulator and multiple user contexts
- [ ] Audit trail collection properly secured
- [ ] No data leakage through compound queries or aggregations

#### **✅ Testing Checklist**
- [ ] Unit tests cover role validation logic
- [ ] Integration tests verify UI restrictions
- [ ] Firestore rules tests validate database security
- [ ] CSV export tests confirm data filtering

### **For New Data Fields**

#### **✅ Data Classification**
- [ ] Field classified as: Public, Staff-Only, Admin-Only, or Financial
- [ ] Appropriate access controls implemented in all layers
- [ ] CSV export logic updated to respect field classification
- [ ] Documentation updated with field access matrix

#### **✅ PII & Financial Data**
- [ ] Customer email addresses restricted to admin-only
- [ ] Financial fields (cost, payments) hidden from staff
- [ ] Audit logging includes data access patterns
- [ ] Export filenames indicate data scope and sensitivity

---

## 🚨 Incident Response

### **Security Incident Categories**

#### **🔴 Critical - Data Breach**
- **Examples**: Unauthorized access to customer financial data, PII exposure
- **Response Time**: Immediate (< 1 hour)
- **Actions**: Disable affected accounts, audit access logs, notify stakeholders

#### **🟡 High - Privilege Escalation**
- **Examples**: Staff user gains admin access, role bypass detected
- **Response Time**: < 4 hours
- **Actions**: Reset user roles, review audit logs, patch vulnerability

#### **🟢 Medium - Access Control Bypass**
- **Examples**: UI restrictions bypassed, unauthorized export attempts
- **Response Time**: < 24 hours
- **Actions**: Review logs, strengthen controls, user education

### **Investigation Procedures**

#### **1. Audit Log Analysis**
```bash
# Query admin_audit collection for suspicious activity
# Look for: unusual role changes, bulk exports, off-hours access
```

#### **2. User Access Review**
```bash
# Review user collection for unauthorized role changes
# Verify assignedTo fields haven't been manipulated
```

#### **3. Export Activity Monitoring**
```bash
# Check for unusual export patterns
# Verify export scope matches user permissions
```

---

## 📊 Security Metrics & Monitoring

### **Key Performance Indicators (KPIs)**

#### **Access Control Effectiveness**
- **Role Validation Success Rate**: > 99.9%
- **Unauthorized Access Attempts**: < 5 per month
- **Admin Action Audit Coverage**: 100%

#### **Data Protection Metrics**
- **PII Exposure Incidents**: 0 per month
- **Financial Data Leaks**: 0 per month
- **Unauthorized Exports**: < 2 per month

#### **System Security Health**
- **Firestore Rules Test Coverage**: > 95%
- **RBAC Unit Test Coverage**: > 90%
- **Security Code Review Coverage**: 100% of admin features

### **Monitoring Alerts**

#### **🚨 Immediate Alerts**
- Multiple failed admin access attempts (> 3 in 1 hour)
- Large CSV export by staff user (> 100 records)
- Admin role assignment outside business hours
- Direct Firestore rule violations

#### **📊 Daily Reports**
- Admin actions summary
- Export activity by user and scope
- Failed permission checks
- New user registrations and role assignments

---

## 🔧 Security Maintenance

### **Regular Security Tasks**

#### **Weekly**
- [ ] Review admin audit logs for unusual activity
- [ ] Verify user role assignments are appropriate
- [ ] Check for failed permission attempts

#### **Monthly**
- [ ] Run comprehensive Firestore rules tests
- [ ] Review and update security documentation
- [ ] Analyze export patterns for anomalies
- [ ] Update threat model based on new features

#### **Quarterly**
- [ ] Security code review for all new admin features
- [ ] Penetration testing of RBAC system
- [ ] User access review and cleanup
- [ ] Security training for development team

### **Security Updates**

#### **When to Update Security Controls**
- New admin-only feature added
- New data field with sensitivity classification
- User role structure changes
- Export functionality modifications
- Firestore schema updates

#### **Update Process**
1. **Design Review**: Security implications assessment
2. **Implementation**: All three layers updated
3. **Testing**: Comprehensive security test suite
4. **Documentation**: Playbook and runbook updates
5. **Deployment**: Staged rollout with monitoring

---

## 📞 Emergency Contacts

### **Security Team**
- **Primary**: Development Team Lead
- **Secondary**: Firebase Admin
- **Escalation**: Project Owner

### **Response Procedures**
- **Immediate**: Disable affected accounts
- **Investigation**: Audit log analysis
- **Communication**: Stakeholder notification
- **Recovery**: System restoration and hardening

---

## 📚 Related Documentation

- **[RBAC Quick Reference](RBAC_QUICKREF.md)** - Implementation patterns and guidelines
- **[RBAC Runbook](RUNBOOK_RBAC.md)** - Operational procedures and troubleshooting
- **[Feature Matrix](FEATURE_MATRIX.md)** - Complete role capabilities comparison
- **[Firestore Security Rules](../FIRESTORE_SECURITY_RULES.md)** - Database security configuration

---

*Last Updated: September 21, 2024*  
*Next Review: October 21, 2024*
