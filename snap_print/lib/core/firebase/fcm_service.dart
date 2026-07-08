import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level handler for background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) debugPrint('[FCM] Background message: ${message.messageId}');
  // Handle background notification silently
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM: request permission, set handlers, return FCM token.
  ///
  /// [onToken] fires once the token is first available, and again whenever it
  /// rotates, so the caller (see AuthNotifier.syncFcmToken) can keep the
  /// backend's copy current.
  ///
  /// [onNotificationTap] fires with the message data when the user taps a
  /// notification that opened the app from the background — payloads are
  /// always `{'type': ..., 'order_id': ...}` (see backend firebase_service.py).
  Future<String?> initialize({
    void Function(String token)? onToken,
    void Function(Map<String, dynamic> data)? onNotificationTap,
  }) async {
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
      if (kDebugMode) debugPrint('[FCM] User denied notifications');
      return null;
    }

    // Foreground messages are intentionally not surfaced as an in-app banner:
    // the customer/delivery apps already hold a live WebSocket connection
    // (see core/realtime/realtime_service.dart) that updates order status UI
    // in real time, so a duplicate system-style notification isn't needed.
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    });

    // Notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message.data);
    });

    // Get FCM token — may fail if SHA-1 not registered in Firebase Console
    String? token;
    try {
      token = await _messaging.getToken();
      if (token != null) onToken?.call(token);

      // Listen for token refresh (device reinstall, token expiry, etc.)
      _messaging.onTokenRefresh.listen((newToken) => onToken?.call(newToken));
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Could not get token (add debug SHA-1 in Firebase Console): $e');
    }

    // Every device joins the broadcast topic used by admin announcements.
    try {
      await _messaging.subscribeToTopic('all_users');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Topic subscribe failed: $e');
    }

    return token;
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
