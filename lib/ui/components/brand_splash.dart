import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opening screen while the session loads: charcoal, the gold WD mark with
/// WE DECOR and the tagline (one baked image, so no font loading), fading in.
///
/// Same look as the Android/web launch screens, so the hand-off is seamless. It
/// shows only as long as loading takes; a thin gold line appears only if that
/// passes 3 seconds (slow connection), so it never looks frozen.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key});

  static const Color charcoal = Color(0xFF23262B);
  static const Color gold = Color(0xFFC6A15B);
  static const String lockupAsset = 'assets/brand/splash_lockup.png';

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> {
  bool _visible = false;
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _slowTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: BrandSplash.charcoal,
      ),
      child: ColoredBox(
        color: BrandSplash.charcoal,
        child: Center(
          child: Semantics(
            label: 'We Decor. Bringing dreams to life. Loading',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: Image.asset(
                    BrandSplash.lockupAsset,
                    width: 228,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 56,
                  height: 2,
                  child: AnimatedOpacity(
                    opacity: _slow ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const LinearProgressIndicator(
                      minHeight: 2,
                      color: BrandSplash.gold,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
