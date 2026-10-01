import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/dropdown_defaults.dart';
import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../data/enquiry_repository.dart';
import 'enquiry_status_parts.dart';

/// How [EnquiryStatusControl] presents the available statuses.
enum EnquiryStatusLayout {
  /// Glass pill dropdown for rows and inline use.
  compact,

  /// Full list of glass options with a gold selection, for sheets.
  list,
}

/// Status picker with role-based transition guards for enquiry details.
class EnquiryStatusControl extends ConsumerStatefulWidget {
  const EnquiryStatusControl({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.currentStatusValue,
    required this.currentStatusLabel,
    required this.isAdmin,
    this.isAssignee = true,
    this.layout = EnquiryStatusLayout.compact,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final String currentStatusValue;
  final String currentStatusLabel;
  final bool isAdmin;
  final bool isAssignee;
  final EnquiryStatusLayout layout;

  @override
  ConsumerState<EnquiryStatusControl> createState() => _EnquiryStatusControlState();
}

class _EnquiryStatusControlState extends ConsumerState<EnquiryStatusControl> {
  String? _selectedStatus;
  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin && !widget.isAssignee) {
      return _ReadOnlyStatusChip(
        label: widget.currentStatusLabel,
        statusValue: widget.currentStatusValue,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: ref.read(firestoreServiceProvider).watchActiveStatusDropdownItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        List<Map<String, String>> statuses;
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          statuses = DropdownDefaults.statuses;
        } else {
          statuses = DropdownDefaults.resolveStatusOptions(
            FirestoreService.parseDropdownOptions(
              snapshot.data!.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>(),
            ),
          );
        }

        final rawCurrent = (_selectedStatus ?? widget.currentStatusValue);
        final currentStatus = EnquiryStatus.canonicalValue(rawCurrent) ?? rawCurrent;
        final values = statuses.map((s) => s['value'] ?? '').toList();
        if (!values.contains(currentStatus)) {
          return _ReadOnlyStatusChip(
            label: widget.currentStatusLabel.isNotEmpty ? widget.currentStatusLabel : currentStatus,
            statusValue: currentStatus,
          );
        }

        final nextOptions = <Map<String, String>>[...statuses];
        if (!widget.isAdmin) {
          final allowed = EnquiryStatus.staffAllowedNextValues(rawCurrent);
          nextOptions.retainWhere((s) {
            final v = s['value'] ?? '';
            return v == currentStatus || allowed.contains(v);
          });
        }

        final canChange = widget.isAdmin || (!widget.isAdmin && widget.isAssignee);
        final enabled = canChange && !_isUpdatingStatus;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.layout == EnquiryStatusLayout.list
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            if (widget.layout == EnquiryStatusLayout.list)
              for (final status in nextOptions)
                Padding(
                  padding: AppSpacing.bottom(AppTokens.space2),
                  child: EnquiryStatusOption(
                    label: status['label'] ?? status['value'] ?? '',
                    color: statusColorFor(context, status['value']),
                    selected: (status['value'] ?? '') == currentStatus,
                    onTap: enabled ? () => _handleStatusChange(status['value'], rawCurrent) : null,
                  ),
                )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: EnquiryStatusPill(
                      color: statusColorFor(context, currentStatus),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: const Key('statusDropdown'),
                          value: currentStatus,
                          isDense: true,
                          borderRadius: AppRadius.large,
                          icon: const Icon(Icons.expand_more_rounded),
                          items: nextOptions.map((status) {
                            final value = status['value'] ?? '';
                            final label = status['label'] ?? value;
                            return DropdownMenuItem<String>(
                              value: value,
                              child: EnquiryStatusLabel(
                                label: label,
                                color: statusColorFor(context, value),
                              ),
                            );
                          }).toList(),
                          onChanged: enabled
                              ? (value) => _handleStatusChange(value, rawCurrent)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  if (_isUpdatingStatus) ...[
                    const SizedBox(width: AppTokens.space2),
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            if (_isUpdatingStatus && widget.layout == EnquiryStatusLayout.list)
              const LinearProgressIndicator(minHeight: 2),
            if (!widget.isAdmin && !widget.isAssignee) ...[
              const SizedBox(height: AppTokens.space1 + 2),
              Text(
                'Only the assigned user can change status',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _handleStatusChange(String? value, String currentStatusValue) async {
    if (value == null || value == currentStatusValue) return;

    final safeValue = (_selectedStatus ?? widget.currentStatusValue);
    if (!widget.isAdmin) {
      if (!EnquiryStatus.isStaffTransitionAllowed(safeValue, value)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This status change is not allowed'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
    }

    final lookup = await ref.read(dropdownLookupProvider.future);
    final nextLabel = lookup.labelForStatus(value);
    final oldStatusLabel = lookup.labelForStatus(currentStatusValue);

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Change Status',
      message:
          'Change status from "$oldStatusLabel" to "$nextLabel"?\n\nThis will notify all admins.',
      confirmText: 'Change Status',
      cancelText: 'Cancel',
      isDestructive: false,
      icon: Icons.info_outline,
    );

    if (!confirmed || !mounted) {
      setState(() {
        _selectedStatus = currentStatusValue;
      });
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
      _selectedStatus = value;
    });

    try {
      final userId = ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown';
      // Route through repository — handles audit history, statusLabel,
      // statusUpdatedBy, notifications, and legacy field cleanup in one place.
      await ref
          .read(enquiryRepositoryProvider)
          .updateStatus(id: widget.enquiryId, nextStatus: value, userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Status updated'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _selectedStatus = currentStatusValue;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }
}

class _ReadOnlyStatusChip extends StatelessWidget {
  const _ReadOnlyStatusChip({required this.label, required this.statusValue});

  final String label;
  final String statusValue;

  @override
  Widget build(BuildContext context) {
    return EnquiryStatusChip(label: label, color: statusColorFor(context, statusValue));
  }
}

Color statusColorFor(BuildContext context, String? status) {
  return AppColorScheme.statusColorFor(status);
}
