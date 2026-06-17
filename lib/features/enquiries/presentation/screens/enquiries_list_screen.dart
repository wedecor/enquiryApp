import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/csv_export.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../filters/apply_enquiry_filters.dart';
import '../../filters/filters_controller.dart';
import '../../filters/filters_state.dart';
import '../../filters/widgets/filters_bar.dart';
import '../../filters/widgets/saved_views_sheet.dart';
import 'enquiry_details_screen.dart';
import 'enquiry_form_screen.dart';

class EnquiriesListScreen extends ConsumerStatefulWidget {
  const EnquiriesListScreen({super.key});

  @override
  ConsumerState<EnquiriesListScreen> createState() => _EnquiriesListScreenState();
}

class _EnquiriesListScreenState extends ConsumerState<EnquiriesListScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final userRole = currentUser.value?.role;

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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
      body: currentUser.when(
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              userRole == UserRole.admin ? Icons.inbox : Icons.assignment,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              userRole == UserRole.admin
                                  ? 'No enquiries found'
                                  : 'No enquiries assigned to you',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              filters.hasActiveFilters ? Icons.filter_list_off : Icons.inbox,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              filters.hasActiveFilters
                                  ? 'No enquiries match your filters'
                                  : (userRole == UserRole.admin
                                        ? 'No enquiries found'
                                        : 'No enquiries assigned to you'),
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
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

                        final statusValueRaw =
                            enquiryData['statusValue'] as String?; // Only use statusValue
                        final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
                            ? statusValueRaw!.trim()
                            : 'new';
                        final statusLabel =
                            (enquiryData['statusLabel'] as String?) ??
                            (dropdownLookup != null
                                ? dropdownLookup.labelForStatus(statusValue)
                                : DropdownLookup.titleCase(statusValue));
                        final eventTypeValueRaw =
                            (enquiryData['eventTypeValue'] ?? enquiryData['eventType']) as String?;
                        final eventTypeValue = (eventTypeValueRaw?.trim().isNotEmpty ?? false)
                            ? eventTypeValueRaw!.trim()
                            : 'event';
                        final eventTypeLabel =
                            (enquiryData['eventTypeLabel'] as String?) ??
                            (dropdownLookup != null
                                ? dropdownLookup.labelForEventType(eventTypeValue)
                                : DropdownLookup.titleCase(eventTypeValue));
                        final priorityValueRaw =
                            (enquiryData['priorityValue'] ?? enquiryData['priority']) as String?;
                        final priorityValue = (priorityValueRaw?.trim().isNotEmpty ?? false)
                            ? priorityValueRaw!.trim()
                            : null;
                        final priorityLabel =
                            (enquiryData['priorityLabel'] as String?) ??
                            (priorityValue != null
                                ? (dropdownLookup != null
                                      ? dropdownLookup.labelForPriority(priorityValue)
                                      : DropdownLookup.titleCase(priorityValue))
                                : 'N/A');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(context, statusValue),
                              child: Text(
                                _getStatusInitial(statusLabel),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              (enquiryData['customerName'] as String?) ?? 'Unknown Customer',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(eventTypeLabel),
                                Text(
                                  'Date: ${_formatDate(enquiryData['eventDate'])}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (userRole == UserRole.admin &&
                                    enquiryData['assignedTo'] != null) ...[
                                  Text(
                                    'Assigned: ${_getAssignedUserName(enquiryData['assignedTo'] as String)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priorityValue),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    priorityLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Edit button for admin users
                                if (userRole == UserRole.admin) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (context) =>
                                              EnquiryFormScreen(enquiryId: enquiryId, mode: 'edit'),
                                        ),
                                      );
                                    },
                                    tooltip: 'Edit Enquiry',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId),
                                ),
                              );
                            },
                          ),
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _getStatusInitial(String? status) {
    if (status == null) return '?';
    return status[0].toUpperCase();
  }

  Color _getStatusColor(BuildContext context, String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Theme.of(context).colorScheme.primary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
        ).push(MaterialPageRoute(builder: (context) => const EnquiryFormScreen()));
        break;
    }
  }

  Future<void> _exportEnquiries(BuildContext context, WidgetRef ref) async {
    try {
      final userRole = ref.read(currentUserWithFirestoreProvider).value?.role;
      final userId = ref.read(currentUserWithFirestoreProvider).value?.uid;
      final firestoreService = ref.read(firestoreServiceProvider);

      // Show loading indicator
      showDialog(
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
            const SnackBar(content: Text('No enquiries to export'), backgroundColor: Colors.orange),
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
