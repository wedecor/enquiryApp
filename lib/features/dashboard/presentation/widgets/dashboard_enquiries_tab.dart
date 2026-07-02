import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/widgets/empty_state.dart';
import 'dashboard_empty_enquiries.dart';
import 'dashboard_enquiry_list_row.dart';
import 'dashboard_enquiry_tab_actions.dart';
import 'dashboard_enquiry_utils.dart';

export 'dashboard_enquiry_tab_actions.dart';

enum _SortMode { eventDateAsc, eventDateDesc, createdDesc, nameAz }

extension _SortModeLabel on _SortMode {
  String get label => switch (this) {
    _SortMode.eventDateAsc => 'Event date (soonest)',
    _SortMode.eventDateDesc => 'Event date (latest)',
    _SortMode.createdDesc => 'Newest first',
    _SortMode.nameAz => 'Name A→Z',
  };
}

/// Filtered enquiries list for a single dashboard status tab.
class DashboardEnquiriesTab extends ConsumerStatefulWidget {
  const DashboardEnquiriesTab({
    super.key,
    required this.status,
    required this.isAdmin,
    required this.userId,
    required this.searchQuery,
    required this.onClearSearch,
    required this.actions,
    required this.errorBuilder,
    required this.headerSlivers,
    this.onTabVisible,
  });

  final String status;
  final bool isAdmin;
  final String? userId;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final DashboardEnquiryTabActions actions;
  final Widget Function(BuildContext context, Object error) errorBuilder;
  final List<Widget> headerSlivers;
  final VoidCallback? onTabVisible;

  @override
  ConsumerState<DashboardEnquiriesTab> createState() =>
      _DashboardEnquiriesTabState();
}

class _DashboardEnquiriesTabState extends ConsumerState<DashboardEnquiriesTab> {
  _SortMode _sortMode = _SortMode.eventDateAsc;

