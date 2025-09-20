import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dropdown_item.dart';
import 'dropdown_form_dialog.dart';
import 'dropdown_providers.dart';

/// Main screen for managing dropdown items
class DropdownManagementScreen extends ConsumerStatefulWidget {
  const DropdownManagementScreen({super.key});

  @override
  ConsumerState<DropdownManagementScreen> createState() =>
      _DropdownManagementScreenState();
}

class _DropdownManagementScreenState
    extends ConsumerState<DropdownManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: DropdownGroup.values.length,
      vsync: this,
    );
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
    final isAdmin = ref.watch(isDropdownAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dropdown Management'),
        actions: [
          // Search field
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),

          // Add button (admin only)
          if (isAdmin)
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, currentGroup),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),

          const SizedBox(width: 8),

          // Refresh button
          IconButton(
            onPressed: () {
              ref.invalidate(filteredDropdownsProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: DropdownGroup.values
              .map(
                (group) => Tab(
                  text: group.displayName,
                  icon: Icon(_getGroupIcon(group)),
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: DropdownGroup.values
            .map((group) => _buildGroupContent(group))
            .toList(),
      ),
    );
  }

  Widget _buildGroupContent(DropdownGroup group) {
    final isAdmin = ref.watch(isDropdownAdminProvider);
    final dropdownsAsync = ref.watch(filteredDropdownsProvider(group));

    return Column(
      children: [
        // Group statistics
        _buildGroupStats(group),

        // Dropdowns list
        Expanded(
          child: dropdownsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState(group, isAdmin);
              }
              return _buildDropdownsList(group, items, isAdmin);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupStats(DropdownGroup group) {
    final statsAsync = ref.watch(dropdownGroupStatsProvider(group));

    return Container(
      padding: const EdgeInsets.all(16),
      child: statsAsync.when(
        data: (stats) => Row(
          children: [
            _buildStatCard('Total', stats['total']!, Colors.blue),
            const SizedBox(width: 16),
            _buildStatCard('Active', stats['active']!, Colors.green),
            const SizedBox(width: 16),
            _buildStatCard('Inactive', stats['inactive']!, Colors.orange),
          ],
        ),
        loading: () => const SizedBox(height: 80),
        error: (_, __) => const SizedBox(height: 80),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(DropdownGroup group, bool isAdmin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getGroupIcon(group), size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No ${group.displayName.toLowerCase()} found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Tap "Add Item" to create your first dropdown item'
                : 'Contact an administrator to add dropdown items',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading dropdowns',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(filteredDropdownsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownsList(
    DropdownGroup group,
    List<DropdownItem> items,
    bool isAdmin,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      onReorder: isAdmin
          ? (oldIndex, newIndex) => _onReorder(group, items, oldIndex, newIndex)
          : (_, __) {},
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildDropdownItem(group, item, index, isAdmin);
      },
    );
  }

  Widget _buildDropdownItem(
    DropdownGroup group,
    DropdownItem item,
    int index,
    bool isAdmin,
  ) {
    return Card(
      key: ValueKey(item.value),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin) ...[
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              ),
              const SizedBox(width: 8),
            ],
            if (item.color != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(item.color!.replaceFirst('#', '0xFF')),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        title: Text(
          item.label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          item.value,
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active status chip
            Chip(
              label: Text(item.active ? 'Active' : 'Inactive'),
              backgroundColor: item.active
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              labelStyle: TextStyle(
                color: item.active
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),

            // Actions menu
            PopupMenuButton<String>(
              enabled: isAdmin,
              onSelected: (action) => _handleItemAction(action, group, item),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: item.active ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        item.active ? Icons.visibility_off : Icons.visibility,
                      ),
                      const SizedBox(width: 8),
                      Text(item.active ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'replace',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz),
                      SizedBox(width: 8),
                      Text('Replace in enquiries'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      await ref
          .read(dropdownFormControllerProvider.notifier)
          .reorderItems(group, orderedValues);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items reordered successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering items: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleItemAction(
    String action,
    DropdownGroup group,
    DropdownItem item,
  ) async {
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
    showDialog(
      context: context,
      builder: (context) => DropdownFormDialog(group: group),
    );
  }

  void _showEditDialog(
    BuildContext context,
    DropdownGroup group,
    DropdownItem item,
  ) {
    showDialog(
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
              item.active
                  ? 'Item deactivated successfully'
                  : 'Item activated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReplaceDialog(
    BuildContext context,
    DropdownGroup group,
    DropdownItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => DropdownReplaceDialog(
        group: group,
        oldValue: item.value,
        oldLabel: item.label,
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    DropdownGroup group,
    DropdownItem item,
  ) async {
    final hasReferences = await ref.read(
      isDropdownReferencedProvider((group, item.value)).future,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => DropdownDeleteDialog(
          group: group,
          item: item,
          hasReferences: hasReferences,
        ),
      );
    }
  }

  IconData _getGroupIcon(DropdownGroup group) {
    switch (group) {
      case DropdownGroup.statuses:
        return Icons.flag;
      case DropdownGroup.eventTypes:
        return Icons.event;
      case DropdownGroup.priorities:
        return Icons.priority_high;
      case DropdownGroup.paymentStatuses:
        return Icons.payment;
    }
  }
}
