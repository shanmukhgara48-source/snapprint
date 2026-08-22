import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getIdToken({bool forceRefresh = false}) =>
      _auth.currentUser?.getIdToken(forceRefresh) ?? Future.value(null);

  // ---------------------------------------------------------------------------
  // Phone Authentication
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Email / Password Authentication
  // ---------------------------------------------------------------------------

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ---------------------------------------------------------------------------
  // Common
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  String? get uid => _auth.currentUser?.uid;
  String? get phoneNumber => _auth.currentUser?.phoneNumber;
  String? get email => _auth.currentUser?.email;
  String? get displayName => _auth.currentUser?.displayName;
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (_) => FirebaseAuthService(),
);
