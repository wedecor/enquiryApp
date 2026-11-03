import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/ui/components/brand_splash.dart';

void main() {
  testWidgets('shows the lockup and only reveals the progress line after 3s', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BrandSplash()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Image), findsOneWidget);
    final line = find.ancestor(
      of: find.byType(LinearProgressIndicator),
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(line).opacity, 0);

    await tester.pump(const Duration(seconds: 3));
    expect(tester.widget<AnimatedOpacity>(line).opacity, 1);
  });
}
