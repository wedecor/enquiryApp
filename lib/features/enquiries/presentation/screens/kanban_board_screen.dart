import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../dashboard/presentation/dashboard_providers.dart';
import '../../data/enquiry_repository.dart';
import '../../domain/event_functions.dart';
import '../../filters/apply_enquiry_filters.dart';
import '../../filters/filters_state.dart';
import '../widgets/approved_date_clash_prompt.dart';
import '../widgets/confirm_booking_sheet.dart';
import '../widgets/list/kanban_lane.dart';
import '../widgets/lost_reason_sheet.dart';
import 'enquiry_details_screen.dart';

// ── Column definitions ────────────────────────────────────────────────────────

class _KanbanColumn {
  const _KanbanColumn({required this.status, required this.label});
  final String status;
  final String label;
}

List<_KanbanColumn> get _kColumns =>
    EnquiryStatus.values.map((s) => _KanbanColumn(status: s.value, label: s.label)).toList();

const double _kColumnWidth = 272.0;

// ── Main screen ───────────────────────────────────────────────────────────────

class KanbanBoardScreen extends ConsumerStatefulWidget {
  const KanbanBoardScreen({super.key, this.embeddedInShell = false, this.filters});

  final bool embeddedInShell;
  final EnquiryFilters? filters;

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> {
  // Tracks which column is being hovered by a drag (for visual feedback)
  String? _hoverColumn;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (v) => v, orElse: () => null);

