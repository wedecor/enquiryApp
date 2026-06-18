import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/audit_provider.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/enquiry_history_widget.dart';
import '../widgets/customer_info_section.dart';
import '../widgets/enquiry_assignment_section.dart';
import '../widgets/enquiry_detail_info_row.dart';
import '../widgets/enquiry_detail_section.dart';
import '../widgets/enquiry_details_header.dart';
import '../widgets/enquiry_images_section.dart';
import '../widgets/event_details_section.dart';
import '../widgets/payment_section.dart';
import 'enquiry_form_screen.dart';

class EnquiryDetailsScreen extends ConsumerStatefulWidget {
  final String enquiryId;

  const EnquiryDetailsScreen({super.key, required this.enquiryId});

  @override
  ConsumerState<EnquiryDetailsScreen> createState() => _EnquiryDetailsScreenState();
}

class _EnquiryDetailsScreenState extends ConsumerState<EnquiryDetailsScreen> {
  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final roleAsync = ref.watch(roleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Details'),
        actions: [
          roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              EnquiryFormScreen(enquiryId: widget.enquiryId, mode: 'edit'),
                        ),
                      );
                    },
                    tooltip: 'Edit Enquiry',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _isUpdatingStatus
                        ? null
                        : () async {
                            await _confirmAndDelete(context);
                          },
                    tooltip: 'Delete Enquiry',
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in to view enquiry details'));
          }

          return roleAsync.when(
            data: (userRole) {
              final firestoreService = ref.watch(firestoreServiceProvider);
              return StreamBuilder<DocumentSnapshot>(
                stream: firestoreService.watchEnquiry(widget.enquiryId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Enquiry not found'));
                  }

                  final enquiryData = snapshot.data!.data() as Map<String, dynamic>;
                  final dropdownLookup = ref
                      .watch(dropdownLookupProvider)
                      .maybeWhen(data: (value) => value, orElse: () => null);

                  String labelOrLookup(
                    String? label,
                    String value,
                    String Function(DropdownLookup, String) resolver,
                  ) {
                    if (label != null && label.trim().isNotEmpty) return label;
                    return dropdownLookup != null
                        ? resolver(dropdownLookup, value)
                        : DropdownLookup.titleCase(value);
                  }

                  final statusValueRaw = enquiryData['statusValue'] as String?;
                  final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
                      ? statusValueRaw!.trim()
                      : 'new';
                  final statusLabel = labelOrLookup(
                    enquiryData['statusLabel'] as String?,
                    statusValue,
                    (l, v) => l.labelForStatus(v),
                  );

                  final eventTypeValueRaw =
                      (enquiryData['eventTypeValue'] ?? enquiryData['eventType']) as String?;
                  final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
                      ? eventTypeValueRaw!.trim()
                      : 'event';
                  final eventTypeLabel = labelOrLookup(
                    enquiryData['eventTypeLabel'] as String?,
                    eventTypeValue,
                    (l, v) => l.labelForEventType(v),
                  );

                  final priorityValueRaw =
                      (enquiryData['priorityValue'] ?? enquiryData['priority']) as String?;
                  final priorityValue = (priorityValueRaw?.trim().isNotEmpty ?? false)
                      ? priorityValueRaw!.trim()
                      : null;
                  final priorityLabel = priorityValue != null
                      ? labelOrLookup(
                          enquiryData['priorityLabel'] as String?,
                          priorityValue,
                          (l, v) => l.labelForPriority(v),
                        )
                      : 'N/A';

                  final paymentStatusValueRaw =
                      (enquiryData['paymentStatusValue'] ?? enquiryData['paymentStatus'])
                          as String?;
                  final paymentStatusValue = (paymentStatusValueRaw?.trim().isNotEmpty ?? false)
                      ? paymentStatusValueRaw!.trim()
                      : null;
                  final paymentStatusLabel = paymentStatusValue != null
                      ? labelOrLookup(
                          enquiryData['paymentStatusLabel'] as String?,
                          paymentStatusValue,
                          (l, v) => l.labelForPaymentStatus(v),
                        )
                      : 'N/A';

                  final sourceValueRaw =
                      (enquiryData['sourceValue'] ?? enquiryData['source']) as String?;
                  final sourceValue = (sourceValueRaw?.trim().isNotEmpty ?? false)
                      ? sourceValueRaw!.trim()
                      : null;
                  final sourceLabel = sourceValue != null
                      ? labelOrLookup(
                          enquiryData['sourceLabel'] as String?,
                          sourceValue,
                          (l, v) => l.labelForSource(v),
                        )
                      : 'N/A';

                  if (userRole != UserRole.admin) {
                    final assignedTo = enquiryData['assignedTo'] as String?;
                    final currentUserId = user.uid;

                    if (assignedTo != null && assignedTo != currentUserId) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppTokens.space4),
                            const Text(
                              'Access Denied',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppTokens.space2),
                            Text(
                              'You can only view enquiries assigned to you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  final images = (enquiryData['images'] as List?)?.cast<dynamic>() ?? const [];

                  return SingleChildScrollView(
                    padding: AppSpacing.space4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EnquiryDetailsHeader(
                          enquiryId: widget.enquiryId,
                          enquiryData: enquiryData,
                          userRole: userRole,
                          currentUserId: user.uid,
                          statusValue: statusValue,
                          statusLabel: statusLabel,
                        ),
                        const SizedBox(height: AppTokens.space6),

                        CustomerInfoSection(
                          enquiryId: widget.enquiryId,
                          customerName: (enquiryData['customerName'] as String?) ?? 'N/A',
                          customerPhone: enquiryData['customerPhone'] as String?,
                          location:
                              (enquiryData['eventLocation'] as String?) ??
                              (enquiryData['location'] as String? ?? 'N/A'),
                          eventTypeLabel: eventTypeLabel,
                          eventDate: (enquiryData['eventDate'] as Timestamp?)?.toDate(),
                          statusValue: statusValue,
                        ),

                        EventDetailsSection(
                          eventTypeLabel: eventTypeLabel,
                          eventDate: enquiryData['eventDate'],
                          guestCount: enquiryData['guestCount'],
                          budgetRange: enquiryData['budgetRange'] as String?,
                          priorityLabel: priorityLabel,
                          sourceLabel: sourceLabel,
                        ),

                        if (_canViewImages(userRole, enquiryData, user.uid))
                          EnquiryImagesSection(images: images),

                        EnquiryAssignmentSection(
                          userRole: userRole,
                          assignedTo: enquiryData['assignedTo'] as String?,
                          createdBy: enquiryData['createdBy'] as String?,
                          currentUserId: user.uid,
                        ),

                        if (userRole == UserRole.admin)
                          PaymentSection(
                            totalCost: enquiryData['totalCost'],
                            advancePaid: enquiryData['advancePaid'],
                            paymentStatusLabel: paymentStatusLabel,
                          ),

                        EnquiryDetailSection(
                          title: 'Description',
                          children: [
                            EnquiryDetailInfoRow(
                              label: 'Notes',
                              value:
                                  (enquiryData['description'] as String?) ?? 'No description provided',
                            ),
                          ],
                        ),

                        EnquiryDetailSection(
                          title: 'Timestamps',
                          children: [
                            EnquiryDetailInfoRow(
                              label: 'Created',
                              value: _formatTimestamp(enquiryData['createdAt']),
                            ),
                            EnquiryDetailInfoRow(
                              label: 'Last Updated',
                              value: _formatTimestamp(enquiryData['updatedAt']),
                            ),
                          ],
                        ),

                        EnquiryDetailSection(
                          title: 'Change History',
                          children: [EnquiryHistoryWidget(enquiryId: widget.enquiryId)],
                        ),

                        const SizedBox(height: AppTokens.space8),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error checking permissions: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading user data: $error')),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute}';
    }
    return timestamp.toString();
  }

  bool _canViewImages(UserRole? role, Map<String, dynamic> data, String meUid) {
    if (role == UserRole.admin) return true;
    final assignedTo = data['assignedTo'] as String?;
    return assignedTo != null && assignedTo == meUid;
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Enquiry',
      message:
          'Are you sure you want to delete this enquiry?\n\nThis action cannot be undone and all enquiry data will be permanently removed.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (!confirmed) return;

    try {
      setState(() {
        _isUpdatingStatus = true;
      });

      final auditService = ref.read(auditServiceProvider);
      await auditService.recordChange(
        enquiryId: widget.enquiryId,
        fieldChanged: 'deleted',
        oldValue: 'exists',
        newValue: 'deleted',
      );

      await ref.read(firestoreServiceProvider).deleteEnquiry(widget.enquiryId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enquiry deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete enquiry: $e')));
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
