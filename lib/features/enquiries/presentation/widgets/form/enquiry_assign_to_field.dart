import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logging/logger.dart';
import '../../../../../core/services/firestore_service.dart';
import '../../../../../core/theme/tokens.dart';
import '../enquiry_form_section.dart';

/// Assignee picker showing active users; retains inactive current assignee as disabled.
class EnquiryAssignToField extends ConsumerStatefulWidget {
  const EnquiryAssignToField({
    super.key,
    required this.selectedAssignedTo,
    required this.onAssignedToChanged,
  });

  final String? selectedAssignedTo;
  final ValueChanged<String?> onAssignedToChanged;

  @override
  ConsumerState<EnquiryAssignToField> createState() => _EnquiryAssignToFieldState();
}

class _EnquiryAssignToFieldState extends ConsumerState<EnquiryAssignToField> {
  String? _inactiveAssigneeLabel;
  String? _loadingInactiveUid;

  @override
  void didUpdateWidget(EnquiryAssignToField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAssignedTo != widget.selectedAssignedTo) {
      _inactiveAssigneeLabel = null;
      _loadingInactiveUid = null;
    }
  }

  Future<void> _loadInactiveLabel(String uid) async {
    if (_loadingInactiveUid == uid) return;
    _loadingInactiveUid = uid;

    try {
      final data = await ref.read(firestoreServiceProvider).getUser(uid);
      final name = (data?['name'] as String?)?.trim();
      final email = (data?['email'] as String?)?.trim();
      final display = name ?? email ?? uid;
      if (mounted) {
        setState(() => _inactiveAssigneeLabel = '$display (inactive)');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _inactiveAssigneeLabel = '$uid (inactive)');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = ref.watch(activeUsersProvider);

    return activeUsers.when(
      data: (users) {
        final activeIds = users.docs.map((doc) => doc.id).toSet();
        final selected = widget.selectedAssignedTo;
        if (selected != null &&
            selected.isNotEmpty &&
            !activeIds.contains(selected) &&
            _inactiveAssigneeLabel == null &&
            _loadingInactiveUid != selected) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadInactiveLabel(selected));
        }

        final items = <DropdownMenuItem<String>>[
          const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
          ...users.docs.map((doc) {
            final user = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text((user['name'] as String?) ?? (user['email'] as String?) ?? 'Unknown'),
            );
          }),
        ];

        if (selected != null && selected.isNotEmpty && !activeIds.contains(selected)) {
          items.add(
            DropdownMenuItem<String>(
              value: selected,
              enabled: false,
              child: Text(_inactiveAssigneeLabel ?? '$selected (inactive)'),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          borderRadius: AppRadius.large,
          icon: const Icon(Icons.expand_more_rounded),
          decoration: const InputDecoration(
            labelText: 'Assign To',
            prefixIcon: Icon(Icons.person_add_outlined),
          ),
          hint: const Text('Select user to assign'),
          items: items,
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onAssignedToChanged(value);
            });
          },
        );
      },
      loading: () => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Assign To',
          prefixIcon: Icon(Icons.person_add_outlined),
          hintText: 'Loading users...',
        ),
        enabled: false,
      ),
      error: (error, stack) {
        Log.e('Error loading users for assignment', error: error);
        return TextFormField(
          initialValue: widget.selectedAssignedTo ?? '',
          scrollPadding: kEnquiryFieldScrollPadding,
          decoration: const InputDecoration(
            labelText: 'Assign To (User ID)',
            prefixIcon: Icon(Icons.person_add_outlined),
            hintText: 'Enter user ID or leave empty for unassigned',
          ),
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onAssignedToChanged(value.isEmpty ? null : value);
            });
          },
        );
      },
    );
  }
}
