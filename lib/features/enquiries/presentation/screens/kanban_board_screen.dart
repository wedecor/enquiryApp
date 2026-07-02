import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/enquiry_repository.dart';
import '../../filters/apply_enquiry_filters.dart';
import '../../filters/filters_state.dart';
import 'enquiry_details_screen.dart';

// ── Column definitions ────────────────────────────────────────────────────────

class _KanbanColumn {
  const _KanbanColumn({
    required this.status,
    required this.label,
    required this.icon,
  });
  final String status;
  final String label;
  final IconData icon;
}

IconData _iconForStatus(EnquiryStatus status) {
  switch (status) {
    case EnquiryStatus.newEnquiry:
      return Icons.fiber_new_outlined;
    case EnquiryStatus.contacted:
      return Icons.phone_outlined;
    case EnquiryStatus.inTalks:
      return Icons.forum_outlined;
    case EnquiryStatus.quoteSent:
      return Icons.description_outlined;
    case EnquiryStatus.approved:
      return Icons.check_circle_outline;
    case EnquiryStatus.scheduled:
      return Icons.event_outlined;
    case EnquiryStatus.completed:
      return Icons.done_all_outlined;
    case EnquiryStatus.notInterested:
      return Icons.block_outlined;
    case EnquiryStatus.closedLost:
      return Icons.thumb_down_outlined;
    case EnquiryStatus.cancelled:
      return Icons.cancel_outlined;
  }
}

List<_KanbanColumn> get _kColumns => EnquiryStatus.values
    .map(
      (s) => _KanbanColumn(
        status: s.value,
        label: s.label,
        icon: _iconForStatus(s),
      ),
    )
    .toList();

const double _kColumnWidth = 260.0;
const double _kColumnHeaderHeight = 52.0;
const double _kCardWidth = 244.0;

// ── Main screen ───────────────────────────────────────────────────────────────

class KanbanBoardScreen extends ConsumerStatefulWidget {
  const KanbanBoardScreen({
    super.key,
    this.embeddedInShell = false,
    this.filters,
  });

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
    final firestoreService = ref.watch(firestoreServiceProvider);

    return currentUser.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('Not logged in'));
        final isAdmin = user.role == UserRole.admin;

        return StreamBuilder<QuerySnapshot>(
          stream: firestoreService.watchEnquiriesForRole(
            isAdmin: isAdmin,
            assignedToUid: user.uid,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = (snapshot.data?.docs ?? []).where((doc) {
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
              final canonical =
                  EnquiryStatus.fromValue(rawStatus)?.value ?? 'new';
              if (buckets.containsKey(canonical)) {
                buckets[canonical]!.add(doc);
              }
            }

            // Sort each bucket by event date then created date
            for (final bucket in buckets.values) {
              bucket.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                DateTime? aDate = _ts(aData['eventDate']);
                DateTime? bDate = _ts(bData['eventDate']);
                if (aDate != null && bDate != null)
                  return aDate.compareTo(bDate);
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
                if (_hoverColumn != status)
                  setState(() => _hoverColumn = status);
              },
              onDragLeave: () {
                if (_hoverColumn != null) setState(() => _hoverColumn = null);
              },
              onDrop: (enquiryId, newStatus) async {
                setState(() => _hoverColumn = null);
                if (!isAdmin) {
                  final doc = docs.firstWhere((d) => d.id == enquiryId);
                  final data = doc.data() as Map<String, dynamic>;
                  final currentStatus = data['statusValue'] as String?;
                  if (!EnquiryStatus.isStaffTransitionAllowed(
                    currentStatus,
                    newStatus,
                  )) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This status change is not allowed'),
                        ),
                      );
                    }
                    return;
                  }
                }
                try {
                  // Use repository so audit history, statusLabel, notifications
                  // and legacy-field cleanup all happen — same as dashboard tabs.
                  await ref
                      .read(enquiryRepositoryProvider)
                      .updateStatus(
                        id: enquiryId,
                        nextStatus: newStatus,
                        userId: user.uid,
                      );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              },
              onTap: (enquiryId) => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => EnquiryDetailsScreen(enquiryId: enquiryId),
                ),
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
      padding: const EdgeInsets.all(AppTokens.space3),
      itemCount: columns.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space2),
      itemBuilder: (context, i) {
        final col = columns[i];
        return _ColumnWidget(
          column: col,
          cards: buckets[col.status] ?? [],
          isHovered: hoverColumn == col.status,
          dropdownLookup: dropdownLookup,
          onDragOver: () => onDragOver(col.status),
          onDragLeave: onDragLeave,
          onDrop: (id) => onDrop(id, col.status),
          onTap: onTap,
        );
      },
    );
  }
}

