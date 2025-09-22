import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart';
import '../../data/enquiry_repository.dart';
import '../../domain/enquiry.dart';

class StatusInlineControl extends ConsumerWidget {
  const StatusInlineControl({super.key, required this.enquiry});

  final Enquiry enquiry;

  static const Map<String, List<String>> _allowedTransitions = {
    'new': ['contacted', 'cancelled'],
    'contacted': ['quoted', 'cancelled'],
    'quoted': ['confirmed', 'cancelled'],
    'confirmed': ['in_progress', 'cancelled'],
    'in_progress': ['completed', 'cancelled'],
    'completed': [],
    'cancelled': [],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final meUid = ref.watch(currentUserUidProvider);
    final repo = ref.watch(enquiryRepositoryProvider);

    final isAdmin = role == 'admin';
    final isStaff = role == 'staff';
    final isAssignee = enquiry.assignedTo == meUid;
    final canChange = isAdmin || (isStaff && isAssignee);

    final current = enquiry.status;
    final options = <String>{
      current,
      ...(_allowedTransitions[current] ?? const <String>[]),
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          key: const Key('statusDropdown'),
          value: current,
          items: options.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
          onChanged: canChange
              ? (next) async {
                  if (next == null || next == current) return;
                  final prev = current;
                  final uid = meUid ?? '';
                  await repo.updateStatus(
                    id: enquiry.id,
                    nextStatus: next,
                    userId: uid,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status changed to $next'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            await repo.updateStatus(
                              id: enquiry.id,
                              nextStatus: prev,
                              userId: uid,
                            );
                          },
                        ),
                      ),
                    );
                  }
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
