import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/services/notification_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late NotificationService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = NotificationService(FirestoreService(firestore: fakeFirestore));
  });

  test('markAsRead updates read flag on user notification', () async {
    final docRef = fakeFirestore
        .collection('users')
        .doc('u1')
        .collection('notifications')
        .doc('n1');
    await docRef.set({'title': 'Test', 'read': false});

    await service.markNotificationAsRead('u1', 'n1');

    final snap = await docRef.get();
    expect(snap.data()?['read'], isTrue);
  });

  test('markAllAsRead marks all unread notifications as read', () async {
    final col = fakeFirestore.collection('users').doc('u1').collection('notifications');
    await col.doc('n1').set({'title': 'A', 'read': false});
    await col.doc('n2').set({'title': 'B', 'read': false});
    await col.doc('n3').set({'title': 'C', 'read': true});

    await service.markAllNotificationsAsRead('u1');

    final n1 = await col.doc('n1').get();
    final n2 = await col.doc('n2').get();
    expect(n1.data()?['read'], isTrue);
    expect(n2.data()?['read'], isTrue);
  });
}
