import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getIdToken({bool forceRefresh = false}) =>
      _auth.currentUser?.getIdToken(forceRefresh) ?? Future.value(null);

  /// Starts phone number verification. Callbacks fire asynchronously:
  /// - [codeSent] when SMS is dispatched (provides verificationId)
  /// - [verificationFailed] on invalid number or rate limit
  /// - [verificationCompleted] on Android auto-detection (skips OTP entry)
  void verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException) verificationFailed,
    void Function(PhoneAuthCredential)? verificationCompleted,
    void Function(String)? codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) {
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted ?? (_) {},
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout ?? (_) {},
      timeout: timeout,
    );
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) =>
      _auth.signInWithCredential(credential);

  Future<void> signOut() => _auth.signOut();

  String? get uid => _auth.currentUser?.uid;
  String? get phoneNumber => _auth.currentUser?.phoneNumber;
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (_) => FirebaseAuthService(),
);
