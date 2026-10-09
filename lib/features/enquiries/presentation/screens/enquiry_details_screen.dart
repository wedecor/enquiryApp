import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/role_guards.dart' show logAdminAction;
import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/contacts/contact_launcher.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../data/customer_lookup_service.dart';
import '../../data/enquiry_merge_service.dart';
import '../../domain/enquiry_location.dart';
import '../../domain/enquiry_prefill.dart';
import '../../domain/event_functions.dart';
import '../widgets/enquiry_access_denied.dart';
import '../widgets/enquiry_detail_footer.dart';
import '../widgets/enquiry_details_body.dart';
import '../widgets/enquiry_details_header.dart';
import '../widgets/enquiry_display_labels.dart';
import '../widgets/enquiry_glass_bar.dart';
import '../widgets/enquiry_round_button.dart';
import '../widgets/enquiry_sheet_header.dart';
import '../widgets/form/enquiry_customer_match_cards.dart';
import 'enquiry_form_screen.dart';

class EnquiryDetailsScreen extends ConsumerStatefulWidget {
  final String enquiryId;

  const EnquiryDetailsScreen({super.key, required this.enquiryId});

  @override
  ConsumerState<EnquiryDetailsScreen> createState() => _EnquiryDetailsScreenState();
}

class _EnquiryDetailsScreenState extends ConsumerState<EnquiryDetailsScreen> {
  bool _isUpdatingStatus = false;

  // Created once: a new snapshots() stream on every rebuild resubscribed, flashed the
  // spinner and remounted the whole screen (which re-ran the customer lookup →
  // rebuild → resubscribe … an endless flicker).
  late Stream<DocumentSnapshot> _enquiryStream;

  @override
  void initState() {
    super.initState();
    _enquiryStream = ref.read(firestoreServiceProvider).watchEnquiry(widget.enquiryId);
  }

