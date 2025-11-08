import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart';
import '../../data/enquiry_repository.dart';
import '../../domain/enquiry.dart';

class StatusInlineControl extends ConsumerWidget {
  const StatusInlineControl({super.key, required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final meUid = ref.watch(currentUserUidProvider);
    final repo = ref.watch(enquiryRepositoryProvider);

    final isAdmin = role == 'admin';
    final isStaff = role == 'staff';
    final isAssignee = enquiry.assignedTo == meUid;
    final canChange = isAdmin || (isStaff && isAssignee);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          key: const Key('statusDropdown'),
          value: enquiry.status,
          items:
              const <String>[
                    'new',
                    'contacted',
                    'quoted',
                    'confirmed',
                    'in_talks',
                    'completed',
                    'cancelled',
                    'not_interested',
                  ]
                  .map(
                    (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                  )
                  .toList(),
          onChanged: canChange
              ? (next) async {
                  if (next == null || next == enquiry.status) return;
                  await repo.updateStatus(
                    id: enquiry.id,
                    nextStatus: next,
                    userId: meUid ?? '',
                  );
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
