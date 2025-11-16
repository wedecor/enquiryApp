import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/enquiry_repository.dart';
import '../../domain/enquiry.dart';

class StatusInlineControl extends ConsumerWidget {
  const StatusInlineControl({super.key, required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final repo = ref.watch(enquiryRepositoryProvider);

    final role = roleAsync.valueOrNull ?? UserRole.staff;
    final isAdmin = role == UserRole.admin;
    final isStaff = role == UserRole.staff;
    final meUid = currentUser.valueOrNull?.uid;
    final isAssignee = enquiry.assignedTo == meUid;
    final canChange = isAdmin || (isStaff && isAssignee);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          key: const Key('statusDropdown'),
          value: enquiry.status,
          items: const <String>[
            'new',
            'contacted',
            'quoted',
            'confirmed',
            'in_talks',
            'completed',
            'cancelled',
            'not_interested',
          ].map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
          onChanged: canChange
              ? (next) async {
                  if (next == null || next == enquiry.status) return;
                  await repo.updateStatus(id: enquiry.id, nextStatus: next, userId: meUid ?? '');
                }
              : null,
        ),
        if (isStaff && !isAssignee)
          Text(
            'Only the assigned user can change status',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
