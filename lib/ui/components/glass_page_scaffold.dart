import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/navigation/shell_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';

/// Pushed full-screen route chrome: ambient ground, frosted top bar with a
/// round glass back button, eyebrow + heavy title and optional actions.
class GlassPageScaffold extends StatelessWidget {
  const GlassPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final List<Widget> actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassPageBar(title: title, eyebrow: eyebrow, actions: actions),
        body: body,
      ),
    );
  }
}

class GlassPageBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassPageBar({super.key, required this.title, this.eyebrow, this.actions = const []});

  final String title;
  final String? eyebrow;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.glassFill,
            border: Border(bottom: BorderSide(color: s.microBorder)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              canPop ? AppTokens.space3 : AppTokens.space5,
              topInset,
              AppTokens.space3,
              0,
            ),
            child: SizedBox(
              height: preferredSize.height,
              child: Row(
                children: [
                  if (canPop) ...[
                    ShellIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: AppTokens.space3),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null) ...[
                          Eyebrow(eyebrow!, accent: true),
                          const SizedBox(height: 2),
                        ],
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final action in actions) ...[
                    const SizedBox(width: AppTokens.space2),
                    action,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
