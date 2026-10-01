import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_detail_section.dart';

/// Assignment section with async user display rows.
class EnquiryAssignmentSection extends ConsumerStatefulWidget {
  const EnquiryAssignmentSection({
    super.key,
    required this.userRole,
    required this.assignedTo,
    required this.createdBy,
    required this.currentUserId,
  });

  final UserRole? userRole;
  final String? assignedTo;
  final String? createdBy;
  final String currentUserId;

  @override
  ConsumerState<EnquiryAssignmentSection> createState() => _EnquiryAssignmentSectionState();
}

class _EnquiryAssignmentSectionState extends ConsumerState<EnquiryAssignmentSection> {
  final Map<String, String> _userDisplayCache = <String, String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.userRole == UserRole.admin) {
      return EnquiryDetailSection(
        eyebrow: 'Ownership',
        title: 'Assignment',
        children: [
          _AsyncUserRow(
            label: 'Assigned To',
            userId: widget.assignedTo,
            currentUserId: widget.currentUserId,
            cache: _userDisplayCache,
            getUserDisplayName: _getUserDisplayName,
          ),
          _AsyncUserRow(
            label: 'Created By',
            userId: widget.createdBy,
            cache: _userDisplayCache,
            getUserDisplayName: _getUserDisplayName,
          ),
        ],
      );
    }

    if (widget.userRole == UserRole.staff) {
      return EnquiryDetailSection(
        eyebrow: 'Ownership',
        title: 'Assignment',
        children: [
          _AsyncUserRow(
            label: 'Assigned To',
            userId: widget.assignedTo,
            currentUserId: widget.currentUserId,
            cache: _userDisplayCache,
            getUserDisplayName: _getUserDisplayName,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<String> _getUserDisplayName(String userId) async {
    final cached = _userDisplayCache[userId];
    if (cached != null) return cached;

    try {
      final data = await ref.read(firestoreServiceProvider).getUser(userId);
      if (data == null) {
        _userDisplayCache[userId] = 'Unknown';
        return 'Unknown';
      }
      final name = (data['name'] as String?)?.trim();
      final phone = (data['phone'] as String?)?.trim();
      final display = [name, phone].where((e) => e != null && e.isNotEmpty).join(' · ');
      final result = display.isNotEmpty ? display : 'Unknown';
      _userDisplayCache[userId] = result;
      return result;
    } catch (_) {
      return 'Unknown';
    }
  }
}

class _AsyncUserRow extends StatelessWidget {
  const _AsyncUserRow({
    required this.label,
    required this.userId,
    required this.cache,
    required this.getUserDisplayName,
    this.currentUserId,
  });

  final String label;
  final String? userId;
  final String? currentUserId;
  final Map<String, String> cache;
  final Future<String> Function(String userId) getUserDisplayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.bottom(AppTokens.space4),
      child: _UserDisplay(
        label: label,
        userId: userId,
        currentUserId: currentUserId,
        getUserDisplayName: getUserDisplayName,
      ),
    );
  }
}

class _UserDisplay extends StatelessWidget {
  const _UserDisplay({
    required this.label,
    required this.userId,
    required this.getUserDisplayName,
    this.currentUserId,
  });

  final String label;
  final String? userId;
  final String? currentUserId;
  final Future<String> Function(String userId) getUserDisplayName;

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return _PersonLine(label: label, name: 'Unassigned', muted: true);
    }
    if (currentUserId != null && userId == currentUserId) {
      return _PersonLine(label: label, name: 'You', highlight: true);
    }

    return FutureBuilder<String>(
      future: getUserDisplayName(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _PersonLine(label: label, name: null);
        }
        return _PersonLine(label: label, name: snapshot.data ?? 'Unknown');
      },
    );
  }
}

/// Monogram avatar + eyebrow label over the person's name. A null [name]
/// shows a slim loading line in place of the name.
class _PersonLine extends StatelessWidget {
  const _PersonLine({
    required this.label,
    required this.name,
    this.muted = false,
    this.highlight = false,
  });

  final String label;
  final String? name;
  final bool muted;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final initial = (name == null || muted || name!.trim().isEmpty)
        ? null
        : name!.trim().characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: highlight ? s.accentGradient : null,
            color: highlight ? null : s.glassFillStrong,
            border: Border.all(color: highlight ? s.edgeHighlight : s.microBorderStrong),
          ),
          child: initial == null
              ? Icon(
                  Icons.person_outline_rounded,
                  size: AppTokens.iconMedium,
                  color: cs.onSurfaceVariant,
                )
              : Text(
                  initial,
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: highlight ? AppColorScheme.brandCharcoal : cs.onSurface,
                  ),
                ),
        ),
        const SizedBox(width: AppTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Eyebrow(label),
              const SizedBox(height: 2),
              if (name == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTokens.space2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else
                Text(
                  name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge?.copyWith(
                    fontWeight: muted ? FontWeight.w300 : FontWeight.w600,
                    color: muted ? cs.onSurfaceVariant : cs.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
