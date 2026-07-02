import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
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
  ConsumerState<EnquiryAssignmentSection> createState() =>
      _EnquiryAssignmentSectionState();
}

class _EnquiryAssignmentSectionState
    extends ConsumerState<EnquiryAssignmentSection> {
  final Map<String, String> _userDisplayCache = <String, String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.userRole == UserRole.admin) {
      return EnquiryDetailSection(
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
      final display = [
        name,
        phone,
      ].where((e) => e != null && e.isNotEmpty).join(' · ');
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
      padding: AppSpacing.bottom(AppTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _UserDisplay(
              userId: userId,
              currentUserId: currentUserId,
              getUserDisplayName: getUserDisplayName,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDisplay extends StatelessWidget {
  const _UserDisplay({
    required this.userId,
    required this.getUserDisplayName,
    this.currentUserId,
  });

  final String? userId;
  final String? currentUserId;
  final Future<String> Function(String userId) getUserDisplayName;

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return const Text('Unassigned', style: TextStyle(fontSize: 16));
    }
    if (currentUserId != null && userId == currentUserId) {
      return const Text('You', style: TextStyle(fontSize: 16));
    }

    return FutureBuilder<String>(
      future: getUserDisplayName(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 12,
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final value = snapshot.data ?? 'Unknown';
        return Text(value, style: const TextStyle(fontSize: 16));
      },
    );
  }
}
