import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/features/auth/data/models/user_model.dart';

void main() {
  test('backend identity is authoritative for id, role, and active state', () {
    final user = UserModel.fromBackend({
      'id': 'database-user-id',
      'firebase_uid': 'firebase-user-id',
      'phone': '+919876543210',
      'role': 'delivery',
      'is_active': true,
      'fcm_token': 'token',
    }, displayName: 'Delivery Partner');

    expect(user.id, 'database-user-id');
    expect(user.firebaseUid, 'firebase-user-id');
    expect(user.role, 'delivery');
    expect(user.isActive, isTrue);
    expect(user.displayName, 'Delivery Partner');
  });
}
