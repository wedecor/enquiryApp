import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> onLoginSubscribe(String uid, {bool isAdmin = false}) async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  await fcm.subscribeToTopic('user_$uid');
  if (isAdmin) await fcm.subscribeToTopic('admins');
}

Future<void> onLogoutUnsubscribe(String uid, {bool isAdmin = false}) async {
  final fcm = FirebaseMessaging.instance;
  await fcm.unsubscribeFromTopic('user_$uid');
  if (isAdmin) await fcm.unsubscribeFromTopic('admins');
}
