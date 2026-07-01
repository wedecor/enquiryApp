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
                    color: selectedDate == null ? colorScheme.onSurfaceVariant : null,
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
        roleAsync.when(
          data: (role) {
            if (role != UserRole.admin) {
              return const SizedBox.shrink();
            }

            return Consumer(
              builder: (context, ref, child) {
                final activeUsers = ref.watch(activeUsersProvider);

                return activeUsers.when(
                  data: (users) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedAssignedTo,
                      decoration: const InputDecoration(
                        labelText: 'Assign To',
                        prefixIcon: Icon(Icons.person_add),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select user to assign'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
                        ...users.docs.map((doc) {
                          final user = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(
                              (user['name'] as String?) ?? (user['email'] as String?) ?? 'Unknown',
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onAssignedToChanged(value);
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
                      initialValue: selectedAssignedTo ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Assign To (User ID)',
                        prefixIcon: Icon(Icons.person_add),
                        border: OutlineInputBorder(),
                        hintText: 'Enter user ID or leave empty for unassigned',
                      ),
                      onChanged: (value) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onAssignedToChanged(value.isEmpty ? null : value);
                        });
                      },
                    );
                  },
                );
              },
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
