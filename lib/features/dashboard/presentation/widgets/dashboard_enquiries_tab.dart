import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../ui/primitives/primitives.dart';
import 'dashboard_empty_enquiries.dart';
import 'dashboard_enquiry_list_row.dart';
import 'dashboard_enquiry_tab_actions.dart';
import 'dashboard_enquiry_utils.dart';
import 'dashboard_sort_bar.dart';

export 'dashboard_enquiry_tab_actions.dart';

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
  });

  final String status;
  final bool isAdmin;
  final String? userId;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final DashboardEnquiryTabActions actions;
  final Widget Function(BuildContext context, Object error) errorBuilder;
  final List<Widget> headerSlivers;

  @override
  ConsumerState<DashboardEnquiriesTab> createState() => _DashboardEnquiriesTabState();
}

class _DashboardEnquiriesTabState extends ConsumerState<DashboardEnquiriesTab> {
  /// Space kept free under the last row for the floating nav pill and FAB.
  static const double _bottomClearance = 96;
  static const int _staggeredRows = 10;

  DashboardSortMode _sortMode = DashboardSortMode.eventDateAsc;

  String get status => widget.status;
  String get searchQuery => widget.searchQuery;
  String? get userId => widget.userId;
  bool get isAdmin => widget.isAdmin;
  DashboardEnquiryTabActions get actions => widget.actions;
  VoidCallback get onClearSearch => widget.onClearSearch;
  Widget Function(BuildContext, Object) get errorBuilder => widget.errorBuilder;

  @override
  Widget build(BuildContext context) {
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

  List<Widget> _buildContentSlivers(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                (doc) => matchesEnquirySearchQuery(doc.data() as Map<String, dynamic>, searchQuery),
              )
              .toList(growable: false);

    if (searchQuery.isNotEmpty && filteredEnquiries.isEmpty) {
      return [
        _centeredContentSliver(
          DashboardEmptyEnquiries(
            status: status,
            searchQuery: searchQuery,
            onClearSearch: onClearSearch,
          ),
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
        child: DashboardSortBar(
          count: filteredEnquiries.length,
          current: _sortMode,
          onSortSelected: (mode) => setState(() => _sortMode = mode),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final row = DashboardEnquiryListRow(
            enquiry: filteredEnquiries[index],
            actions: actions,
            dropdownLookup: dropdownLookup,
            isReminderTab: isReminderTab,
            showStatus: isReminderTab || status == 'closed' || status == 'All',
          );
          // Only the first screenful cascades in; rows built later while
          // scrolling appear immediately.
          return index < _staggeredRows ? StaggerIn(index: index, child: row) : row;
        }, childCount: filteredEnquiries.length),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: _bottomClearance)),
    ];
  }

  Widget _centeredContentSliver(Widget child) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: AppTokens.space6, bottom: _bottomClearance),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 240),
          child: Center(child: child),
        ),
      ),
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
          .where((doc) => shouldShowReminder(doc.data() as Map<String, dynamic>, now))
          .toList(growable: false);
    }
    if (status == 'in_talks') {
      return raw
          .where((doc) => shouldShowInTalks(doc.data() as Map<String, dynamic>))
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
      case DashboardSortMode.eventDateAsc:
        list.sort((a, b) => compareByNearestEventDate(a, b, now));
      case DashboardSortMode.eventDateDesc:
        list.sort((a, b) => compareByEventDate(b, a));
      case DashboardSortMode.createdDesc:
        list.sort((a, b) => compareByCreatedDate(b, a));
      case DashboardSortMode.nameAz:
        list.sort((a, b) {
          final aName = ((a.data() as Map<String, dynamic>)['customerName'] as String? ?? '')
              .toLowerCase();
          final bName = ((b.data() as Map<String, dynamic>)['customerName'] as String? ?? '')
              .toLowerCase();
          return aName.compareTo(bName);
        });
    }
  }
}
