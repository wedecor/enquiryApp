import 'package:flutter/material.dart';

import '../../../../ui/components/tinted_icon_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/safe_log.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/primitives/primitives.dart';

/// Widget for cleaning up past enquiries
class PastEnquiryCleanupWidget extends ConsumerStatefulWidget {
  const PastEnquiryCleanupWidget({super.key});

  @override
  ConsumerState<PastEnquiryCleanupWidget> createState() => _PastEnquiryCleanupWidgetState();
}

class _PastEnquiryCleanupWidgetState extends ConsumerState<PastEnquiryCleanupWidget> {
  bool _isRunning = false;
  int? _pendingCount;
  bool _isLoadingCount = false;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    setState(() {
      _isLoadingCount = true;
    });

    try {
      final service = ref.read(pastEnquiryCleanupServiceProvider);
      final count = await service.countPastEnquiriesToUpdate();
      if (mounted) {
        setState(() {
          _pendingCount = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      safeLog('past_enquiry_count_error', {'error': e.toString()});
      if (mounted) {
        setState(() {
          _isLoadingCount = false;
        });
      }
    }
  }

  Future<void> _runCleanup() async {
    final roleAsync = ref.read(roleProvider);
    final role = roleAsync.valueOrNull;

    if (role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can run this cleanup'),
          backgroundColor: AppColorScheme.snackError,
        ),
      );
      return;
    }

    final currentUserAsync = ref.read(currentUserWithFirestoreProvider);
    final currentUser = currentUserAsync.valueOrNull;
    final userId = currentUser?.uid ?? 'system';

    setState(() {
      _isRunning = true;
    });

    try {
      final service = ref.read(pastEnquiryCleanupServiceProvider);
      // Use runAutomaticCleanup(force: true) — same date-guarded logic as the daily run
      final updatedCount = await service.runAutomaticCleanup(force: true, userId: userId) ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated $updatedCount enquiry(ies)'),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );

        setState(() {
          _pendingCount = 0;
          _isRunning = false;
        });
      }
    } catch (e) {
      safeLog('past_enquiry_cleanup_error', {'error': e.toString()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running cleanup: $e'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TintedIconBadge(icon: Icons.auto_fix_high_rounded),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Past Enquiries Status',
                      style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automatically marks approved bookings as completed once their event date has passed (runs at start of next day).',
                      style: t.bodySmall?.copyWith(fontWeight: FontWeight.w300, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.standard),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, if (current != null) current],
            ),
            child: _isLoadingCount
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _pendingCount != null
                ? _PendingPill(key: ValueKey(_pendingCount), count: _pendingCount!)
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_isRunning || _isLoadingCount) ? null : _runCleanup,
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  icon: _isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high, size: 18),
                  label: Text(_isRunning ? 'Running...' : 'Run Cleanup'),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              IconButton.outlined(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _isRunning ? null : _loadPendingCount,
                tooltip: 'Refresh count',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingPill extends StatelessWidget {
  const _PendingPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = count > 0 ? AppColorScheme.warning : AppColorScheme.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusDot(color: color, size: 7),
            const SizedBox(width: AppTokens.space2),
            Text(
              '$count pending',
              style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
