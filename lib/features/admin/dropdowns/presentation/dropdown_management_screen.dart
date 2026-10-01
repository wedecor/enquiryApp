import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/shell_widgets.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/components/glass_page_scaffold.dart';
import '../../../../ui/components/glass_segmented_tabs.dart';
import '../../../../ui/components/glass_state_message.dart';
import '../../../../ui/components/gradient_pill_button.dart';
import '../domain/dropdown_item.dart';
import 'dropdown_form_dialog.dart';
import 'dropdown_providers.dart';
import 'widgets/dropdown_item_tile.dart';

/// Main screen for managing dropdown items
class DropdownManagementScreen extends ConsumerStatefulWidget {
  const DropdownManagementScreen({super.key});

  @override
  ConsumerState<DropdownManagementScreen> createState() => _DropdownManagementScreenState();
}

class _DropdownManagementScreenState extends ConsumerState<DropdownManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: DropdownGroup.values.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final group = DropdownGroup.values[_tabController.index];
      ref.read(dropdownGroupProvider.notifier).setGroup(group);
    }
  }

  void _onSearchChanged() {
    ref.read(dropdownQueryProvider.notifier).setQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final currentGroup = ref.watch(dropdownGroupProvider);
    final roleAsync = ref.watch(roleProvider);
    final isAdmin = roleAsync.valueOrNull == UserRole.admin;

    return GlassPageScaffold(
      eyebrow: 'Admin',
      title: 'Dropdown Management',
      actions: [
        ShellIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: () {
            ref.invalidate(filteredDropdownsProvider);
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space3,
              AppTokens.space4,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                // Statuses are a fixed workflow: admins edit labels/colours, never add.
                if (isAdmin && currentGroup != DropdownGroup.statuses) ...[
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    flex: 2,
                    child: GradientPillButton(
                      label: 'Add Item',
                      icon: Icons.add_rounded,
                      height: AppTokens.minTapTarget,
                      onPressed: () => _showAddDialog(context, currentGroup),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space3,
              AppTokens.space4,
              AppTokens.space1,
            ),
            child: GlassSegmentedTabs(
              controller: _tabController,
              minSegmentWidth: 140,
              segments: [
                for (final group in DropdownGroup.values)
                  GlassSegment(group.displayName, icon: dropdownGroupIcon(group)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: DropdownGroup.values.map((group) => _buildGroupContent(group)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContent(DropdownGroup group) {
    final roleAsync = ref.watch(roleProvider);
    final isAdmin = roleAsync.when(
      data: (role) => role == UserRole.admin,
      loading: () => false,
      error: (_, _) => false,
    );
    final dropdownsAsync = ref.watch(filteredDropdownsProvider(group));

    return dropdownsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Column(
            children: [
              _buildGroupStats(group),
              Expanded(child: _buildEmptyState(group, isAdmin)),
            ],
          );
        }
        return _buildDropdownsList(group, items, isAdmin);
      },
      loading: () => Column(
        children: [
          _buildGroupStats(group),
          const Expanded(child: GlassLoadingState()),
        ],
      ),
      error: (error, stack) => Column(
        children: [
          _buildGroupStats(group),
          Expanded(child: _buildErrorState(error)),
        ],
      ),
    );
  }

  Widget _buildGroupStats(DropdownGroup group) {
    final statsAsync = ref.watch(dropdownGroupStatsProvider(group));

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space4, AppTokens.space3, AppTokens.space4, 0),
      child: statsAsync.when(
        data: (stats) => DropdownGroupStats(
          total: stats['total']!,
          active: stats['active']!,
          inactive: stats['inactive']!,
        ),
        loading: () => const SizedBox(height: 80),
        error: (_, _) => const SizedBox(height: 80),
      ),
    );
  }

  Widget _buildEmptyState(DropdownGroup group, bool isAdmin) {
    return GlassStateMessage(
      icon: dropdownGroupIcon(group),
      title: 'No ${group.displayName.toLowerCase()} found',
      message: isAdmin && group != DropdownGroup.statuses
          ? 'Tap "Add Item" to create your first dropdown item'
          : 'Contact an administrator to add dropdown items',
    );
  }

  Widget _buildErrorState(Object error) {
    return GlassStateMessage(
      icon: Icons.error_outline_rounded,
      title: 'Error loading dropdowns',
      message: error.toString(),
      color: Theme.of(context).colorScheme.error,
      action: FilledButton.icon(
        onPressed: () {
          ref.invalidate(filteredDropdownsProvider);
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    );
  }

  Widget _buildDropdownsList(DropdownGroup group, List<DropdownItem> items, bool isAdmin) {
    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space4,
        0,
        AppTokens.space4,
        AppTokens.space8 + MediaQuery.paddingOf(context).bottom,
      ),
      header: Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.space3),
        child: _buildGroupStats(group),
      ),
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.02 * Curves.easeOut.transform(animation.value),
          child: Material(type: MaterialType.transparency, child: child),
        ),
        child: child,
      ),
      itemCount: items.length,
      onReorder: isAdmin
          ? (oldIndex, newIndex) => _onReorder(group, items, oldIndex, newIndex)
          : (_, _) {},
      itemBuilder: (context, index) {
        final item = items[index];
        return DropdownItemTile(
          key: ValueKey(item.value),
          item: item,
          index: index,
          isAdmin: isAdmin,
          onAction: (action) => _handleItemAction(action, group, item),
        );
      },
    );
  }

  Future<void> _onReorder(
    DropdownGroup group,
    List<DropdownItem> items,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedItems = List<DropdownItem>.from(items);
    final item = reorderedItems.removeAt(oldIndex);
    reorderedItems.insert(newIndex, item);

    final orderedValues = reorderedItems.map((item) => item.value).toList();

    try {
      await ref.read(dropdownFormControllerProvider.notifier).reorderItems(group, orderedValues);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items reordered successfully'),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering items: ${e.toString()}'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
      }
    }
  }

  Future<void> _handleItemAction(String action, DropdownGroup group, DropdownItem item) async {
    switch (action) {
      case 'edit':
        _showEditDialog(context, group, item);
        break;
      case 'activate':
      case 'deactivate':
        await _toggleActive(group, item);
        break;
      case 'replace':
        _showReplaceDialog(context, group, item);
        break;
      case 'delete':
        await _showDeleteDialog(context, group, item);
        break;
    }
  }

  void _showAddDialog(BuildContext context, DropdownGroup group) {
    showDialog<void>(
      context: context,
      builder: (context) => DropdownFormDialog(group: group),
    );
  }

  void _showEditDialog(BuildContext context, DropdownGroup group, DropdownItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => DropdownFormDialog(group: group, item: item),
    );
  }

  Future<void> _toggleActive(DropdownGroup group, DropdownItem item) async {
    try {
      await ref
          .read(dropdownFormControllerProvider.notifier)
          .toggleActive(group, item.value, !item.active);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.active ? 'Item deactivated successfully' : 'Item activated successfully',
            ),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
      }
    }
  }

  void _showReplaceDialog(BuildContext context, DropdownGroup group, DropdownItem item) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          DropdownReplaceDialog(group: group, oldValue: item.value, oldLabel: item.label),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    DropdownGroup group,
    DropdownItem item,
  ) async {
    final hasReferences = await ref.read(isDropdownReferencedProvider((group, item.value)).future);

    if (context.mounted) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) =>
              DropdownDeleteDialog(group: group, item: item, hasReferences: hasReferences),
        ),
      );
    }
  }
}
