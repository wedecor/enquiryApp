import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../ui/primitives/primitives.dart';
import 'kanban_card.dart';

/// A tall glass lane for one status. Becomes a drop target: while a card
/// hovers, the lane takes a status tint, a stronger border and a soft glow,
/// and the accent rule under the header stretches across.
class KanbanLane extends StatelessWidget {
  const KanbanLane({
    super.key,
    required this.status,
    required this.label,
    required this.cards,
    required this.isHovered,
    required this.dropdownLookup,
    required this.onDragOver,
    required this.onDragLeave,
    required this.onDrop,
    required this.onTap,
    required this.width,
    this.isAdmin = false,
  });

  final String status;
  final String label;
  final List<QueryDocumentSnapshot> cards;
  final bool isHovered;
  final DropdownLookup? dropdownLookup;
  final VoidCallback onDragOver;
  final VoidCallback onDragLeave;
  final void Function(String enquiryId) onDrop;
  final void Function(String enquiryId) onTap;
  final double width;

  /// Passed to each [KanbanCard] (admin-only markers).
  final bool isAdmin;

  static const double _cardInset = 10;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final statusColor = AppColorScheme.statusColorFor(status);
    final duration = AppMotion.of(context, AppMotion.quick);

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        onDragOver();
        return true;
      },
      onLeave: (_) => onDragLeave(),
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, _) {
        final accepting = candidateData.isNotEmpty || isHovered;
        return AnimatedContainer(
          duration: duration,
          curve: AppMotion.standardCurve,
          width: width,
          decoration: BoxDecoration(
            borderRadius: AppRadius.xLarge,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  statusColor.withValues(alpha: accepting ? 0.16 : 0.06),
                  s.glassFill,
                ),
                Color.alphaBlend(
                  statusColor.withValues(alpha: accepting ? 0.06 : 0.0),
                  s.glassFill,
                ),
              ],
            ),
            border: Border.all(
              color: accepting ? statusColor.withValues(alpha: 0.7) : s.microBorder,
              width: accepting ? 1.6 : 1,
            ),
            boxShadow: accepting ? AppShadows.glow(statusColor, strength: 0.22) : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LaneHeader(
                label: label,
                count: cards.length,
                color: statusColor,
                accepting: accepting,
              ),
              Expanded(
                child: cards.isEmpty
                    ? _EmptyLane(accepting: accepting, color: statusColor)
                    : ListView.builder(
                        // Bottom inset keeps the last card clear of the FAB.
                        padding: const EdgeInsets.fromLTRB(_cardInset, 0, _cardInset, 72),
                        itemCount: cards.length,
                        itemBuilder: (context, i) {
                          final doc = cards[i];
                          // EnquiryListRow adds its own bottom spacing.
                          return StaggerIn(
                            index: i,
                            maxStaggered: 6,
                            child: KanbanCard(
                              doc: doc,
                              statusColor: statusColor,
                              dropdownLookup: dropdownLookup,
                              onTap: () => onTap(doc.id),
                              width: width - _cardInset * 2,
                              isAdmin: isAdmin,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LaneHeader extends StatelessWidget {
  const _LaneHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.accepting,
  });

  final String label;
  final int count;
  final Color color;
  final bool accepting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(color: color, size: 9),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Text(
                '$count',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          LayoutBuilder(
            builder: (context, constraints) => AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.standard),
              curve: AppMotion.standardCurve,
              height: 2,
              width: accepting ? constraints.maxWidth : 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: accepting ? 0.8 : 0.55),
                borderRadius: AppRadius.full,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLane extends StatelessWidget {
  const _EmptyLane({required this.accepting, required this.color});

  final bool accepting;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Center(
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.quick),
        child: Column(
          key: ValueKey(accepting),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accepting ? color.withValues(alpha: 0.14) : null,
                border: Border.all(color: accepting ? color : s.microBorderStrong),
              ),
              child: Icon(
                accepting ? Icons.south_rounded : Icons.remove_rounded,
                size: 18,
                color: accepting ? color : muted,
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Eyebrow(accepting ? 'Drop here' : 'Empty', color: accepting ? color : muted),
          ],
        ),
      ),
    );
  }
}
