import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/safe_log.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../shared/models/user_model.dart';

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
          backgroundColor: Colors.red,
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
      final updatedCount = await service.markPastEnquiriesAsNotInterested(userId: userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated $updatedCount enquiry(ies)'),
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Past Enquiries Status',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          'Automatically update enquiries with passed event dates:\n'
          '• "new", "in_talks", "quote_sent" → "not_interested"\n'
          '• "confirmed" → "completed"',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_isLoadingCount)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_pendingCount != null)
              Chip(
                label: Text('$_pendingCount pending'),
                backgroundColor: _pendingCount! > 0 ? Colors.orange.shade100 : Colors.green.shade100,
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: (_isRunning || _isLoadingCount) ? null : _runCleanup,
              icon: _isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_isRunning ? 'Running...' : 'Run Cleanup'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isRunning ? null : _loadPendingCount,
              tooltip: 'Refresh count',
            ),
          ],
        ),
      ],
    );
  }
}

