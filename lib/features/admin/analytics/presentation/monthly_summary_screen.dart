import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../settings/domain/app_config.dart';
import '../../../settings/providers/settings_providers.dart';
import '../data/monthly_summary_pdf.dart';
import '../domain/monthly_summary.dart';
import 'monthly_summary_controller.dart';
import 'widgets/analytics_section_card.dart';
import 'widgets/analytics_state_views.dart';
import 'widgets/monthly_summary_sections.dart';

/// Admin-only monthly summary: month picker, sections, Share as PDF.
class MonthlySummaryScreen extends ConsumerWidget {
  const MonthlySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final selected = ref.watch(monthlySummaryMonthProvider);
    final async = ref.watch(monthlySummaryProvider);
    final options = monthlySummaryMonthOptions(now);

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  AppTokens.space4,
                  AppTokens.space4,
                  AppTokens.space2,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: Text(
                        'Monthly summary',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    async.maybeWhen(
                      data: (summary) => TextButton.icon(
                        onPressed: summary.isEmpty ? null : () => _sharePdf(context, ref, summary),
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Share as PDF'),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SummaryMonth>(
                      isExpanded: true,
                      value: selected,
                      items: [
                        for (final m in options)
                          DropdownMenuItem(
                            value: m,
                            child: Text(monthlySummaryMonthOptionLabel(m, now)),
                          ),
                      ],
                      onChanged: (m) {
                        if (m == null) return;
                        ref.read(monthlySummaryMonthProvider.notifier).state = m;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              Expanded(
                child: async.when(
                  loading: () => const AnalyticsLoadingView(message: 'Building monthly summary…'),
                  error: (e, _) => AnalyticsErrorView(
                    error: 'Could not build the monthly summary.\n$e',
                    onRetry: () => ref.invalidate(monthlySummaryProvider),
                  ),
                  data: (summary) {
                    if (summary.isEmpty) {
                      return Center(
                        child: AnalyticsEmptyState(
                          icon: Icons.inbox_outlined,
                          message: 'No enquiries in ${summary.month.label}',
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.space4,
                        AppTokens.space2,
                        AppTokens.space4,
                        AppTokens.space8,
                      ),
                      children: [MonthlySummaryBody(summary: summary)],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref, MonthlySummary summary) async {
    final company = ref.read(appGeneralConfigProvider).valueOrNull ?? const AppGeneralConfig();
    try {
      await MonthlySummaryPdf.buildAndShare(summary: summary, company: company);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not share PDF: $e')));
    }
  }
}
