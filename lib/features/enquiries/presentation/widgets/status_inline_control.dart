import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/enquiry.dart';
import 'enquiry_status_control.dart';

/// Compact status dropdown for list rows — delegates to [EnquiryStatusControl].
class StatusInlineControl extends ConsumerWidget {
  const StatusInlineControl({super.key, required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);
    final currentUser = ref.watch(currentUserWithFirestoreProvider);

    final role = roleAsync.valueOrNull ?? UserRole.staff;
    final isAdmin = role == UserRole.admin;
    final isStaff = role == UserRole.staff;
    final meUid = currentUser.valueOrNull?.uid;
    final isAssignee = enquiry.assignedTo == meUid;

    return EnquiryStatusControl(
      enquiryId: enquiry.id,
      enquiryData: {'statusValue': enquiry.status, 'assignedTo': enquiry.assignedTo},
      currentStatusValue: enquiry.status,
      currentStatusLabel: enquiry.statusDisplay,
      isAdmin: isAdmin,
      isAssignee: isStaff ? isAssignee : true,
    );
  }
}
