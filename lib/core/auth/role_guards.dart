import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/logger.dart';
import '../providers/audit_provider.dart';
import '../providers/role_provider.dart';
import '../../shared/models/user_model.dart';

/// Provides boolean value indicating if current user is an admin
/// Uses the standardized isAdminProvider from role_provider.dart
final isAdminValueProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider);
});

/// Provides boolean value indicating if current user is staff
final isStaffValueProvider = Provider<bool>((ref) {
  return ref.watch(isStaffProvider);
});

/// Check if current user has admin role
bool isAdmin(WidgetRef ref) => ref.read(isAdminValueProvider);

/// Check if current user has staff role
bool isStaff(WidgetRef ref) => ref.read(isStaffValueProvider);

/// Require admin role - throws StateError if not admin
void requireAdmin(WidgetRef ref) {
  final adminStatus = ref.read(isAdminValueProvider);
  final roleAsync = ref.read(roleProvider);
  final currentRole = roleAsync.valueOrNull ?? UserRole.staff;

  Logger.info('Role check: requireAdmin called', tag: 'RoleGuards');

  if (!adminStatus) {
    Logger.error('Admin-only action attempted by non-admin', tag: 'RoleGuards');
    throw StateError('Admin access required. Current role: $currentRole');
  }
}

/// Check if current user can edit a specific enquiry
/// Returns true if user is admin OR if user is staff assigned to the enquiry
bool canEditEnquiry(WidgetRef ref, {required String? assigneeId}) {
  // Admins can edit any enquiry
  if (isAdmin(ref)) {
    Logger.debug('Admin can edit any enquiry', tag: 'RoleGuards');
    return true;
  }

  // Staff can only edit enquiries assigned to them
  final currentUser = ref.read(currentUserWithFirestoreProvider);
  final currentUserId = currentUser.valueOrNull?.uid;
  final canEdit = currentUserId != null && assigneeId == currentUserId;

  Logger.debug('Staff enquiry edit check', tag: 'RoleGuards');

  return canEdit;
}

/// Check if current user can view financial data
bool canViewFinancialData(WidgetRef ref) {
  final adminStatus = isAdmin(ref);
  Logger.debug('Financial data access check', tag: 'RoleGuards');
  return adminStatus;
}

/// Check if current user can manage other users
bool canManageUsers(WidgetRef ref) {
  final adminStatus = isAdmin(ref);
  Logger.debug('User management access check', tag: 'RoleGuards');
  return adminStatus;
}

/// Check if current user can access analytics
bool canAccessAnalytics(WidgetRef ref) {
  final adminStatus = isAdmin(ref);
  Logger.debug('Analytics access check', tag: 'RoleGuards');
  return adminStatus;
}

/// Check if current user can configure system settings
bool canConfigureSystem(WidgetRef ref) {
  final adminStatus = isAdmin(ref);
  Logger.debug('System configuration access check', tag: 'RoleGuards');
  return adminStatus;
}

/// Helper to log admin actions for audit trail
Future<void> logAdminAction(WidgetRef ref, String action, Map<String, Object?> data) async {
  try {
    final currentUser = ref.read(currentUserWithFirestoreProvider);
    final userId = currentUser.valueOrNull?.uid;
    final userEmail = currentUser.valueOrNull?.email;

    final auditData = {
      'action': action,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': DateTime.now().toIso8601String(),
      'isAdmin': isAdmin(ref),
      ...data,
    };

    Logger.info('Admin action logged', tag: 'AdminAudit');

    // Also log to audit service if available
    final auditService = ref.read(auditServiceProvider);
    await auditService.logAdminAction(action, auditData);
  } catch (e) {
    Logger.error('Failed to log admin action', tag: 'AdminAudit');
  }
}

/// Helper to validate and log enquiry access
bool validateEnquiryAccess(
  WidgetRef ref, {
  required String enquiryId,
  required String? assigneeId,
  required String operation,
}) {
  final canAccess = isAdmin(ref) || canEditEnquiry(ref, assigneeId: assigneeId);

  Logger.info('Enquiry access validation', tag: 'RoleGuards');

  return canAccess;
}

/// Helper to get user-friendly role display name
String getRoleDisplayName(WidgetRef ref) {
  final roleAsync = ref.read(roleProvider);
  final role = roleAsync.valueOrNull ?? UserRole.staff;
  switch (role) {
    case UserRole.admin:
      return 'Administrator';
    case UserRole.staff:
      return 'Staff Member';
    default:
      return 'Unknown Role';
  }
}

/// Helper to get role-appropriate dashboard title
String getDashboardTitle(WidgetRef ref) {
  return isAdmin(ref) ? 'Admin Dashboard' : 'My Enquiries';
}

/// Helper to get role-appropriate enquiries list title
String getEnquiriesListTitle(WidgetRef ref) {
  return isAdmin(ref) ? 'All Enquiries' : 'My Assigned Enquiries';
}
