import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';

/// Glass panel with the member search field and role / status filters.
class UsersFilterPanel extends StatelessWidget {
  const UsersFilterPanel({
    super.key,
    required this.searchController,
    required this.role,
    required this.isActive,
    required this.onRoleChanged,
    required this.onActiveChanged,
  });

  final TextEditingController searchController;
  final String role;
  final bool? isActive;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<bool?> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: role,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Roles')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  ],
                  onChanged: (value) {
                    if (value != null) onRoleChanged(value);
                  },
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  initialValue: isActive,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem<bool?>(value: null, child: Text('All Status')),
                    DropdownMenuItem<bool?>(value: true, child: Text('Active')),
                    DropdownMenuItem<bool?>(value: false, child: Text('Inactive')),
                  ],
                  onChanged: onActiveChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
