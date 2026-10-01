import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Floating frosted action bar pinned to the bottom of the enquiry screens.
/// Content scrolls underneath it, so callers must reserve [reservedHeight]
/// (plus the bottom safe-area inset) at the end of their scrollable.
class EnquiryGlassBar extends StatelessWidget {
  const EnquiryGlassBar({super.key, required this.child});

  /// Approximate height the bar occupies above the safe-area inset.
  static const double reservedHeight = 96;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space3,
        AppTokens.space2,
        AppTokens.space3,
        bottomInset + AppTokens.space3,
      ),
      child: GlassPanel(
        blur: true,
        strong: true,
        shadow: true,
        borderRadius: AppRadius.xxLarge,
        padding: const EdgeInsets.all(AppTokens.space2),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// Bottom padding a scrollable needs so its last item clears [EnquiryGlassBar].
double enquiryGlassBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + EnquiryGlassBar.reservedHeight;
