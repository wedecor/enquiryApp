import 'package:flutter/material.dart';

/// Transparent app bar with a heavy display title; sits on the ambient ground.
class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderBar({super.key, this.title = 'We Decor Dashboard'});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      ),
      automaticallyImplyLeading: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }
}