// ── Column widget ─────────────────────────────────────────────────────────────

class _ColumnWidget extends StatelessWidget {
  const _ColumnWidget({
    required this.column,
    required this.cards,
    required this.isHovered,
    required this.dropdownLookup,
    required this.onDragOver,
    required this.onDragLeave,
    required this.onDrop,
    required this.onTap,
  });

  final _KanbanColumn column;
  final List<QueryDocumentSnapshot> cards;
  final bool isHovered;
  final DropdownLookup? dropdownLookup;
  final VoidCallback onDragOver;
  final VoidCallback onDragLeave;
  final void Function(String enquiryId) onDrop;
  final void Function(String enquiryId) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = AppColorScheme.statusColorFor(column.status);

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        onDragOver();
        return true;
      },
      onLeave: (_) => onDragLeave(),
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, __) {
        final accepting = candidateData.isNotEmpty || isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _kColumnWidth,
          decoration: BoxDecoration(
            color: accepting
                ? statusColor.withValues(alpha: 0.08)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            border: Border.all(
              color: accepting ? statusColor : cs.outlineVariant,
              width: accepting ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _ColumnHeader(
                column: column,
                count: cards.length,
                statusColor: statusColor,
              ),
              const Divider(height: 1),
              // Cards
              Expanded(
                child: cards.isEmpty
                    ? _EmptyColumn(
                        accepting: accepting,
                        statusColor: statusColor,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTokens.space2),
                        itemCount: cards.length,
                        itemBuilder: (context, i) {
                          final doc = cards[i];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTokens.space2,
                            ),
                            child: _KanbanCard(
                              doc: doc,
                              statusColor: statusColor,
                              dropdownLookup: dropdownLookup,
                              onTap: () => onTap(doc.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Column header ─────────────────────────────────────────────────────────────

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.column,
    required this.count,
    required this.statusColor,
  });

  final _KanbanColumn column;
  final int count;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: _kColumnHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
        child: Row(
          children: [
            Icon(column.icon, size: 18, color: statusColor),
            const SizedBox(width: AppTokens.space2),
            Text(
              column.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty column placeholder ──────────────────────────────────────────────────

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.accepting, required this.statusColor});

  final bool accepting;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              accepting ? Icons.add_circle_outline : Icons.inbox_outlined,
              size: 32,
              color: accepting
                  ? statusColor
                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              accepting ? 'Drop here' : 'Empty',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accepting
                    ? statusColor
                    : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kanban card ───────────────────────────────────────────────────────────────

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.doc,
    required this.statusColor,
    required this.dropdownLookup,
    required this.onTap,
  });

  final QueryDocumentSnapshot doc;
  final Color statusColor;
  final DropdownLookup? dropdownLookup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final customerName = (data['customerName'] as String?) ?? 'Customer';
    final eventTypeValue =
        (data['eventTypeValue'] ?? data['eventType']) as String? ?? '';
    final eventTypeLabel =
        (data['eventTypeLabel'] as String?) ??
        (dropdownLookup?.labelForEventType(eventTypeValue) ??
            _titleCase(eventTypeValue));
    final location = (data['eventLocation'] ?? data['location']) as String?;
    final eventDate = _ts(data['eventDate']);
    final createdAt = _ts(data['createdAt']) ?? DateTime.now();
    final countdown = _countdownLabel(eventDate);
    final ageLabel = _ageLabel(createdAt);
    final phone = data['customerPhone'] as String?;

    final card = Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status strip
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTokens.radiusSmall),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.space2 + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + event type
                  Text(
                    customerName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.celebration_outlined,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          eventTypeLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTokens.space2),
                  // Bottom row: event countdown + age
                  Row(
                    children: [
                      if (countdown != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            countdown,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const Spacer(),
                      ],
                      if (phone != null)
                        Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      const Spacer(),
                      Text(
                        ageLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap in LongPressDraggable
    return LongPressDraggable<String>(
      data: doc.id,
      hapticFeedbackOnStart: true,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: SizedBox(
          width: _kCardWidth,
          child: Opacity(opacity: 0.9, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }

  DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String? _countdownLabel(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final days = eventDay.difference(today).inDays;
    if (days > 1) return 'In $days days';
    if (days == 1) return 'Tomorrow';
    if (days == 0) return 'Today';
    if (days == -1) return '1 day ago';
    return '${days.abs()}d ago';
  }

  String _ageLabel(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inHours < 24) return '${age.inHours}h old';
    if (age.inDays < 7) return '${age.inDays}d old';
    final weeks = age.inDays ~/ 7;
    if (weeks < 5) return '${weeks}w old';
    return '${age.inDays ~/ 30}mo old';
  }

  String _titleCase(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1).replaceAll('_', ' ');
  }
}
