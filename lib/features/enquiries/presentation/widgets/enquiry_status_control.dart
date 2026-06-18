import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/providers/audit_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';

/// Status dropdown with role-based transition guards for enquiry details.
class EnquiryStatusControl extends ConsumerStatefulWidget {
  const EnquiryStatusControl({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    required this.currentStatusValue,
    required this.currentStatusLabel,
    required this.isAdmin,
    this.isAssignee = true,
  });

  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final String currentStatusValue;
  final String currentStatusLabel;
  final bool isAdmin;
  final bool isAssignee;

  @override
  ConsumerState<EnquiryStatusControl> createState() => _EnquiryStatusControlState();
}

class _EnquiryStatusControlState extends ConsumerState<EnquiryStatusControl> {
  String? _selectedStatus;
  bool _isUpdatingStatus = false;

  static const Map<String, List<String>> _allowedTransitions = {
    'new': ['in_talks', 'cancelled', 'not_interested'],
    'in_talks': ['quote_sent', 'cancelled', 'not_interested'],
    'quote_sent': ['confirmed', 'closed_lost', 'not_interested'],
    'confirmed': ['scheduled', 'cancelled'],
    'scheduled': ['completed', 'cancelled'],
    'completed': [],
    'cancelled': [],
    'closed_lost': [],
    'not_interested': [],
  };

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

        List<Map<String, dynamic>> statuses;
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          statuses = [
            {'value': 'new', 'label': 'New', 'order': 1},
            {'value': 'in_talks', 'label': 'In Talks', 'order': 2},
            {'value': 'quote_sent', 'label': 'Quote Sent', 'order': 3},
            {'value': 'approved', 'label': 'Approved', 'order': 4},
            {'value': 'scheduled', 'label': 'Scheduled', 'order': 5},
            {'value': 'completed', 'label': 'Completed', 'order': 6},
            {'value': 'cancelled', 'label': 'Cancelled', 'order': 7},
            {'value': 'closed_lost', 'label': 'Closed Lost', 'order': 8},
          ];
        } else {
          statuses = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        }

        final currentStatus = (_selectedStatus ?? widget.currentStatusValue);
        final values = statuses.map((s) => (s['value'] as String?) ?? '').toList();
        final safeValue = values.contains(currentStatus)
            ? currentStatus
            : (values.isNotEmpty ? values.first : 'new');

        final nextOptions = <Map<String, dynamic>>[...statuses];
        if (!widget.isAdmin) {
          final allowed = _allowedTransitions[safeValue] ?? const <String>[];
          nextOptions.retainWhere((s) {
            final v = (s['value'] as String?) ?? '';
            return v == safeValue || allowed.contains(v);
          });
        }

        final canChange = widget.isAdmin || (!widget.isAdmin && widget.isAssignee);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              key: const Key('statusDropdown'),
              value: safeValue,
              items: nextOptions.map((status) {
                final value = (status['value'] as String?) ?? '';
                final label = (status['label'] as String?) ?? value;
                return DropdownMenuItem<String>(value: value, child: Text(label));
              }).toList(),
              onChanged: (!canChange || _isUpdatingStatus)
                  ? null
                  : (value) => _handleStatusChange(value, widget.currentStatusValue),
            ),
            if (_isUpdatingStatus) ...[
              const SizedBox(width: AppTokens.space2),
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
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
    if (kDebugMode) {
      debugPrint('🚀 STATUS CHANGE TRIGGERED');
      debugPrint('   New value: $value');
      debugPrint('   Current value: $currentStatusValue');
      debugPrint('   Is Admin: ${widget.isAdmin}');
      debugPrint('   EnquiryId: ${widget.enquiryId}');
    }

    if (value == null || value == currentStatusValue) {
      if (kDebugMode) {
        debugPrint('⚠️ STATUS CHANGE: No change needed, returning early');
      }
      return;
    }

    final safeValue = (_selectedStatus ?? widget.currentStatusValue);
    if (!widget.isAdmin) {
      final allowed = _allowedTransitions[safeValue] ?? const <String>[];
      if (!allowed.contains(value)) {
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
      final oldStatusValue = currentStatusValue;
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateEnquiry(widget.enquiryId, {
        'statusValue': value,
        'statusLabel': nextLabel,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
        'updatedBy': ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
        'eventStatus': FieldValue.delete(),
        'status': FieldValue.delete(),
        'status_slug': FieldValue.delete(),
      });

      final auditService = ref.read(auditServiceProvider);
      await auditService.recordChange(
        enquiryId: widget.enquiryId,
        fieldChanged: 'statusValue',
        oldValue: oldStatusValue,
        newValue: value,
      );

      try {
        if (kDebugMode) {
          debugPrint('📢 STATUS UPDATE: About to call notifyStatusUpdated');
          debugPrint('   EnquiryId: ${widget.enquiryId}');
          debugPrint('   OldStatus: $oldStatusLabel → NewStatus: $nextLabel');
          debugPrint(
            '   UpdatedBy: ${ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown'}',
          );
        }

        final currentEnquiryData = await firestoreService.getEnquiry(widget.enquiryId) ?? {};
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.notifyStatusUpdated(
          enquiryId: widget.enquiryId,
          customerName: currentEnquiryData['customerName'] as String? ?? 'Unknown Customer',
          oldStatus: oldStatusLabel,
          newStatus: nextLabel,
          updatedBy: ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
          assignedTo: currentEnquiryData['assignedTo'] as String?,
        );

        if (kDebugMode) {
          debugPrint('✅ STATUS UPDATE: notifyStatusUpdated completed');
        }
      } catch (notificationError, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ ERROR sending notifications: $notificationError');
          debugPrint('Stack trace: $stackTrace');
        }
        Log.e(
          'EnquiryStatusControl: error sending notifications',
          error: notificationError,
          stackTrace: stackTrace,
        );
      }

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
    return Container(
      padding: AppSpacing.horizontal(AppTokens.space3).copyWith(
        top: AppTokens.space1 + 2,
        bottom: AppTokens.space1 + 2,
      ),
      decoration: BoxDecoration(
        color: statusColorFor(context, statusValue),
        borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color statusColorFor(BuildContext context, String? status) {
  final colorScheme = Theme.of(context).colorScheme;

  switch (status) {
    case 'new':
      return AppColorScheme.warning;
    case 'in_talks':
      return colorScheme.primary;
    case 'quote_sent':
      return AppColorScheme.info;
    case 'approved':
      return colorScheme.secondary;
    case 'scheduled':
      return colorScheme.tertiary;
    case 'completed':
      return AppColorScheme.success;
    case 'cancelled':
    case 'closed_lost':
      return colorScheme.error;
    default:
      return colorScheme.outline;
  }
}
