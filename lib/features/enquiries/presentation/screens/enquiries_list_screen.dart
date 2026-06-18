import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/csv_export.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../filters/apply_enquiry_filters.dart';
import '../../filters/filters_controller.dart';
import '../../filters/filters_state.dart';
import '../../filters/widgets/filters_bar.dart';
import '../../filters/widgets/saved_views_sheet.dart';
import '../widgets/enquiry_list_item.dart';
import 'enquiry_form_screen.dart';

class EnquiriesListScreen extends ConsumerStatefulWidget {
  const EnquiriesListScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<EnquiriesListScreen> createState() => _EnquiriesListScreenState();
}

class _EnquiriesListScreenState extends ConsumerState<EnquiriesListScreen> {
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

        return Column(
          children: [
            if (widget.embeddedInShell)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      userRole == UserRole.admin ? 'All Enquiries' : 'My Enquiries',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filters',
                      onPressed: () => _showFiltersSheet(context),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) =>
                          _handleAction(context, ref, action, userRole, user.uid),
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
              ),
            FiltersBar(
              onClearFilters: () => ref.read(enquiryFiltersProvider.notifier).clearFilters(),
            ),
              if (filters.searchQuery?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text('Search: ${filters.searchQuery}'),
                      onDeleted: () =>
                          ref.read(enquiryFiltersProvider.notifier).updateSearchQuery(null),
                    ),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.watchEnquiriesForRole(
                    isAdmin: userRole == UserRole.admin,
                    assignedToUid: user.uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              userRole == UserRole.admin ? Icons.inbox : Icons.assignment,
                              size: 64,
                              color: mutedColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              userRole == UserRole.admin
                                  ? 'No enquiries found'
                                  : 'No enquiries assigned to you',
                              style: TextStyle(fontSize: 18, color: mutedColor),
                            ),
                          ],
                        ),
                      );
                    }

                    final enquiries = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return matchesEnquiryFilters(data, filters, currentUserId: user.uid);
                    }).toList();

                    if (enquiries.isEmpty) {
                      final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              filters.hasActiveFilters ? Icons.filter_list_off : Icons.inbox,
                              size: 64,
                              color: mutedColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              filters.hasActiveFilters
                                  ? 'No enquiries match your filters'
                                  : (userRole == UserRole.admin
                                        ? 'No enquiries found'
                                        : 'No enquiries assigned to you'),
                              style: TextStyle(fontSize: 18, color: mutedColor),
                            ),
                            if (filters.hasActiveFilters) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () =>
                                    ref.read(enquiryFiltersProvider.notifier).clearFilters(),
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // Debug: Log the count
                    if (kDebugMode) {
                      print('Enquiries count: ${enquiries.length}');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: enquiries.length,
                      itemBuilder: (context, index) {
                        final enquiry = enquiries[index];
                        final enquiryData = enquiry.data() as Map<String, dynamic>;
                        final enquiryId = enquiry.id;
                        final assignedTo = enquiryData['assignedTo'] as String?;

                        return EnquiryListItem(
                          enquiryId: enquiryId,
                          data: enquiryData,
                          dropdownLookup: dropdownLookup,
                          showAssignee:
                              userRole == UserRole.admin && assignedTo != null,
                          assigneeLabel: _getAssignedUserName(assignedTo),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading user data: $error')),
      );

    if (widget.embeddedInShell) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(userRole == UserRole.admin ? 'All Enquiries' : 'My Enquiries'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () => _showFiltersSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (action) =>
                _handleAction(context, ref, action, userRole, currentUser.value?.uid),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
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
              Text('Filter Enquiries', style: Theme.of(sheetContext).textTheme.titleLarge),
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

  String _getAssignedUserName(String? assignedTo) {
    if (assignedTo == null) return 'Unassigned';
    // TODO: Fetch user name from Firestore
    return 'User ID: $assignedTo';
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
        Navigator.of(
          context,
        ).push<void>(MaterialPageRoute<void>(builder: (context) => const EnquiryFormScreen()));
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