    return currentUser.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          ErrorState(message: 'Couldn\'t load your profile.\nPlease try again.', error: e),
      data: (user) {
        if (user == null) return const Center(child: Text('Not logged in'));
        final isAdmin = user.role == UserRole.admin;

        // Same shared listeners as the dashboard: every column's slice.
        final enquiriesAsync = watchRoleScopedEnquiries(
          ref,
          isAdmin: isAdmin,
          uid: user.uid,
          scopes: EnquiryScope.values,
        );
        return Builder(
          builder: (context) {
            if (enquiriesAsync.hasError) {
              return ErrorState(
                message: 'Couldn\'t load the board.\nPlease check your connection and try again.',
                error: enquiriesAsync.error,
              );
            }
            final loadedDocs = enquiriesAsync.valueOrNull;
            if (loadedDocs == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = loadedDocs.where((doc) {
              if (widget.filters == null) return true;
              return matchesEnquiryFilters(
                doc.data() as Map<String, dynamic>,
                widget.filters!,
                currentUserId: user.uid,
              );
            }).toList();

            // Bucket docs by statusValue
            final Map<String, List<QueryDocumentSnapshot>> buckets = {};
            for (final col in _kColumns) {
              buckets[col.status] = [];
            }
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final rawStatus = (data['statusValue'] as String?)?.trim();
              final canonical = EnquiryStatus.fromValue(rawStatus)?.value ?? 'new';
              if (buckets.containsKey(canonical)) {
                buckets[canonical]!.add(doc);
              }
            }

            // Sort each bucket by event date (next upcoming function for
            // multi-function bookings) then created date
            final sortNow = DateTime.now();
            for (final bucket in buckets.values) {
              bucket.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final DateTime? aDate = listSortDateOf(aData, sortNow);
                final DateTime? bDate = listSortDateOf(bData, sortNow);
                if (aDate != null && bDate != null) return aDate.compareTo(bDate);
                if (aDate != null) return -1;
                if (bDate != null) return 1;
                final aC = _ts(aData['createdAt']) ?? DateTime(2000);
                final bC = _ts(bData['createdAt']) ?? DateTime(2000);
                return bC.compareTo(aC);
              });
            }

            return _KanbanBoard(
              columns: _kColumns,
              buckets: buckets,
              hoverColumn: _hoverColumn,
              dropdownLookup: dropdownLookup,
              onDragOver: (status) {
                if (_hoverColumn != status) setState(() => _hoverColumn = status);
              },
              onDragLeave: () {
                if (_hoverColumn != null) setState(() => _hoverColumn = null);
              },
              onDrop: (enquiryId, newStatus) async {
                setState(() => _hoverColumn = null);
                QueryDocumentSnapshot<Object?>? doc;
                for (final d in docs) {
                  if (d.id == enquiryId) {
                    doc = d;
                    break;
                  }
                }
                // Card vanished from the live data (deleted / filtered) mid-drag.
                if (doc == null) return;
                final currentStatus =
                    (doc.data() as Map<String, dynamic>)['statusValue'] as String?;
                if (EnquiryStatus.statusesMatch(currentStatus, newStatus)) return;
                if (!isAdmin) {
                  if (!EnquiryStatus.isStaffTransitionAllowed(currentStatus, newStatus)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This status change is not allowed')),
                      );
                    }
                    return;
                  }
                }
                // Approving: Confirm booking (location, optional amounts for admins),
                // then the date check.
                Map<String, Object?>? bookingFields;
                if (EnquiryStatus.isApproved(newStatus)) {
                  final booking = await ensureApprovalBooking(
                    context,
                    ref,
                    enquiryId: enquiryId,
                    data: doc.data() as Map<String, dynamic>,
                    isAdmin: isAdmin,
                  );
                  if (!booking.proceed || !context.mounted) return;
                  bookingFields = booking.fields;
                }
                // Approving: warn when other approved bookings share the event date.
                if (EnquiryStatus.isApproved(newStatus)) {
                  // Every function day of the booking (legacy: the event date).
                  final functionDays = functionDaysOf(doc.data() as Map<String, dynamic>);
                  if (functionDays.isNotEmpty) {
                    final proceed = await confirmApprovedDateClash(
                      context,
                      ref,
                      eventDates: functionDays,
                      excludeEnquiryId: enquiryId,
                      isDateChange: false,
                    );
                    if (!proceed || !context.mounted) return;
                  }
                }
                if (!context.mounted) return;
                final lostPrompt = await promptLostReasonIfNeeded(context, newStatus);
                if (!lostPrompt.proceed) return;
                try {
                  // Use repository so audit history, statusLabel, notifications
                  // and legacy-field cleanup all happen — same as dashboard tabs.
                  await ref
                      .read(enquiryRepositoryProvider)
                      .updateStatus(
                        id: enquiryId,
                        nextStatus: newStatus,
                        userId: user.uid,
                        lostReason: lostPrompt.choice,
                        extraFields: bookingFields,
                      );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
                  }
                }
              },
              onTap: (enquiryId) => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => EnquiryDetailsScreen(enquiryId: enquiryId)),
              ),
            );
          },
        );
      },
    );
  }

  DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}

// ── Board layout ──────────────────────────────────────────────────────────────

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.columns,
    required this.buckets,
    required this.hoverColumn,
    required this.dropdownLookup,
    required this.onDragOver,
    required this.onDragLeave,
    required this.onDrop,
    required this.onTap,
  });

  final List<_KanbanColumn> columns;
  final Map<String, List<QueryDocumentSnapshot>> buckets;
  final String? hoverColumn;
  final DropdownLookup? dropdownLookup;
  final void Function(String status) onDragOver;
  final VoidCallback onDragLeave;
  final void Function(String enquiryId, String newStatus) onDrop;
  final void Function(String enquiryId) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space1,
        AppTokens.space4,
        AppTokens.space4,
      ),
      itemCount: columns.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppTokens.space3),
      itemBuilder: (context, i) {
        final col = columns[i];
        return KanbanLane(
          status: col.status,
          label: dropdownLookup?.labelForStatus(col.status) ?? col.label,
          cards: buckets[col.status] ?? [],
          isHovered: hoverColumn == col.status,
          dropdownLookup: dropdownLookup,
          onDragOver: () => onDragOver(col.status),
          onDragLeave: onDragLeave,
          onDrop: (id) => onDrop(id, col.status),
          onTap: onTap,
          width: _kColumnWidth,
        );
      },
    );
  }
}
