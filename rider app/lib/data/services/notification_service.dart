import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';

const _kOneSignalAppId = 'REPLACE';

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // FCM permission
    await _fcm.requestPermission();

    // Awesome Notifications init
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'delivery_channel',
        channelName: 'Delivery Updates',
        channelDescription: 'Notifications for delivery updates',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ]);

    // Notification permission
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) showLocal(n.title ?? '', n.body ?? '');
    });

    // OneSignal
    OneSignal.initialize(_kOneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
  }

  static Future<String?> getToken() => _fcm.getToken();

  static Future<void> setExternalUserId(String uid) async {
    OneSignal.login(uid);
  }

  static Future<void> showLocal(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'delivery_channel',
        title: title,
        body: body,
      ),
    );
  }

  // Send push to specific user via OneSignal REST API
  static Future<void> sendPushToUser({
    required String targetUid,
    required String title,
    required String body,
  }) async {
    const apiKey = 'REPLACE';
    await http.post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: {
        'Authorization': 'Basic $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'app_id': _kOneSignalAppId,
        'include_aliases': {
          'external_id': [targetUid],
        },
        'target_channel': 'push',
        'headings': {'en': title},
        'contents': {'en': body},
      }),
    );
  }
}
