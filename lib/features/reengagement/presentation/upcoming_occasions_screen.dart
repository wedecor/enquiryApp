import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/user_model.dart';
import '../../../ui/components/glass_page_scaffold.dart';
import '../../../ui/components/glass_segmented_tabs.dart';
import '../../../ui/components/glass_state_message.dart';
import '../../../ui/primitives/primitives.dart';
import '../domain/past_customer_occasion.dart';
import 'reengagement_actions.dart';
import 'reengagement_providers.dart';
import 'widgets/occasion_row.dart';
import 'widgets/past_customer_row_tile.dart';

/// Customer occasions, two tabs:
/// * **Due now** — pending yearly reminders for the next 30 days, soonest first.
/// * **All past customers** — every completed customer with an occasion, by next
///   yearly date, with a WhatsApp wish button.
///
/// Admins see everyone's; staff see their own (assigned) customers.
class UpcomingOccasionsScreen extends ConsumerStatefulWidget {
  const UpcomingOccasionsScreen({super.key});

  @override
  ConsumerState<UpcomingOccasionsScreen> createState() => _UpcomingOccasionsScreenState();
}

class _UpcomingOccasionsScreenState extends ConsumerState<UpcomingOccasionsScreen>
    with SingleTickerProviderStateMixin {
  static const _segments = [
    GlassSegment('Due now', icon: Icons.notifications_active_outlined),
    GlassSegment('All past customers', icon: Icons.people_outline_rounded),
  ];

  late final TabController _tabController = TabController(length: _segments.length, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPageScaffold(
      eyebrow: 'Same time next year',
      title: 'Customer occasions',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space3,
              AppTokens.space4,
              AppTokens.space1,
            ),
            child: GlassSegmentedTabs(controller: _tabController, segments: _segments),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_DueNowTab(), _PastCustomersTab()],
            ),
          ),
        ],
      ),
    );
  }
}

const EdgeInsets _listPadding = EdgeInsets.fromLTRB(
  AppTokens.space4,
  AppTokens.space4,
  AppTokens.space4,
  AppTokens.space12,
);

const EdgeInsets _panelPadding = EdgeInsets.fromLTRB(
  AppTokens.space4,
  AppTokens.space2,
  AppTokens.space2,
  AppTokens.space2,
);

/// Pending reminders (WhatsApp / Mark sent / Skip / Don't remind again).
class _DueNowTab extends ConsumerWidget {
  const _DueNowTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(upcomingRemindersProvider);
    final isAdmin = ref.watch(roleProvider).valueOrNull == UserRole.admin;

    return remindersAsync.when(
      loading: () => const GlassLoadingState(),
      error: (error, _) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Reminders unavailable',
        message: '$error',
        color: Theme.of(context).colorScheme.error,
      ),
      data: (reminders) {
        if (reminders.isEmpty) {
          return GlassStateMessage(
            icon: Icons.celebration_outlined,
            title: 'Nothing to send right now',
            message:
                "Reminders appear 30 days before a past customer's occasion (1 year or "
                'more after their event). The app checks every morning at 9.',
            action: isAdmin ? const _CheckNowButton() : null,
          );
        }
        return ListView(
          padding: _listPadding,
          children: [
            GlassPanel(
              strong: true,
              padding: _panelPadding,
              child: Column(children: [for (final r in reminders) OccasionRow(reminder: r)]),
            ),
          ],
        );
      },
    );
  }
}

/// Admin-only: runs the daily reminder job now.
class _CheckNowButton extends ConsumerStatefulWidget {
  const _CheckNowButton();

  @override
  ConsumerState<_CheckNowButton> createState() => _CheckNowButtonState();
}

class _CheckNowButtonState extends ConsumerState<_CheckNowButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    await ReengagementActions.checkNow(context, ref);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox.square(
              dimension: AppTokens.iconSmall,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
      label: const Text('Check now'),
    );
  }
}

/// Every completed customer with an occasion, soonest next yearly date first.
class _PastCustomersTab extends ConsumerStatefulWidget {
  const _PastCustomersTab();

  @override
  ConsumerState<_PastCustomersTab> createState() => _PastCustomersTabState();
}

class _PastCustomersTabState extends ConsumerState<_PastCustomersTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref.refresh(pastCustomerOccasionsProvider.future);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final rowsAsync = ref.watch(pastCustomerOccasionsProvider);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return rowsAsync.when(
      loading: () => const GlassLoadingState(message: 'Loading past customers…'),
      error: (error, _) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Customers unavailable',
        message: '$error',
        color: cs.error,
        action: TextButton(onPressed: _refresh, child: const Text('Try again')),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: AppTokens.space12),
                GlassStateMessage(
                  icon: Icons.people_outline_rounded,
                  title: 'No past customers yet',
                  message:
                      'Completed events show up here with their yearly date, so you can '
                      'wish the customer any time.',
                ),
              ],
            ),
          );
        }
        final visible = PastCustomers.search(rows, _query);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: _listPadding,
            children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search name or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.space1),
                child: Text(
                  visible.length == 1 ? '1 customer' : '${visible.length} customers',
                  style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTokens.space6),
                  child: Text(
                    'No customers match "$_query"',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              else
                GlassPanel(
                  strong: true,
                  padding: _panelPadding,
                  child: Column(children: [for (final r in visible) PastCustomerRowTile(row: r)]),
                ),
            ],
          ),
        );
      },
    );
  }
}
