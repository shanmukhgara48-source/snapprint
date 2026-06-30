import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/fcm_service.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class VerifyFirebaseUidUseCase {
  VerifyFirebaseUidUseCase(this._repository, this._fcmService);

  final AuthRepository _repository;
  final FcmService _fcmService;

  Future<UserEntity> call({
    required String firebaseUid,
    required String phone,
    required String role,
  }) async {
    final fcmToken = await _fcmService.getToken();
    return _repository.verifyFirebaseUser(
      firebaseUid: firebaseUid,
      phone: phone,
      role: role,
      fcmToken: fcmToken,
    );
  }
}

final verifyFirebaseUidProvider = Provider<VerifyFirebaseUidUseCase>((ref) {
  return VerifyFirebaseUidUseCase(
    ref.read(authRepositoryProvider),
    ref.read(fcmServiceProvider),
  );
});
