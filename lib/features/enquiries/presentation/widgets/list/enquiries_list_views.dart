import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/firestore_service.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/utils/status_colors.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../data/enquiry_pagination_provider.dart';
import '../../../filters/apply_enquiry_filters.dart';
import '../../../filters/filters_controller.dart';
import '../../../filters/filters_state.dart';
import '../enquiry_list_item.dart';

/// Leaves room for the floating nav pill and FAB below the last row.
const EdgeInsets _kListPadding = EdgeInsets.only(top: AppTokens.space1, bottom: 96);

/// Live (non-paginated) list used while a search query is active.
class EnquiriesStreamList extends StatelessWidget {
  const EnquiriesStreamList({
    super.key,
    required this.firestoreService,
    required this.isAdmin,
    required this.userUid,
    required this.userRole,
    required this.filters,
    required this.dropdownLookup,
    required this.onClearFilters,
  });

  final FirestoreService firestoreService;
  final bool isAdmin;
  final String userUid;
  final UserRole? userRole;
  final EnquiryFilters filters;
  final DropdownLookup? dropdownLookup;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.watchEnquiriesForRole(isAdmin: isAdmin, assignedToUid: userUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Couldn\'t load enquiries.\nPlease check your connection and try again.',
            error: snapshot.error,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final empty = EnquiriesListEmpty(
          userRole: userRole,
          filters: filters,
          onClearFilters: onClearFilters,
        );
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return empty;

        final enquiries = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return matchesEnquiryFilters(data, filters, currentUserId: userUid);
        }).toList();

        if (enquiries.isEmpty) return empty;

        final dataList = [for (final e in enquiries) e.data() as Map<String, dynamic>];
        return ListView.builder(
          padding: _kListPadding,
          itemCount: enquiries.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ResultCountHeader(
                count: enquiries.length,
                eyebrow: 'Matches',
                statuses: [for (final d in dataList) d['statusValue'] as String?],
                dropdownLookup: dropdownLookup,
              );
            }
            final i = index - 1;
            final enquiryData = dataList[i];
            final assignedTo = enquiryData['assignedTo'] as String?;

            return StaggerIn(
              index: i,
              child: EnquiryListItem(
                enquiryId: enquiries[i].id,
                data: enquiryData,
                dropdownLookup: dropdownLookup,
                showAssignee: userRole == UserRole.admin && assignedTo != null,
              ),
            );
          },
        );
      },
    );
  }
}

/// Paginated list with infinite scroll and pull-to-refresh.
class EnquiriesPaginatedList extends ConsumerStatefulWidget {
  const EnquiriesPaginatedList({
    super.key,
    required this.userRole,
    required this.userUid,
    required this.filters,
    required this.dropdownLookup,
    required this.onClearFilters,
  });

  final UserRole? userRole;
  final String userUid;
  final EnquiryFilters filters;
  final DropdownLookup? dropdownLookup;
  final VoidCallback onClearFilters;

  @override
  ConsumerState<EnquiriesPaginatedList> createState() => _EnquiriesPaginatedListState();
}

class _EnquiriesPaginatedListState extends ConsumerState<EnquiriesPaginatedList> {
  late final ScrollController _scrollController;

  PaginationParams get _params => PaginationParams(
    status: widget.filters.statuses.length == 1 ? widget.filters.statuses.first : null,
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPageIfNeeded());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFirstPageIfNeeded() {
    final state = ref.read(paginatedEnquiriesProvider(_params));
    if (state.documents.isEmpty && !state.isLoading && state.error == null) {
      ref.read(paginatedEnquiriesProvider(_params).notifier).loadFirstPage();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(paginatedEnquiriesProvider(_params).notifier).loadMore();
    }
  }

