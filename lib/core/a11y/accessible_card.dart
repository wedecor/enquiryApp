import 'package:flutter/material.dart';

/// A simple accessible card wrapper
class AccessibleCard extends StatelessWidget {
  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget card = Card(child: child);
    
    if (onTap != null) {
      card = InkWell(
        onTap: enabled ? onTap : null,
        child: card,
      );
    }
    
    if (semanticLabel != null || semanticHint != null) {
      card = Semantics(
        label: semanticLabel,
        hint: semanticHint,
        child: card,
      );
    }
    
    return card;
  }
}
