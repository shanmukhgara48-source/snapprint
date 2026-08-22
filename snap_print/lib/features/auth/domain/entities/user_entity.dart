class UserEntity {
  const UserEntity({
    required this.id,
    required this.firebaseUid,
    required this.phone,
    required this.role,
    required this.isActive,
    this.displayName,
    this.email,
    this.fcmToken,
  });

  final String id;
  final String firebaseUid;
  final String phone;
  final String role; // 'customer' | 'delivery'
  final bool isActive;
  final String? displayName;
  final String? email;
  final String? fcmToken;
}