  @override
  void didUpdateWidget(covariant EnquiryDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enquiryId != widget.enquiryId) {
      _enquiryStream = ref.read(firestoreServiceProvider).watchEnquiry(widget.enquiryId);
    }
  }

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
                return StreamBuilder<DocumentSnapshot>(
                  stream: _enquiryStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _frame(actions, Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting) {
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
    final functions = functionsOf(enquiryData);
    // Multi-function booking: the header shows the next upcoming function's day.
    final eventDate = functions.length > 1
        ? nextFunctionOf(functions, DateTime.now())?.day
        : (eventDateTs is Timestamp ? eventDateTs.toDate() : null);
    final isAdmin = userRole == UserRole.admin;
    final phone = customerPhone?.trim() ?? '';
    final otherEvents = phone.isEmpty
        ? null
        : ref
              .watch(
                customerOtherEventsProvider((phone: phone, excludeEnquiryId: widget.enquiryId)),
              )
              .valueOrNull;
    final loadedActions = [
      ...actions,
      if (isAdmin)
        EnquiryRoundButton(
          icon: Icons.more_horiz_rounded,
          tooltip: 'More actions',
          onTap: _isUpdatingStatus ? null : () => _showMoreActions(enquiryData),
        ),
    ];

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
              actions: loadedActions,
              repeatCustomer: (otherEvents?.totalEvents ?? 0) >= 1,
              locationPending: isApprovedLocationPending(
                statusIsApproved: EnquiryStatus.isApproved(labels.statusValue),
                data: enquiryData,
              ),
            ),
            EnquiryDetailsBody(
              enquiryId: widget.enquiryId,
              enquiryData: enquiryData,
              labels: labels,
              userRole: userRole,
              currentUserId: currentUserId,
              canViewImages: _canViewImages(userRole, enquiryData, currentUserId),
              bottomClearance: enquiryGlassBarClearance(context) + AppTokens.space4,
              onAddEvent: isAdmin ? () => _addAnotherEvent(enquiryData) : null,
              onOpenCustomerEvent: (event) => _openCustomerEvent(event, isAdmin: isAdmin),
              // Functions are staff-editable on their own enquiry (not protected in the rules).
              canEditFunctions: isAdmin || (enquiryData['assignedTo'] as String?) == currentUserId,
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

  /// New enquiry for the same customer, with their details filled in.
  void _addAnotherEvent(Map<String, dynamic> enquiryData) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => EnquiryFormScreen(
          mode: 'create',
          prefill: EnquiryPrefill.fromEnquiryData(enquiryData, enquiryId: widget.enquiryId),
        ),
      ),
    );
  }

  /// Opens another enquiry of this customer if the user may read it.
  void _openCustomerEvent(CustomerEvent event, {required bool isAdmin}) {
    if (!event.canOpen(isAdmin: isAdmin)) {
      final who = event.assignedToName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(who == null ? 'Not assigned to you' : 'Assigned to $who')),
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => EnquiryDetailsScreen(enquiryId: event.id)),
    );
  }

  Future<void> _showMoreActions(Map<String, dynamic> enquiryData) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Add another event'),
              subtitle: const Text('New enquiry with this customer\'s details'),
              onTap: () => Navigator.of(sheetContext).pop('add_event'),
            ),
            ListTile(
              leading: const Icon(Icons.merge_type_rounded),
              title: const Text('Mark as duplicate of…'),
              subtitle: const Text('Close this enquiry and merge it into another'),
              onTap: () => Navigator.of(sheetContext).pop('merge'),
            ),
            const SizedBox(height: AppTokens.space2),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'add_event':
        _addAnotherEvent(enquiryData);
      case 'merge':
        await _markAsDuplicate(enquiryData);
    }
  }

  /// Admin: pick another enquiry of this customer, confirm, merge, then open it.
  Future<void> _markAsDuplicate(Map<String, dynamic> enquiryData) async {
    final messenger = ScaffoldMessenger.of(context);
    if (enquiryData['mergedInto'] != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This enquiry is already marked as a duplicate')),
      );
      return;
    }
    final phone = (enquiryData['customerPhone'] as String?)?.trim() ?? '';
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This enquiry has no phone number to match on')),
      );
      return;
    }

    final result = await ref
        .read(customerLookupServiceProvider)
        .lookupOrNull(phone, excludeEnquiryId: widget.enquiryId);
    if (!mounted) return;
    if (result == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not load this customer\'s enquiries. Try again.')),
      );
      return;
    }
    if (result.events.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No other enquiries for this customer')));
      return;
    }

    final target = await showModalBottomSheet<CustomerEvent>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppTokens.space4),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  0,
                  AppTokens.space4,
                  AppTokens.space2,
                ),
                child: Text(
                  'Duplicate of which enquiry?',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final event in result.events)
                ListTile(
                  title: Text(customerEventSummary(event)),
                  subtitle: Text(
                    event.assignedToName == null
                        ? 'Unassigned'
                        : 'Assigned to ${event.assignedToName}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(event),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || target == null) return;

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Mark as duplicate?',
      message:
          'This enquiry will be closed as Closed Lost (Duplicate enquiry). Its notes and '
          'images will be added to ${customerEventSummary(target)}.',
      confirmText: 'Mark duplicate',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.merge_type_rounded,
    );
    if (!confirmed || !mounted) return;

    final user = ref.read(currentUserWithFirestoreProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isUpdatingStatus = true);
    try {
      await ref
          .read(enquiryMergeServiceProvider)
          .markAsDuplicate(sourceId: widget.enquiryId, targetId: target.id, userId: user.uid);
      ref.invalidate(customerOtherEventsProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Marked as duplicate — showing the kept enquiry')),
      );
      unawaited(
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(builder: (context) => EnquiryDetailsScreen(enquiryId: target.id)),
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Could not mark as duplicate: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
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

    if (!confirmed || !mounted) return;

    try {
      setState(() {
        _isUpdatingStatus = true;
      });

      await ref.read(firestoreServiceProvider).deleteEnquiry(widget.enquiryId);

      // The enquiry's history subcollection goes with it, so the delete is recorded in
      // the top-level admin_audit log instead (non-fatal; logged on failure).
      await logAdminAction(ref, 'enquiry_deleted', {'enquiryId': widget.enquiryId});

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enquiry deleted')));
      }
    } catch (e) {
      if (context.mounted) {
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
