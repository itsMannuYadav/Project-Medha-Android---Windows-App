import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/notifications_api.dart';

const _channelId = 'medha_default';
const _channelName = 'Medha सूचनाएं';
const _channelDescription = 'नई गतिविधि, गृहकार्य और घोषणाओं की सूचना';

/// Runs in a separate background isolate when a push arrives while the app
/// isn't in the foreground -- Firebase needs its own init there too.
/// `@pragma('vm:entry-point')` keeps the Dart compiler from stripping it.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push notifications: Firebase Cloud Messaging for delivery,
/// flutter_local_notifications to actually show a banner while the app is
/// in the foreground (FCM alone doesn't display foreground notifications on
/// Android). Every step degrades gracefully -- only Android has
/// `google-services.json` wired up so far, so this quietly no-ops on
/// iOS/Windows for now; the in-app notification inbox (`NotificationsApi`,
/// the bell icon) always works regardless of any of this.
class PushService {
  PushService._();

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _firebaseReady = false;

  /// Call once at app startup, before the first screen shows.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase not configured on this platform yet, push disabled: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(_channelId, _channelName, description: _channelDescription, importance: Importance.high),
        );

    FirebaseMessaging.onMessage.listen(_showForegroundBanner);
  }

  static void _showForegroundBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Call once after a successful login (and it's safe to call again on
  /// every app start): asks for the notification permission, then registers
  /// this device's FCM token with the backend so it can actually receive
  /// pushes. A declined permission or missing Firebase config just means no
  /// push for this device -- never blocks or throws into the caller.
  static Future<void> registerDevice() async {
    if (!_firebaseReady) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await NotificationsApi.registerDevice(token: token, platform: _platformName());
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        NotificationsApi.registerDevice(token: newToken, platform: _platformName());
      });
    } catch (e) {
      debugPrint('Push device registration skipped: $e');
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    return Platform.isIOS ? 'ios' : 'android';
  }
}
