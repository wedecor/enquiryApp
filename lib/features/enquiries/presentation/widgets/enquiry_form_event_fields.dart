import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/status_dropdown.dart';
import 'enquiry_form_section.dart';

/// Event date, type, status, priority, and assignment fields for the enquiry form.
class EnquiryFormEventFields extends ConsumerWidget {
  const EnquiryFormEventFields({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    required this.selectedEventType,
    required this.onEventTypeChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.selectedAssignedTo,
    required this.onAssignedToChanged,
    this.selectedSource,
    this.onSourceChanged,
    this.guestCountController,
    this.budgetController,
    this.showLeadSource = false,
  });

  final DateTime? selectedDate;
  final VoidCallback onSelectDate;
  final String? selectedEventType;
  final ValueChanged<String?> onEventTypeChanged;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final String? selectedPriority;
  final ValueChanged<String?> onPriorityChanged;
  final String? selectedAssignedTo;
  final ValueChanged<String?> onAssignedToChanged;
  final String? selectedSource;
  final ValueChanged<String?>? onSourceChanged;
  final TextEditingController? guestCountController;
  final TextEditingController? budgetController;
  final bool showLeadSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return EnquiryFormSection(
      title: 'Event Details',
      children: [
        InkWell(
          onTap: onSelectDate,
          child: Container(
            padding: AppSpacing.space4,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: AppTokens.space4),
                Text(
                  selectedDate == null
                      ? 'Select Event Date *'
                      : 'Event Date: ${selectedDate!.toString().split(' ')[0]}',
                  style: TextStyle(
                    color: selectedDate == null
                        ? colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        StatusDropdown(
          collectionName: 'event_types',
          value: selectedEventType,
          label: 'Event Type',
          required: true,
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onEventTypeChanged(value);
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select an event type';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTokens.space4),
        StatusDropdown(
          collectionName: 'statuses',
          value: selectedStatus,
          label: 'Status',
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onStatusChanged(value);
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select a status';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTokens.space4),
        StatusDropdown(
          collectionName: 'priorities',
          value: selectedPriority,
          label: 'Priority',
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onPriorityChanged(value);
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select a priority';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTokens.space4),
        if (guestCountController != null)
          TextFormField(
            controller: guestCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Guest Count (optional)',
              prefixIcon: Icon(Icons.groups_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              final count = int.tryParse(trimmed);
              if (count == null || count < 0)
                return 'Enter a valid guest count';
              return null;
            },
          ),
        if (guestCountController != null)
          const SizedBox(height: AppTokens.space4),
        if (budgetController != null)
          TextFormField(
            controller: budgetController,
            decoration: const InputDecoration(
              labelText: 'Budget Range (optional)',
              prefixIcon: Icon(Icons.currency_rupee),
              border: OutlineInputBorder(),
              hintText: 'e.g. 50000-100000',
            ),
          ),
        if (budgetController != null) const SizedBox(height: AppTokens.space4),
        if (showLeadSource && onSourceChanged != null)
          StatusDropdown(
            collectionName: 'sources',
            value: selectedSource,
            label: 'Lead Source',
            required: true,
            onChanged: (value) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onSourceChanged!(value);
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please select a lead source';
              }
              return null;
            },
          ),
        if (showLeadSource && onSourceChanged != null)
          const SizedBox(height: AppTokens.space4),
        roleAsync.when(
          data: (role) {
            if (role != UserRole.admin) {
              return const SizedBox.shrink();
            }

            return _AssignToDropdownField(
              selectedAssignedTo: selectedAssignedTo,
              onAssignedToChanged: onAssignedToChanged,
            );
          },
          loading: () => TextFormField(
            decoration: const InputDecoration(
              labelText: 'Assign To',
              prefixIcon: Icon(Icons.person_add),
              border: OutlineInputBorder(),
              hintText: 'Checking permissions...',
            ),
            enabled: false,
          ),
          error: (error, stack) {
            Log.e('Error checking admin status', error: error);
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

/// Assignee picker showing active users; retains inactive current assignee as disabled.
class _AssignToDropdownField extends ConsumerStatefulWidget {
  const _AssignToDropdownField({
    required this.selectedAssignedTo,
    required this.onAssignedToChanged,
  });

  final String? selectedAssignedTo;
  final ValueChanged<String?> onAssignedToChanged;

  @override
  ConsumerState<_AssignToDropdownField> createState() =>
      _AssignToDropdownFieldState();
}

class _AssignToDropdownFieldState
    extends ConsumerState<_AssignToDropdownField> {
  String? _inactiveAssigneeLabel;
  String? _loadingInactiveUid;

  @override
  void didUpdateWidget(_AssignToDropdownField oldWidget) {
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _loadInactiveLabel(selected),
          );
        }

        final items = <DropdownMenuItem<String>>[
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Unassigned'),
          ),
          ...users.docs.map((doc) {
            final user = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                (user['name'] as String?) ??
                    (user['email'] as String?) ??
                    'Unknown',
              ),
            );
          }),
        ];

        if (selected != null &&
            selected.isNotEmpty &&
            !activeIds.contains(selected)) {
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
          decoration: const InputDecoration(
            labelText: 'Assign To',
            prefixIcon: Icon(Icons.person_add),
            border: OutlineInputBorder(),
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
          prefixIcon: Icon(Icons.person_add),
          border: OutlineInputBorder(),
          hintText: 'Loading users...',
        ),
        enabled: false,
      ),
      error: (error, stack) {
        Log.e('Error loading users for assignment', error: error);
        return TextFormField(
          initialValue: widget.selectedAssignedTo ?? '',
          decoration: const InputDecoration(
            labelText: 'Assign To (User ID)',
            prefixIcon: Icon(Icons.person_add),
            border: OutlineInputBorder(),
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
