import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.firebaseUid,
    required super.phone,
    required super.role,
    required super.isActive,
    super.displayName,
    super.email,
    super.fcmToken,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) =>
      UserModel(
        id: uid,
        firebaseUid: uid,
        phone: data['phone'] as String? ?? '',
        role: data['role'] as String? ?? 'customer',
        isActive: data['isActive'] as bool? ?? true,
        displayName: data['displayName'] as String?,
        email: data['email'] as String?,
        fcmToken: data['fcmToken'] as String?,
      );

  factory UserModel.fromBackend(
    Map<String, dynamic> data, {
    String? displayName,
  }) => UserModel(
    id: data['id'] as String,
    firebaseUid: data['firebase_uid'] as String,
    phone: data['phone'] as String? ?? '',
    role: data['role'] as String? ?? 'customer',
    isActive: data['is_active'] as bool? ?? true,
    displayName: displayName,
    email: data['email'] as String?,
    fcmToken: data['fcm_token'] as String?,
  );

  Map<String, dynamic> toFirestore() => {
    'phone': phone,
    'role': role,
    'isActive': isActive,
    'displayName': displayName,
    'email': email,
    'fcmToken': fcmToken,
    'updatedAt': DateTime.now().toIso8601String(),
  };
}
