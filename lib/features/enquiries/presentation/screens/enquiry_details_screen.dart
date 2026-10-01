import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/providers/audit_provider.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../ui/primitives/primitives.dart';
import '../widgets/enquiry_access_denied.dart';
import '../widgets/enquiry_detail_footer.dart';
import '../widgets/enquiry_details_body.dart';
import '../widgets/enquiry_details_header.dart';
import '../widgets/enquiry_display_labels.dart';
import '../widgets/enquiry_glass_bar.dart';
import '../widgets/enquiry_round_button.dart';
import '../widgets/enquiry_sheet_header.dart';
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

    final actions = roleAsync.maybeWhen(
      data: (role) => role != UserRole.admin
          ? const <Widget>[]
          : [
              EnquiryRoundButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit Enquiry',
                onTap: _openEdit,
              ),
              EnquiryRoundButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete Enquiry',
                iconColor: Theme.of(context).colorScheme.error,
                onTap: _isUpdatingStatus
                    ? null
                    : () async {
                        await _confirmAndDelete(context);
                      },
              ),
            ],
      orElse: () => const <Widget>[],
    );

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: currentUser.when(
          data: (user) {
            if (user == null) {
              return _frame(actions, const Text('Please log in to view enquiry details'));
            }

            return roleAsync.when(
              data: (userRole) {
                final firestoreService = ref.watch(firestoreServiceProvider);
                return StreamBuilder<DocumentSnapshot>(
                  stream: firestoreService.watchEnquiry(widget.enquiryId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _frame(actions, Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _frame(actions, const CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return _frame(actions, const Text('Enquiry not found'));
                    }

                    final enquiryData = snapshot.data!.data() as Map<String, dynamic>;
                    final dropdownLookup = ref
                        .watch(dropdownLookupProvider)
                        .maybeWhen(data: (value) => value, orElse: () => null);

                    final labels = EnquiryDisplayLabels.from(enquiryData, dropdownLookup);

                    if (userRole != UserRole.admin) {
                      final assignedTo = enquiryData['assignedTo'] as String?;
                      final currentUserId = user.uid;

                      if (assignedTo != null && assignedTo != currentUserId) {
                        return _frame(actions, const EnquiryAccessDenied());
                      }
                    }

                    return _buildLoaded(
                      context,
                      enquiryData: enquiryData,
                      labels: labels,
                      userRole: userRole,
                      currentUserId: user.uid,
                      actions: actions,
                    );
                  },
                );
              },
              loading: () => _frame(actions, const CircularProgressIndicator()),
              error: (error, stack) => _frame(actions, Text('Error checking permissions: $error')),
            );
          },
          loading: () => _frame(actions, const CircularProgressIndicator()),
          error: (error, stack) => _frame(actions, Text('Error loading user data: $error')),
        ),
      ),
    );
  }

  /// Header + centred state content for loading, error and gated states.
  Widget _frame(List<Widget> actions, Widget child) {
    return CustomScrollView(
      slivers: [
        EnquirySheetHeader(eyebrow: 'Enquiry', title: 'Enquiry Details', actions: actions),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: AppSpacing.space6,
              child: DefaultTextStyle.merge(textAlign: TextAlign.center, child: child),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoaded(
    BuildContext context, {
    required Map<String, dynamic> enquiryData,
    required EnquiryDisplayLabels labels,
    required UserRole? userRole,
    required String currentUserId,
    required List<Widget> actions,
  }) {
    final customerPhone = enquiryData['customerPhone'] as String?;
    final eventDateTs = enquiryData['eventDate'];
    final eventDate = eventDateTs is Timestamp ? eventDateTs.toDate() : null;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            EnquiryDetailsHeader(
              enquiryId: widget.enquiryId,
              customerName: (enquiryData['customerName'] as String?) ?? 'Customer',
              customerPhone: customerPhone,
              location:
                  (enquiryData['eventLocation'] as String?) ?? (enquiryData['location'] as String?),
              eventTypeLabel: labels.eventTypeLabel,
              eventDate: eventDate,
              statusValue: labels.statusValue,
              statusLabel: labels.statusLabel,
              actions: actions,
            ),
            EnquiryDetailsBody(
              enquiryId: widget.enquiryId,
              enquiryData: enquiryData,
              labels: labels,
              userRole: userRole,
              currentUserId: currentUserId,
              canViewImages: _canViewImages(userRole, enquiryData, currentUserId),
              bottomClearance: enquiryGlassBarClearance(context) + AppTokens.space4,
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: EnquiryGlassBar(
            child: EnquiryDetailFooter(
              enquiryId: widget.enquiryId,
              enquiryData: enquiryData,
              userRole: userRole,
              currentUserId: currentUserId,
              statusValue: labels.statusValue,
              statusLabel: labels.statusLabel,
              customerPhone: customerPhone,
              customerName: (enquiryData['customerName'] as String?) ?? 'Customer',
              onCall: customerPhone == null
                  ? null
                  : () async {
                      final launcher = ref.read(contactLauncherProvider);
                      await launcher.callNumberWithAudit(
                        customerPhone,
                        enquiryId: widget.enquiryId,
                      );
                    },
              onWhatsApp: customerPhone == null
                  ? null
                  : () async {
                      final launcher = ref.read(contactLauncherProvider);
                      await launcher.openWhatsAppWithAudit(
                        customerPhone,
                        enquiryId: widget.enquiryId,
                        prefillText:
                            'Hi ${enquiryData['customerName'] ?? 'there'}, this is from We Decor.',
                      );
                    },
              onEdit: userRole == UserRole.admin ? _openEdit : null,
            ),
          ),
        ),
      ],
    );
  }

  void _openEdit() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => EnquiryFormScreen(enquiryId: widget.enquiryId, mode: 'edit'),
      ),
    );
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
