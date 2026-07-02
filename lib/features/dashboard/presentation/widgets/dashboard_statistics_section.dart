import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/stats_card.dart';
import 'dashboard_enquiry_utils.dart';
import 'dashboard_kpi_grid.dart';

// ── Date range filter ─────────────────────────────────────────────────────────

enum _DateFilter {
  thisMonth('This month'),
  last30('Last 30 days'),
  allTime('All time');

  const _DateFilter(this.label);
  final String label;
}

DateTime? _cutoffFor(_DateFilter filter) {
  final now = DateTime.now();
  return switch (filter) {
    _DateFilter.thisMonth => DateTime(now.year, now.month, 1),
    _DateFilter.last30 => now.subtract(const Duration(days: 30)),
    _DateFilter.allTime => null,
  };
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Dashboard KPI statistics section with date-range toggle.
class DashboardStatisticsSection extends ConsumerStatefulWidget {
  const DashboardStatisticsSection({
    super.key,
    required this.isAdmin,
    required this.userId,
  });

  final bool isAdmin;
  final String? userId;

  @override
  ConsumerState<DashboardStatisticsSection> createState() =>
      _DashboardStatisticsSectionState();
}

class _DashboardStatisticsSectionState
    extends ConsumerState<DashboardStatisticsSection> {
  _DateFilter _filter = _DateFilter.thisMonth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .read(firestoreServiceProvider)
          .watchEnquiriesForRole(
            isAdmin: widget.isAdmin,
            assignedToUid: widget.userId,
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading statistics');
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppTokens.space6),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        final cutoff = _cutoffFor(_filter);
        final docs = cutoff == null
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final created = (data['createdAt'] as Timestamp?)?.toDate();
                return created != null && created.isAfter(cutoff);
              }).toList();

        int newCount = 0, staleNew = 0;
        int activeLeads = 0;
        int approved = 0, completed = 0, followUps = 0, notInterested = 0;
        double pipelineRevenue = 0, advancesCollected = 0;

        final now = DateTime.now();
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status =
              EnquiryStatus.fromValue(data['statusValue'] as String?)?.value ??
              ((data['statusValue'] as String?)?.toLowerCase() ?? '');
          final cost = (data['totalCost'] as num?)?.toDouble() ?? 0;
          final advance = (data['advancePaid'] as num?)?.toDouble() ?? 0;
          switch (status) {
            case 'new':
              newCount++;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              if (createdAt != null && now.difference(createdAt).inDays > 3)
                staleNew++;
            case 'in_talks':
              activeLeads++;
              if (shouldShowReminder(data, now)) followUps++;
              pipelineRevenue += cost;
            case 'approved':
              approved++;
              pipelineRevenue += cost;
              advancesCollected += advance;
            case 'completed':
              completed++;
              advancesCollected += advance;
            case 'not_interested':
              notInterested++;
          }
        }

        final won = approved + completed;
        final lost = notInterested;
        final conversionPct = (won + lost) > 0
            ? ((won / (won + lost)) * 100).round()
            : 0;

        String formatCurrency(double amount) {
          if (amount >= 100000)
            return '₹${(amount / 100000).toStringAsFixed(1)}L';
          if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
          return '₹${amount.toStringAsFixed(0)}';
        }

        final cards = [
          StatsCard(
            icon: Icons.fiber_new_outlined,
            value: newCount.toString(),
            label: 'New',
            trendLabel: staleNew > 0
                ? '$staleNew waiting 3+ days'
                : (newCount > 0 ? 'Need first contact' : 'All contacted'),
            trendIcon: staleNew > 0
                ? Icons.warning_amber_rounded
                : (newCount > 0 ? Icons.priority_high : Icons.check),
            trendColor: staleNew > 0
                ? colorScheme.error
                : (newCount > 0 ? colorScheme.error : colorScheme.tertiary),
          ),
          StatsCard(
            icon: Icons.forum_outlined,
            value: activeLeads.toString(),
            label: 'Active Leads',
            trendLabel: followUps > 0
                ? '$followUps events within 21d'
                : 'In progress',
            trendIcon: followUps > 0
                ? Icons.notifications_active_outlined
                : Icons.check,
            trendColor: followUps > 0
                ? colorScheme.primary
                : colorScheme.tertiary,
          ),
          StatsCard(
            icon: Icons.check_circle_outline,
            value: approved.toString(),
            label: 'Approved',
            trendLabel: approved > 0 ? 'Booked & ready' : 'None yet',
            trendIcon: approved > 0 ? Icons.event_available : null,
            trendColor: colorScheme.tertiary,
          ),
          StatsCard(
            icon: Icons.verified_outlined,
            value: completed.toString(),
            label: 'Completed',
            trendLabel: completed > 0 ? 'Events delivered' : null,
            trendIcon: completed > 0 ? Icons.star_outline : null,
            trendColor: colorScheme.tertiary,
          ),
          StatsCard(
            icon: Icons.trending_up,
            value: (won + lost) > 0 ? '$conversionPct%' : '0%',
            label: 'Conversion',
            trendLabel: (won + lost) > 0
                ? '${won}W · ${lost}L'
                : 'No closed cases yet',
            trendIcon: conversionPct >= 50
                ? Icons.trending_up
                : Icons.trending_flat,
            trendColor: conversionPct >= 50
                ? colorScheme.tertiary
                : colorScheme.onSurfaceVariant,
          ),
          StatsCard(
            icon: Icons.currency_rupee,
            value: pipelineRevenue > 0 ? formatCurrency(pipelineRevenue) : '₹0',
            label: 'Pipeline',
            trendLabel: 'Active + approved',
            trendIcon: Icons.show_chart,
            trendColor: colorScheme.primary,
          ),
          StatsCard(
            icon: Icons.payments_outlined,
            value: advancesCollected > 0
                ? formatCurrency(advancesCollected)
                : '₹0',
            label: 'Advances',
            trendLabel: 'Collected so far',
            trendIcon: Icons.check_circle_outline,
            trendColor: colorScheme.tertiary,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                0,
                AppTokens.space4,
                AppTokens.space3,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _DateFilter.values.map((f) {
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTokens.space2),
                      child: FilterChip(
                        label: Text(f.label),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = f),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        selectedColor: colorScheme.primaryContainer,
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        side: BorderSide(
                          color: selected
                              ? colorScheme.primary.withValues(alpha: 0.4)
                              : colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.full,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            DashboardKpiGrid(items: cards),
            const SizedBox(height: AppTokens.space2),
          ],
        );
      },
    );
  }
}
