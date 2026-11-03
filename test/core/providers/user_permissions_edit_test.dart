import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';

void main() {
  const staff = UserPermissions(
    canViewEnquiries: true,
    canCreateEnquiries: false,
    canEditEnquiries: true,
    canDeleteEnquiries: false,
    canViewAnalytics: false,
    canManageUsers: false,
  );
  const admin = UserPermissions(
    canViewEnquiries: true,
    canCreateEnquiries: true,
    canEditEnquiries: true,
    canDeleteEnquiries: true,
    canViewAnalytics: true,
    canManageUsers: true,
    canEditAllEnquiries: true,
    canOpenEditForm: true,
  );

  test('staff may update status / functions only on enquiries assigned to them', () {
    expect(staff.canEditEnquiry(assignedTo: 'staff1', currentUid: 'staff1'), isTrue);
    expect(staff.canEditEnquiry(assignedTo: 'staff2', currentUid: 'staff1'), isFalse);
    expect(staff.canEditEnquiry(assignedTo: null, currentUid: 'staff1'), isFalse);
    expect(staff.canOpenEditForm, isFalse, reason: 'full edit form stays admin-only');
  });

  test('admins may update any enquiry and open the full form', () {
    expect(admin.canEditEnquiry(assignedTo: 'staff2', currentUid: 'admin1'), isTrue);
    expect(admin.canEditEnquiry(assignedTo: null, currentUid: 'admin1'), isTrue);
    expect(admin.canOpenEditForm, isTrue);
  });
}
