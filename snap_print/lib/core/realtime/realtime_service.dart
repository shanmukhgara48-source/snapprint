import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'realtime_event.dart';

enum RealtimeConnectionState { disconnected, connecting, connected }

/// Maintains one authenticated WebSocket to the backend (`/ws/app`) and
/// exposes pushed domain events as a broadcast stream.
///
/// Resilience:
/// - authenticates with the Firebase ID token (first message, never the URL)
/// - heartbeat ping every 25s; stale connections (>60s silent) are recycled
/// - exponential backoff with jitter (1s → 30s), reset on successful auth
/// - reconnects immediately when connectivity returns or the user logs in
/// - disconnects on logout
class RealtimeService {
  RealtimeService();

  final _eventsController = StreamController<RealtimeEvent>.broadcast();

  /// Domain events pushed by the backend.
  Stream<RealtimeEvent> get events => _eventsController.stream;

  final connectionState =
      ValueNotifier<RealtimeConnectionState>(RealtimeConnectionState.disconnected);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime _lastMessageAt = DateTime.now();
  int _retryCount = 0;
  bool _started = false;
  bool _disposed = false;

  static const _heartbeatInterval = Duration(seconds: 25);
  static const _staleAfter = Duration(seconds: 60);
  static const _maxBackoff = Duration(seconds: 30);

  void start() {
    if (_started || _disposed) return;
    _started = true;

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && getDevAuthToken() == null) {
        _teardownSocket();
        connectionState.value = RealtimeConnectionState.disconnected;
      } else {
        _retryCount = 0;
        _connect();
      }
    });

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online &&
          connectionState.value == RealtimeConnectionState.disconnected) {
        _retryCount = 0;
        _connect();
      }
    });

    _connect();
  }

  Future<void> _connect() async {
    if (_disposed ||
        connectionState.value != RealtimeConnectionState.disconnected) {
      return;
    }
    _reconnectTimer?.cancel();

    final token = await _resolveToken();
    if (token == null) return; // not logged in — auth listener will retry

    connectionState.value = RealtimeConnectionState.connecting;
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl.replaceFirst('http', 'ws')}/ws/app',
      );
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _lastMessageAt = DateTime.now();

      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));

      _channelSub = channel.stream.listen(
        _onMessage,
        onDone: _onSocketClosed,
        onError: (_) => _onSocketClosed(),
        cancelOnError: true,
      );
    } catch (_) {
      connectionState.value = RealtimeConnectionState.disconnected;
      _scheduleReconnect();
    }
  }

  Future<String?> _resolveToken() async {
    // Prefer our own backend-minted JWT (dev bypass or the access token from
    // AuthNotifier._syncBackend) — the server verifies these locally against
    // its own secret key, with no dependency on the Firebase project the ID
    // token was minted for matching the backend's configured Firebase
    // project. Raw Firebase ID tokens are kept only as a last-resort
    // fallback since a project mismatch there fails server-side auth.
    final devToken = getDevAuthToken();
    if (devToken != null) return devToken;
    final appToken = getAppAuthToken();
    if (appToken != null) return appToken;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) return await user.getIdToken();
    } catch (_) {}
    return null;
  }

  void _onMessage(dynamic raw) {
    _lastMessageAt = DateTime.now();
    Map<String, dynamic> message;
    try {
      message = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (message['type']) {
      case 'auth_ok':
        connectionState.value = RealtimeConnectionState.connected;
        _retryCount = 0;
        _startHeartbeat();
      case 'pong':
        break; // _lastMessageAt already refreshed above
      case 'event':
        final event = RealtimeEvent.tryParse(message);
        if (event != null) _eventsController.add(event);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (DateTime.now().difference(_lastMessageAt) > _staleAfter) {
        // Server went silent — recycle the connection.
        _onSocketClosed();
        return;
      }
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      } catch (_) {
        _onSocketClosed();
      }
    });
  }

  void _onSocketClosed() {
    if (_disposed) return;
    _teardownSocket();
    connectionState.value = RealtimeConnectionState.disconnected;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    final backoffSeconds = min(
      _maxBackoff.inSeconds,
      1 << min(_retryCount, 5), // 1, 2, 4, 8, 16, 32→30
    );
    _retryCount++;
    final jitterMs = Random().nextInt(1000);
    _reconnectTimer = Timer(
      Duration(seconds: backoffSeconds, milliseconds: jitterMs),
      _connect,
    );
  }

  void _teardownSocket() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Forces an immediate (re)connect attempt using whatever token
  /// [_resolveToken] currently resolves to. Callers whose sign-in doesn't
  /// go through Firebase (e.g. the dev-login bypass) must call this
  /// explicitly, since [start]'s auth listener only reacts to Firebase
  /// [authStateChanges].
  void reconnect() {
    _retryCount = 0;
    _reconnectTimer?.cancel();
    _teardownSocket();
    connectionState.value = RealtimeConnectionState.disconnected;
    _connect();
  }

  /// Tears the socket down without scheduling a reconnect. Callers whose
  /// sign-out doesn't go through Firebase (e.g. clearing a dev-login
  /// session) must call this explicitly for the same reason as [reconnect].
  void disconnectNow() {
    _reconnectTimer?.cancel();
    _teardownSocket();
    connectionState.value = RealtimeConnectionState.disconnected;
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _authSub?.cancel();
    _connectivitySub?.cancel();
    _teardownSocket();
    _eventsController.close();
    connectionState.dispose();
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService()..start();
  ref.onDispose(service.dispose);
  return service;
});
