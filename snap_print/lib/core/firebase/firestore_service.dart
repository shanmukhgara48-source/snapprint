import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/models/user_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc.data()!, uid);
  }

  Future<UserModel> createUser({
    required String uid,
    required String phone,
    required String role,
    String? displayName,
  }) async {
    final data = {
      'phone': phone,
      'role': role,
      'isActive': true,
      'displayName': displayName ?? '',
      'phoneVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _users.doc(uid).set(data);
    return UserModel(
      id: uid,
      firebaseUid: uid,
      phone: phone,
      role: role,
      isActive: true,
      displayName: displayName ?? '',
    );
  }

  Future<void> updateFcmToken(String uid, String? token) async {
    await _users.doc(uid).update({'fcmToken': token});
  }
}

final firestoreServiceProvider = Provider<FirestoreService>(
  (_) => FirestoreService(),
);
