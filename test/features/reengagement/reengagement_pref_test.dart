import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/features/reengagement/data/reengagement_repository.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  test("\"Don't remind again\" goes through setReengagementPref, not a client write", () async {
    final firestore = _MockFirestore();
    final calls = <(String, bool)>[];
    final repo = ReengagementRepository(
      firestore,
      prefSetter: (phone, value) async => calls.add((phone, value)),
    );
    await repo.setNoReminders('9876543210', value: true, uid: 'staff1');
    expect(calls, [('9876543210', true)]);
    verifyZeroInteractions(firestore);
  });
}
