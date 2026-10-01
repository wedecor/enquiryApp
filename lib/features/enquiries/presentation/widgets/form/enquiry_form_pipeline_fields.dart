import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logging/logger.dart';
import '../../../../../core/providers/role_provider.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../../shared/widgets/status_dropdown.dart';
import '../enquiry_form_section.dart';
import 'enquiry_assign_to_field.dart';

/// Status, priority, lead source and (admin-only) assignment for the form.
class EnquiryFormPipelineFields extends ConsumerWidget {
  const EnquiryFormPipelineFields({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.selectedAssignedTo,
    required this.onAssignedToChanged,
    this.selectedSource,
    this.onSourceChanged,
    this.showLeadSource = false,
    this.showStatus = true,
  });

  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final String? selectedPriority;
  final ValueChanged<String?> onPriorityChanged;
  final String? selectedAssignedTo;
  final ValueChanged<String?> onAssignedToChanged;
  final String? selectedSource;
  final ValueChanged<String?>? onSourceChanged;
  final bool showLeadSource;
  final bool showStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);

    return EnquiryFormSection(
      eyebrow: 'Pipeline',
      title: 'Lead & Assignment',
      children: [
        if (showStatus) ...[
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
          const SizedBox(height: kEnquiryFieldGap),
        ],
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
        const SizedBox(height: kEnquiryFieldGap),
        if (showLeadSource && onSourceChanged != null) ...[
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
          const SizedBox(height: kEnquiryFieldGap),
        ],
        roleAsync.when(
          data: (role) {
            if (role != UserRole.admin) {
              return const SizedBox.shrink();
            }

            return EnquiryAssignToField(
              selectedAssignedTo: selectedAssignedTo,
              onAssignedToChanged: onAssignedToChanged,
            );
          },
          loading: () => TextFormField(
            decoration: const InputDecoration(
              labelText: 'Assign To',
              prefixIcon: Icon(Icons.person_add_outlined),
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
