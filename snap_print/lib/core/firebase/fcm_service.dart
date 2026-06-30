import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level handler for background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Handle background notification silently
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM: request permission, set handlers, return FCM token.
  Future<String?> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] User denied notifications');
      return null;
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get FCM token — may fail if SHA-1 not registered in Firebase Console
    String? token;
    try {
      token = await _messaging.getToken();
      debugPrint('[FCM] Token: $token');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        // TODO: Send updated token to backend
      });
    } catch (e) {
      debugPrint('[FCM] Could not get token (add debug SHA-1 in Firebase Console): $e');
    }

    return token;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    // TODO: Show local notification using flutter_local_notifications
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    // TODO: Navigate to relevant screen based on message.data['type']
    // e.g. 'order_update' → navigate to order detail
  }

  /// Returns the current FCM token.
  Future<String?> getToken() => _messaging.getToken();

  /// Subscribes to a topic (e.g. 'promotions').
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  /// Unsubscribes from a topic.
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}

final fcmServiceProvider = Provider<FcmService>((_) => FcmService());
