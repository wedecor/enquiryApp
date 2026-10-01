import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../filters_state.dart';

/// Glass row for one saved view: tap applies it, the overflow menu edits,
/// sets as default or deletes.
class SavedViewTile extends StatelessWidget {
  const SavedViewTile({
    super.key,
    required this.view,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final SavedView view;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final descriptions = view.filters.activeFilterDescriptions;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: Pressable(
        onTap: onApply,
        borderRadius: AppRadius.large,
        child: GlassPanel(
          strong: true,
          borderRadius: AppRadius.large,
          tint: view.isDefault ? s.accent.withValues(alpha: 0.07) : null,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space3,
            AppTokens.space1,
            AppTokens.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: view.isDefault ? s.accent.withValues(alpha: 0.14) : s.glassFill,
                  border: Border.all(
                    color: view.isDefault ? s.accent.withValues(alpha: 0.3) : s.microBorder,
                  ),
                ),
                child: Icon(
                  view.isDefault ? Icons.star_rounded : Icons.bookmark_outline_rounded,
                  size: 20,
                  color: view.isDefault ? s.accentInk : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (view.isDefault) const Eyebrow('Default', accent: true),
                    Text(
                      view.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (descriptions.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        descriptions.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTokens.space1),
                    Text(
                      'Created ${_formatDate(view.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _Menu(
                isDefault: view.isDefault,
                onApply: onApply,
                onEdit: onEdit,
                onDelete: onDelete,
                onSetDefault: onSetDefault,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.isDefault,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final bool isDefault;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        switch (value) {
          case 'apply':
            onApply();
            break;
          case 'edit':
            onEdit();
            break;
          case 'default':
            onSetDefault();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'apply',
          child: ListTile(
            leading: Icon(Icons.play_arrow_rounded),
            title: Text('Apply'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (!isDefault)
          const PopupMenuItem(
            value: 'default',
            child: ListTile(
              leading: Icon(Icons.star_outline_rounded),
              title: Text('Set as Default'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: error),
            title: Text('Delete', style: TextStyle(color: error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
