import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../dashboard_providers.dart';
import '../screens/amount_pending_screen.dart';

/// Admin dashboard card: "N approved bookings without an amount". Hidden when
/// there are none, while loading, on error and for staff. Opens
/// [AmountPendingScreen].
class AmountPendingCard extends ConsumerWidget {
  const AmountPendingCard({super.key, required this.isAdmin, required this.userId});

  final bool isAdmin;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAdmin) return const SizedBox.shrink();
    // Same shared listeners as the Today counters.
    final docs = watchRoleScopedEnquiries(
      ref,
      isAdmin: isAdmin,
      uid: userId,
      scopes: amountPendingScopes,
    ).valueOrNull;
    if (docs == null) return const SizedBox.shrink();
    final count = amountPendingDocs(docs).length;
    if (count == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final ink = theme.brightness == Brightness.dark
        ? AppColorScheme.warningDark
        : AppColorScheme.onWarningContainerLight;
    final label = count == 1
        ? '1 approved booking without an amount'
        : '$count approved bookings without an amount';

    void open() => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AmountPendingScreen(userId: userId)),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space3),
      child: Pressable(
        onTap: open,
        borderRadius: AppRadius.large,
        semanticLabel: label,
        child: GlassPanel(
          key: const Key('amountPendingCard'),
          strong: true,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space1,
            AppTokens.space1,
            AppTokens.space1,
          ),
          child: Row(
            children: [
              Icon(Icons.currency_rupee_rounded, size: AppTokens.iconSmall, color: ink),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                ),
              ),
              TextButton(
                onPressed: open,
                style: TextButton.styleFrom(foregroundColor: s.accentInk),
                child: const Text('View'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
