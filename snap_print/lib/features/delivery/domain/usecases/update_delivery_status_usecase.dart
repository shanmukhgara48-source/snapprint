import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/delivery_repository.dart';
import '../../data/repositories/delivery_repository_impl.dart';

class UpdateDeliveryStatusUseCase {
  UpdateDeliveryStatusUseCase(this._repository);
  final DeliveryRepository _repository;

  Future<void> call(
    String orderId,
    String status, {
    String? proofUrl,
  }) =>
      _repository.updateStatus(orderId, status, proofUrl: proofUrl);
}

final updateDeliveryStatusUseCaseProvider =
    Provider<UpdateDeliveryStatusUseCase>((ref) {
  return UpdateDeliveryStatusUseCase(ref.read(deliveryRepositoryProvider));
});
