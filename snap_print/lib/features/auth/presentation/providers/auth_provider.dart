import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/firebase/fcm_service.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user_entity.dart';

const _storageKeyDevToken = 'dev_auth_token';
const _storageKeyDevUid = 'dev_firebase_uid';

const _storageKeyRole = 'user_role';

class AuthNotifier extends AsyncNotifier<UserEntity?> implements ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _listeners = <VoidCallback>[];

  // Set to true after a successful OTP verification or profile completion.
  // GoRouter redirect checks this flag to route to the success screen.
  bool _verifiedJustNow = false;
  bool get verifiedJustNow => _verifiedJustNow;
  void acknowledgeVerification() => _verifiedJustNow = false;

  @override
  Future<UserEntity?> build() async {
    // Restore dev session if one was previously stored
    final storedDevToken = await _storage.read(key: _storageKeyDevToken);
    final storedDevUid = await _storage.read(key: _storageKeyDevUid);
    if (storedDevToken != null && storedDevUid != null) {
      setDevAuthToken(storedDevToken);
      return UserEntity(
        id: storedDevUid,
        firebaseUid: storedDevUid,
        phone: await _storage.read(key: 'dev_phone') ?? '',
        role: 'customer',
        isActive: true,
        displayName: await _storage.read(key: 'dev_display_name') ?? 'Test User',
      );
    }

    final firebaseUser = ref.read(firebaseAuthServiceProvider).currentUser;
    if (firebaseUser == null) return null;
    // Ensure PostgreSQL record exists for cached Firebase sessions too
    await _syncBackend(firebaseUser);
    return _loadFromFirestore(firebaseUser);
  }

  Future<UserEntity?> _loadFromFirestore(User firebaseUser) async {
    try {
      final user =
          await ref.read(firestoreServiceProvider).getUser(firebaseUser.uid);
      if (user != null) {
        await _storage.write(key: _storageKeyRole, value: user.role);
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Syncs the Firebase-authenticated user into the PostgreSQL backend.
  /// Sends the Firebase ID token once so the server can verify ownership of
  /// the UID (via firebase_admin.auth.verify_id_token) and exchanges it for
  /// our own application access token, along with the current FCM token so
  /// order-status push notifications (see backend notify_order_placed/
  /// notify_delivered etc.) have somewhere to go. The app access token —
  /// not the raw Firebase token — is what every later API call uses
  /// (see ApiClient's _AuthInterceptor); it's re-minted here on every
  /// sign-in, auto-verify, and cold-start restore, so no separate refresh
  /// flow is needed for its ~7-day lifetime.
  Future<void> _syncBackend(User firebaseUser, {String role = 'customer', String? fcmToken}) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        dev.log('[PhoneAuth] backend sync skipped — no id token', name: 'SnapPrint');
        return;
      }
      final token = fcmToken ?? await ref.read(fcmServiceProvider).getToken();
      final client = ref.read(apiClientProvider);
      final response = await client.post(ApiEndpoints.verifyAuth, data: {
        'id_token': idToken,
        'phone': firebaseUser.phoneNumber ?? '',
        'role': role,
        'fcm_token': ?token,
      });
      final accessToken = (response.data as Map<String, dynamic>)['access_token'] as String?;
      if (accessToken != null) setAppAuthToken(accessToken);
      dev.log('[PhoneAuth] backend sync success uid=${firebaseUser.uid}', name: 'SnapPrint');
    } catch (e) {
      dev.log('[PhoneAuth] backend sync failed (non-fatal): $e', name: 'SnapPrint');
    }
  }

  /// Called by FcmService whenever the device's FCM token is issued or
  /// rotates, so a logged-in user's backend record stays current without
  /// waiting for their next login.
  Future<void> syncFcmToken(String token) async {
    final firebaseUser = ref.read(firebaseAuthServiceProvider).currentUser;
    if (firebaseUser != null) await _syncBackend(firebaseUser, fcmToken: token);
  }

  /// Initiates SMS OTP. Returns the verificationId when the SMS is sent,
  /// or 'auto-verified' if Android auto-detected and signed in the user.
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();
    final authService = ref.read(firebaseAuthServiceProvider);

    dev.log('[PhoneAuth] verifyPhoneNumber called for: $phoneNumber', name: 'SnapPrint');

    authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: (verificationId, _) {
        dev.log('[PhoneAuth] codeSent — verificationId: $verificationId', name: 'SnapPrint');
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      verificationFailed: (e) {
        dev.log(
          '[PhoneAuth] verificationFailed — code: ${e.code} | message: ${e.message} | plugin: ${e.plugin}',
          name: 'SnapPrint',
        );
        if (!completer.isCompleted) completer.completeError(e);
      },
      verificationCompleted: (credential) async {
        // Android only: auto-detected OTP — sign in without user input
        try {
          final userCred = await authService.signInWithCredential(credential);
          await _syncBackend(userCred.user!);
          final user = await _loadFromFirestore(userCred.user!);
          if (user != null) {
            state = AsyncData(user);
            _notifyListeners();
          }
          if (!completer.isCompleted) completer.complete('auto-verified');
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
    );

    return completer.future;
  }

  /// Verifies the 6-digit OTP. Returns true if this is a new user
  /// (Firebase auth succeeded but no Firestore profile exists yet).
  Future<bool> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCred = await authService.signInWithCredential(credential);
      final firebaseUser = userCred.user;
      if (firebaseUser == null) throw Exception('Authentication failed');

      // Sync into PostgreSQL backend (creates record if new, no-ops if existing)
      await _syncBackend(firebaseUser);

      final user = await _loadFromFirestore(firebaseUser);
      if (user == null) {
        // Firebase auth complete, but no Firestore profile — new user
        state = const AsyncData(null);
        return true;
      }

      _verifiedJustNow = true;
      state = AsyncData(user);
      _notifyListeners();
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Creates the Firestore profile after OTP verification (new users only).
  Future<void> completeProfile({
    required String phone,
    required String displayName,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firebaseUser = ref.read(firebaseAuthServiceProvider).currentUser;
      if (firebaseUser == null) {
        throw Exception('Session expired. Please verify your phone again.');
      }

      final user = await ref.read(firestoreServiceProvider).createUser(
            uid: firebaseUser.uid,
            phone: phone,
            role: role,
            displayName: displayName,
          );

      await _storage.write(key: _storageKeyRole, value: user.role);
      _verifiedJustNow = true;
      _notifyListeners();
      return user;
    });
  }

  /// Dev-only: logs in via backend bypass without real Firebase OTP.
  /// Only callable in debug builds — no-ops in release.
  Future<void> devLogin(String phone, String displayName) async {
    assert(kDebugMode, 'devLogin must not be called in production');
    if (!kDebugMode) return;
    // Dev bypass secret comes from --dart-define=DEV_BYPASS_SECRET=... at build time only
    const devSecret = String.fromEnvironment('DEV_BYPASS_SECRET');
    if (devSecret.isEmpty) {
      throw Exception('DEV_BYPASS_SECRET is not set. Pass --dart-define=DEV_BYPASS_SECRET=<value>');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(apiClientProvider);
      final resp = await client.post(ApiEndpoints.devLogin, data: {
        'phone': phone,
        'secret': devSecret,
      });
      final data = resp.data as Map<String, dynamic>;
      final devToken = data['dev_token'] as String;
      final firebaseUid = data['firebase_uid'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      setDevAuthToken(devToken);
      await _storage.write(key: _storageKeyDevToken, value: devToken);
      await _storage.write(key: _storageKeyDevUid, value: firebaseUid);
      await _storage.write(key: 'dev_phone', value: phone);
      await _storage.write(key: 'dev_display_name', value: displayName);

      _verifiedJustNow = true;
      _notifyListeners();
      return UserEntity(
        id: userData['id'] as String,
        firebaseUid: firebaseUid,
        phone: phone,
        role: 'customer',
        isActive: true,
        displayName: displayName,
      );
    });
  }

  Future<void> signOut() async {
    setDevAuthToken(null);
    setAppAuthToken(null);
    await ref.read(firebaseAuthServiceProvider).signOut();
    await _storage.deleteAll();
    state = const AsyncData(null);
    _notifyListeners();
  }

  // ChangeNotifier compatibility for GoRouter refreshListenable
  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);
  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  @override
  bool get hasListeners => _listeners.isNotEmpty;
  @override
  void dispose() => _listeners.clear();
  @override
  void notifyListeners() => _notifyListeners();
  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(
  AuthNotifier.new,
);
