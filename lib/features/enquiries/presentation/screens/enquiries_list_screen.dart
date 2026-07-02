import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/csv_export.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/enquiry_pagination_provider.dart';
import '../../filters/apply_enquiry_filters.dart';
import '../../filters/filters_controller.dart';
import '../../filters/filters_state.dart';
import '../../filters/widgets/filters_bar.dart';
import '../../filters/widgets/saved_views_sheet.dart';
import '../widgets/enquiry_list_item.dart';
import 'enquiry_form_screen.dart';
import 'kanban_board_screen.dart';

enum _EnquiriesView { list, board }

class EnquiriesListScreen extends ConsumerStatefulWidget {
  const EnquiriesListScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<EnquiriesListScreen> createState() =>
      _EnquiriesListScreenState();
}

class _EnquiriesListScreenState extends ConsumerState<EnquiriesListScreen> {
  _EnquiriesView _view = _EnquiriesView.list;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final userRole = currentUser.value?.role;

    final body = currentUser.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in to view enquiries'));
        }

        final dropdownLookup = ref
            .watch(dropdownLookupProvider)
            .maybeWhen(data: (value) => value, orElse: () => null);
        final filters = ref.watch(enquiryFiltersProvider);
        final firestoreService = ref.watch(firestoreServiceProvider);

        if (_view == _EnquiriesView.board) {
          return Column(
            children: [
              if (widget.embeddedInShell)
                _buildShellToolbar(context, userRole, user.uid),
              Expanded(
                child: KanbanBoardScreen(
                  embeddedInShell: true,
                  filters: filters,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            if (widget.embeddedInShell)
              _buildShellToolbar(context, userRole, user.uid),
            FiltersBar(
              onClearFilters: () =>
                  ref.read(enquiryFiltersProvider.notifier).clearFilters(),
            ),
            if (filters.searchQuery?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('Search: ${filters.searchQuery}'),
                    onDeleted: () => ref
                        .read(enquiryFiltersProvider.notifier)
                        .updateSearchQuery(null),
                  ),
                ),
              ),
            Expanded(
              child: (filters.searchQuery?.isNotEmpty ?? false)
                  ? _EnquiriesStreamList(
                      firestoreService: firestoreService,
                      isAdmin: userRole == UserRole.admin,
                      userUid: user.uid,
                      userRole: userRole,
                      filters: filters,
                      dropdownLookup: dropdownLookup,
                      onClearFilters: () => ref
                          .read(enquiryFiltersProvider.notifier)
                          .clearFilters(),
                    )
                  : _EnquiriesPaginatedList(
                      key: ValueKey(
                        'paginated-${filters.statuses.length == 1 ? filters.statuses.first : 'all'}',
                      ),
                      userRole: userRole,
                      userUid: user.uid,
                      filters: filters,
                      dropdownLookup: dropdownLookup,
                      onClearFilters: () => ref
                          .read(enquiryFiltersProvider.notifier)
                          .clearFilters(),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading user data: $error')),
    );

    if (widget.embeddedInShell) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          userRole == UserRole.admin ? 'All Enquiries' : 'My Enquiries',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () => _showFiltersSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(
              context,
              ref,
              action,
              userRole,
              currentUser.value?.uid,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (userRole == UserRole.admin)
                const PopupMenuItem(
                  value: 'add',
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Add Enquiry'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildShellToolbar(
    BuildContext context,
    UserRole? userRole,
    String userId,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          SegmentedButton<_EnquiriesView>(
            segments: const [
              ButtonSegment(
                value: _EnquiriesView.list,
                label: Text('List'),
                icon: Icon(Icons.list, size: 18),
              ),
              ButtonSegment(
                value: _EnquiriesView.board,
                label: Text('Board'),
                icon: Icon(Icons.view_kanban, size: 18),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (selection) {
              setState(() => _view = selection.first);
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () => _showFiltersSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (action) =>
                _handleAction(context, ref, action, userRole, userId),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter Enquiries',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const QuickFilters(),
              const FilterSummary(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showSavedViewsSheet(sheetContext);
                },
                icon: const Icon(Icons.bookmark_outline),
                label: const Text('Saved views'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    UserRole? userRole,
    String? userId,
  ) {
    switch (action) {
      case 'export':
        _exportEnquiries(context, ref);
        break;
      case 'add':
        if (userRole != UserRole.admin) return;
        Navigator.of(context)
            .push<void>(
              MaterialPageRoute<void>(
                builder: (context) => const EnquiryFormScreen(),
              ),
            )
            .then((_) {
              if (_view == _EnquiriesView.list) {
                final filters = ref.read(enquiryFiltersProvider);
                if (filters.searchQuery?.isNotEmpty ?? false) return;
                final status = filters.statuses.length == 1
                    ? filters.statuses.first
                    : null;
                ref
                    .read(
                      paginatedEnquiriesProvider(
                        PaginationParams(status: status),
                      ).notifier,
                    )
                    .refresh();
              }
            });
        break;
    }
  }

  Future<void> _exportEnquiries(BuildContext context, WidgetRef ref) async {
    try {
      final userRole = ref.read(currentUserWithFirestoreProvider).value?.role;
      final userId = ref.read(currentUserWithFirestoreProvider).value?.uid;
      final firestoreService = ref.read(firestoreServiceProvider);

      // Show loading indicator
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting enquiries...'),
            ],
          ),
        ),
      );

      final snapshot = await firestoreService.fetchEnquiriesForRole(
        isAdmin: userRole == UserRole.admin,
        assignedToUid: userId,
      );
      final enquiries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (enquiries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No enquiries to export'),
              backgroundColor: AppColorScheme.snackWarning,
            ),
          );
        }
        return;
      }

      // Export to CSV with role-based filtering
      await CsvExport.exportEnquiries(enquiries, ref);

      if (context.mounted) {
        CsvExport.showExportSuccess(
          context,
          'enquiries_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        CsvExport.showExportError(context, e.toString());
      }
    }
  }
}

class _EnquiriesStreamList extends StatelessWidget {
  const _EnquiriesStreamList({
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
      stream: firestoreService.watchEnquiriesForRole(
        isAdmin: isAdmin,
        assignedToUid: userUid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EnquiriesEmptyState(
            userRole: userRole,
            filters: filters,
            onClearFilters: onClearFilters,
          );
        }

        final enquiries = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return matchesEnquiryFilters(data, filters, currentUserId: userUid);
        }).toList();

        if (enquiries.isEmpty) {
          return _EnquiriesEmptyState(
            userRole: userRole,
            filters: filters,
            onClearFilters: onClearFilters,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: enquiries.length,
          itemBuilder: (context, index) {
            final enquiry = enquiries[index];
            final enquiryData = enquiry.data() as Map<String, dynamic>;
            final assignedTo = enquiryData['assignedTo'] as String?;

            return EnquiryListItem(
              enquiryId: enquiry.id,
              data: enquiryData,
              dropdownLookup: dropdownLookup,
              showAssignee: userRole == UserRole.admin && assignedTo != null,
            );
          },
        );
      },
    );
  }
}

class _EnquiriesPaginatedList extends ConsumerStatefulWidget {
  const _EnquiriesPaginatedList({
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
  ConsumerState<_EnquiriesPaginatedList> createState() =>
      _EnquiriesPaginatedListState();
}

class _EnquiriesPaginatedListState
    extends ConsumerState<_EnquiriesPaginatedList> {
  late final ScrollController _scrollController;

  PaginationParams get _params => PaginationParams(
    status: widget.filters.statuses.length == 1
        ? widget.filters.statuses.first
        : null,
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadFirstPageIfNeeded(),
    );
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
      return Center(child: Text('Error: ${pagination.error}'));
    }

    if (pagination.isLoading && pagination.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final enquiries = pagination.documents.where((doc) {
      final data = doc.data();
      return matchesEnquiryFilters(
        data,
        widget.filters,
        currentUserId: widget.userUid,
      );
    }).toList();

    if (enquiries.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(paginatedEnquiriesProvider(_params).notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: _EnquiriesEmptyState(
                userRole: widget.userRole,
                filters: widget.filters,
                onClearFilters: widget.onClearFilters,
              ),
            ),
          ],
        ),
      );
    }

    final showBottomLoader = pagination.isLoadingMore && pagination.hasMore;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paginatedEnquiriesProvider(_params).notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: enquiries.length + (showBottomLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (showBottomLoader && index == enquiries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final enquiry = enquiries[index];
          final enquiryData = enquiry.data();
          final assignedTo = enquiryData['assignedTo'] as String?;

          return EnquiryListItem(
            enquiryId: enquiry.id,
            data: enquiryData,
            dropdownLookup: widget.dropdownLookup,
            showAssignee:
                widget.userRole == UserRole.admin && assignedTo != null,
            onReturnFromDetail: _refreshPagination,
          );
        },
      ),
    );
  }
}

class _EnquiriesEmptyState extends StatelessWidget {
  const _EnquiriesEmptyState({
    required this.userRole,
    required this.filters,
    required this.onClearFilters,
  });

  final UserRole? userRole;
  final EnquiryFilters filters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasFilters = filters.hasActiveFilters;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters
                ? Icons.filter_list_off
                : (userRole == UserRole.admin ? Icons.inbox : Icons.assignment),
            size: 64,
            color: mutedColor,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No enquiries match your filters'
                : (userRole == UserRole.admin
                      ? 'No enquiries found'
                      : 'No enquiries assigned to you'),
            style: TextStyle(fontSize: 18, color: mutedColor),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}