  String get status => widget.status;
  String get searchQuery => widget.searchQuery;
  String? get userId => widget.userId;
  bool get isAdmin => widget.isAdmin;
  DashboardEnquiryTabActions get actions => widget.actions;
  VoidCallback get onClearSearch => widget.onClearSearch;
  Widget Function(BuildContext, Object) get errorBuilder => widget.errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (widget.onTabVisible != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onTabVisible!(),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .read(firestoreServiceProvider)
          .watchEnquiriesForRole(isAdmin: isAdmin, assignedToUid: userId),
      builder: (context, snapshot) {
        final contentSlivers = _buildContentSlivers(context, snapshot);

        return CustomScrollView(
          key: PageStorageKey<String>('dashboard-tab-$status'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [...widget.headerSlivers, ...contentSlivers],
        );
      },
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> snapshot,
  ) {
    if (snapshot.hasError) {
      return [_centeredContentSliver(errorBuilder(context, snapshot.error!))];
    }

    if (!snapshot.hasData) {
      return [_centeredContentSliver(const CircularProgressIndicator())];
    }

    final rawEnquiries = snapshot.data!.docs.toList();

    if (rawEnquiries.isEmpty) {
      return [
        _centeredContentSliver(
          DashboardEmptyEnquiries(
            status: status,
            searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
            onClearSearch: searchQuery.isNotEmpty ? onClearSearch : null,
          ),
        ),
      ];
    }

    final now = DateTime.now();
    final preFilteredEnquiries = _filterByTab(rawEnquiries, now);
    _applySort(preFilteredEnquiries, now);

    final filteredEnquiries = searchQuery.isEmpty
        ? preFilteredEnquiries
        : preFilteredEnquiries
              .where(
                (doc) => matchesEnquirySearchQuery(
                  doc.data() as Map<String, dynamic>,
                  searchQuery,
                ),
              )
              .toList(growable: false);

    if (searchQuery.isNotEmpty && filteredEnquiries.isEmpty) {
      return [
        _centeredContentSliver(
          SearchEmptyState(query: searchQuery, onClearSearch: onClearSearch),
        ),
      ];
    }

    if (filteredEnquiries.isEmpty) {
      return [_centeredContentSliver(DashboardEmptyEnquiries(status: status))];
    }

    final dropdownLookup = ref
        .watch(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final isReminderTab = status == 'reminders';

    return [
      SliverToBoxAdapter(
        child: _SortSummaryBar(
          count: filteredEnquiries.length,
          current: _sortMode,
          onSortSelected: (mode) => setState(() => _sortMode = mode),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space1,
          AppTokens.space4,
          0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => DashboardEnquiryListRow(
              enquiry: filteredEnquiries[index],
              actions: actions,
              dropdownLookup: dropdownLookup,
              isReminderTab: isReminderTab,
            ),
            childCount: filteredEnquiries.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space8)),
    ];
  }

  Widget _centeredContentSliver(Widget child) {
    return SliverToBoxAdapter(
      child: SizedBox(height: 240, child: Center(child: child)),
    );
  }

  List<QueryDocumentSnapshot<Object?>> _filterByTab(
    List<QueryDocumentSnapshot<Object?>> raw,
    DateTime now,
  ) {
    if (status == 'All') return raw;
    if (status == 'closed') {
      return raw
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return EnquiryStatus.isLost(data['statusValue'] as String?);
          })
          .toList(growable: false);
    }
    if (status == 'reminders') {
      return raw
          .where(
            (doc) =>
                shouldShowReminder(doc.data() as Map<String, dynamic>, now),
          )
          .toList(growable: false);
    }
    if (status == 'in_talks') {
      return raw
          .where(
            (doc) => shouldShowInTalks(doc.data() as Map<String, dynamic>, now),
          )
          .toList(growable: false);
    }
    if (status == 'approved') {
      return raw
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final statusValueRaw = data['statusValue'] as String?;
            final canonical =
                EnquiryStatus.fromValue(statusValueRaw)?.value ??
                (statusValueRaw?.trim().toLowerCase() ?? 'new');
            return canonical == 'approved';
          })
          .toList(growable: false);
    }
    return raw
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final statusValueRaw = data['statusValue'] as String?;
          final canonical =
              EnquiryStatus.fromValue(statusValueRaw)?.value ??
              (statusValueRaw?.trim().isNotEmpty ?? false
                  ? statusValueRaw!.trim().toLowerCase()
                  : 'new');
          return canonical == status.toLowerCase();
        })
        .toList(growable: false);
  }

  void _applySort(List<QueryDocumentSnapshot<Object?>> list, DateTime now) {
    switch (_sortMode) {
      case _SortMode.eventDateAsc:
        list.sort((a, b) => compareByNearestEventDate(a, b, now));
      case _SortMode.eventDateDesc:
        list.sort((a, b) => compareByEventDate(b, a));
      case _SortMode.createdDesc:
        list.sort((a, b) => compareByCreatedDate(b, a));
      case _SortMode.nameAz:
        list.sort((a, b) {
          final aName =
              ((a.data() as Map<String, dynamic>)['customerName'] as String? ??
                      '')
                  .toLowerCase();
          final bName =
              ((b.data() as Map<String, dynamic>)['customerName'] as String? ??
                      '')
                  .toLowerCase();
          return aName.compareTo(bName);
        });
    }
  }
}

class _SortSummaryBar extends StatelessWidget {
  const _SortSummaryBar({
    required this.count,
    required this.current,
    required this.onSortSelected,
  });

  final int count;
  final _SortMode current;
  final ValueChanged<_SortMode> onSortSelected;

  Future<void> _showSortSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selected = await showModalBottomSheet<_SortMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  AppTokens.space2,
                  AppTokens.space4,
                  AppTokens.space3,
                ),
                child: Text(
                  'Sort enquiries',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              ..._SortMode.values.map((mode) {
                final isSelected = mode == current;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  title: Text(mode.label),
                  onTap: () => Navigator.of(context).pop(mode),
                );
              }),
              const SizedBox(height: AppTokens.space2),
            ],
          ),
        );
      },
    );

    if (selected != null) onSortSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space3,
        AppTokens.space2,
        AppTokens.space2,
      ),
      child: Row(
        children: [
          Text(
            '$count result${count == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Sort enquiries',
            onPressed: () => _showSortSheet(context),
            icon: const Icon(Icons.sort_rounded),
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              foregroundColor: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
