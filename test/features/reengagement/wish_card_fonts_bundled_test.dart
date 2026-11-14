import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/presentation/wish_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wish card fonts resolve from assets with runtime fetching off', () async {
    final previous = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = previous);

    final png = await WishCardRenderer.renderPng(
      WishCardContent.forOccasion(
        kind: OccasionKind.birthday,
        customerName: 'Ayesha Khan',
        nth: 1,
        enquired: false,
      ),
    );
    expect(png, isNotEmpty);
  });
}
