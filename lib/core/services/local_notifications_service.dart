import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  LocalNotificationsService._internal();
  static final LocalNotificationsService instance = LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    final initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle tap with response.payload if needed
    });

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'high_importance',
        'High Importance',
        description: 'Used for important notifications',
        importance: Importance.high,
      ));
    }

    _initialized = true;
  }

  Future<void> show({required String title, required String body, Map<String, dynamic>? payload}) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance',
      'High Importance',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload == null ? null : payload.toString(),
    );
  }
}


