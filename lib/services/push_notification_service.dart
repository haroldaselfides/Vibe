import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permission (iOS and Android 13+).
    await _requestPermissions();

    // Initialize local notifications for foreground alerts
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Print token for debugging.
    await _getAndPrintToken();

    // Listen for token refreshes and update Firestore automatically
    _messaging.onTokenRefresh.listen((newToken) {
      updateTokenInFirestore();
    });

    // Foreground message handler.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode, // A unique ID for the notification
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // When app is opened from a notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // ignore: avoid_print
      print('FCM onMessageOpenedApp: ${message.messageId} ${message.data}');
    });

    // Background messages are handled in android-specific entrypoint via
    // firebase_messaging BackgroundMessageHandler (see main.dart).

    // NOTE: If you rely on push while app is in background/terminated,
    // you must show a local notification from the background handler.
    // This service currently only shows notifications for foreground messages.
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ignore: avoid_print
    print('FCM permission: ${settings.authorizationStatus}');
  }

  /// Saves the FCM token to the user's Firestore document.
  /// Call this after a successful login or during app initialization if the user is already logged in.
  Future<void> updateTokenInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _getAndPrintToken() async {
    final token = await _messaging.getToken();
    // ignore: avoid_print
    print('FCM token: $token');
  }
}
