import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Verifies the Firebase UID with the backend, creates or fetches the user,
  /// and returns the UserEntity with role and ID.
  Future<UserEntity> verifyFirebaseUser({
    required String firebaseUid,
    required String phone,
    required String role,
    String? fcmToken,
    String? referredByCode,
  });
}