  void _refreshPagination() {
    ref.read(paginatedEnquiriesProvider(_params).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EnquiryFilters>(enquiryFiltersProvider, (previous, next) {
      if (next.searchQuery?.isNotEmpty ?? false) return;
      if (previous == next) return;
      _refreshPagination();
    });

    final pagination = ref.watch(paginatedEnquiriesProvider(_params));

    if (pagination.error != null && pagination.documents.isEmpty) {
      return ErrorState(
        message: 'Couldn\'t load enquiries.\nPlease check your connection and try again.',
        error: pagination.error,
        onRetry: _refreshPagination,
      );
    }

    if (pagination.isLoading && pagination.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final enquiries = pagination.documents.where((doc) {
      final data = doc.data();
      return matchesEnquiryFilters(data, widget.filters, currentUserId: widget.userUid);
    }).toList();

    if (enquiries.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(paginatedEnquiriesProvider(_params).notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: AppTokens.space8, bottom: 96),
          children: [
            EnquiriesListEmpty(
              userRole: widget.userRole,
              filters: widget.filters,
              onClearFilters: widget.onClearFilters,
            ),
          ],
        ),
      );
    }

    final showBottomLoader = pagination.isLoadingMore && pagination.hasMore;

    return RefreshIndicator(
      onRefresh: () => ref.read(paginatedEnquiriesProvider(_params).notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _kListPadding,
        itemCount: enquiries.length + 1 + (showBottomLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ResultCountHeader(
              count: enquiries.length,
              hasMore: pagination.hasMore,
              statuses: [for (final d in enquiries) d.data()['statusValue'] as String?],
              dropdownLookup: widget.dropdownLookup,
            );
          }
          final i = index - 1;
          if (showBottomLoader && i == enquiries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.space4),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final enquiry = enquiries[i];
          final enquiryData = enquiry.data();
          final assignedTo = enquiryData['assignedTo'] as String?;

          return StaggerIn(
            index: i,
            child: EnquiryListItem(
              enquiryId: enquiry.id,
              data: enquiryData,
              dropdownLookup: widget.dropdownLookup,
              showAssignee: widget.userRole == UserRole.admin && assignedTo != null,
              onReturnFromDetail: _refreshPagination,
            ),
          );
        },
      ),
    );
  }
}

/// "RESULTS / 24 enquiries" with a hairline strip of the status mix.
class ResultCountHeader extends StatelessWidget {
  const ResultCountHeader({
    super.key,
    required this.count,
    required this.statuses,
    this.hasMore = false,
    this.eyebrow = 'Results',
    this.dropdownLookup,
  });

  final int count;
  final List<String?> statuses;
  final bool hasMore;
  final String eyebrow;
  final DropdownLookup? dropdownLookup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = <String, int>{};
    for (final raw in statuses) {
      final key = (raw?.trim().isNotEmpty ?? false) ? raw!.trim().toLowerCase() : 'new';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final segments = [
      for (final entry in counts.entries)
        (
          entry.value.toDouble(),
          resolveStatusColor(context, entry.key, firestoreColors: dropdownLookup?.statusColorMap),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space2,
        AppTokens.space5,
        AppTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(hasMore ? '$eyebrow · loaded so far' : eyebrow),
          const SizedBox(height: AppTokens.space1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$count${hasMore ? '+' : ''}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: count == 1 ? '  enquiry' : '  enquiries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (segments.length > 1) ...[
            const SizedBox(height: AppTokens.space3),
            ProportionStrip(segments: segments, height: 4),
          ],
        ],
      ),
    );
  }
}

/// Role- and filter-aware empty state for the enquiries list.
class EnquiriesListEmpty extends StatelessWidget {
  const EnquiriesListEmpty({
    super.key,
    required this.userRole,
    required this.filters,
    required this.onClearFilters,
  });

  final UserRole? userRole;
  final EnquiryFilters filters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final hasFilters = filters.hasActiveFilters;
    final isAdmin = userRole == UserRole.admin;

    return EmptyState(
      icon: hasFilters
          ? Icons.filter_list_off
          : (isAdmin ? Icons.inbox_outlined : Icons.assignment_outlined),
      eyebrow: hasFilters ? 'No matches' : (isAdmin ? 'Pipeline' : 'Your desk'),
      message: hasFilters
          ? 'No enquiries match your filters'
          : (isAdmin ? 'No enquiries found' : 'No enquiries assigned to you'),
      action: hasFilters ? onClearFilters : null,
      actionText: hasFilters ? 'Clear filters' : null,
    );
  }
}
