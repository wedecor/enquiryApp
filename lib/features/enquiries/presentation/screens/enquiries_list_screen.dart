import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/csv_export.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../filters/filters_controller.dart';
import '../../filters/filters_state.dart';
import '../../filters/widgets/filters_bar.dart';
import '../../filters/widgets/saved_views_sheet.dart';
import '../widgets/list/enquiries_list_views.dart';
import '../widgets/list/enquiries_toolbar.dart';
import 'enquiry_form_screen.dart';
import 'kanban_board_screen.dart';

enum _EnquiriesView { list, board }

class EnquiriesListScreen extends ConsumerStatefulWidget {
  const EnquiriesListScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<EnquiriesListScreen> createState() => _EnquiriesListScreenState();
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
        void clearFilters() => ref.read(enquiryFiltersProvider.notifier).clearFilters();

        final Widget content;
        if (_view == _EnquiriesView.board) {
          content = KanbanBoardScreen(embeddedInShell: true, filters: filters);
        } else if (filters.searchQuery?.isNotEmpty ?? false) {
          content = EnquiriesStreamList(
            firestoreService: firestoreService,
            isAdmin: userRole == UserRole.admin,
            userUid: user.uid,
            userRole: userRole,
            filters: filters,
            dropdownLookup: dropdownLookup,
            onClearFilters: clearFilters,
          );
        } else {
          content = EnquiriesPaginatedList(
            key: ValueKey(
              'paginated-${filters.statuses.length == 1 ? filters.statuses.first : 'all'}',
            ),
            userRole: userRole,
            userUid: user.uid,
            filters: filters,
            dropdownLookup: dropdownLookup,
            onClearFilters: clearFilters,
          );
        }

        return Column(
          children: [
            if (widget.embeddedInShell) _buildShellToolbar(context, userRole, user.uid),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.space4,
                AppTokens.space1,
                AppTokens.space4,
                AppTokens.space1,
              ),
              child: EnquirySearchField(),
            ),
            FiltersBar(onClearFilters: clearFilters),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.standard),
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                layoutBuilder: (current, previous) =>
                    Stack(fit: StackFit.expand, children: [...previous, ?current]),
                child: KeyedSubtree(key: ValueKey(_view), child: content),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          ErrorState(message: 'Error loading user data.\nPlease try again.', error: error),
    );

    if (widget.embeddedInShell) {
      return body;
    }

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(userRole == UserRole.admin ? 'All Enquiries' : 'My Enquiries'),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
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
      ),
    );
  }

  Widget _buildShellToolbar(BuildContext context, UserRole? userRole, String userId) {
    final activeCount = ref.watch(enquiryFiltersProvider.select((f) => f.activeFilterCount));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: Row(
        children: [
          EnquiriesViewToggle(
            isBoard: _view == _EnquiriesView.board,
            onChanged: (board) =>
                setState(() => _view = board ? _EnquiriesView.board : _EnquiriesView.list),
          ),
          const Spacer(),
          GlassIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'Filters',
            badgeCount: activeCount,
            onTap: () => _showFiltersSheet(context),
          ),
          const SizedBox(width: AppTokens.space2),
          PressScale(
            pressedScale: 0.9,
            child: PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (action) => _handleAction(context, ref, action, userRole, userId),
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
              child: const GlassIconButton(icon: Icons.more_horiz_rounded, tooltip: 'More actions'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return GlassPanel(
          blur: true,
          strong: true,
          borderRadius: AppRadius.only(
            topLeft: AppTokens.radiusXXLarge,
            topRight: AppTokens.radiusXXLarge,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space5,
                AppTokens.space3,
                AppTokens.space5,
                AppTokens.space5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  const Eyebrow('Refine', accent: true),
                  const SizedBox(height: AppTokens.space1),
                  SplitHeading(
                    light: 'Filter',
                    bold: 'Enquiries',
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTokens.space2),
                  const QuickFilters(),
                  const FilterSummary(),
                  const SizedBox(height: AppTokens.space4),
                  PressScale(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        showSavedViewsSheet(context);
                      },
                      icon: const Icon(Icons.bookmark_outline),
                      label: const Text('Saved views'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _ExportProgressDialog(),
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

class _ExportProgressDialog extends StatelessWidget {
  const _ExportProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: GlassPanel(
        blur: true,
        strong: true,
        shadow: true,
        borderRadius: AppRadius.xLarge,
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: AppTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Eyebrow('Export', accent: true),
                  const SizedBox(height: 2),
                  Text(
                    'Exporting enquiries...',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
