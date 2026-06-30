import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/delivery_order_entity.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasources/delivery_remote_datasource.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  DeliveryRepositoryImpl(this._dataSource);
  final DeliveryRemoteDataSource _dataSource;

  @override
  Future<List<DeliveryOrderEntity>> getAssignedOrders() =>
      _dataSource.getAssignedOrders();

  @override
  Future<void> updateStatus(
    String orderId,
    String status, {
    String? proofUrl,
  }) =>
      _dataSource.updateStatus(orderId, status, proofUrl: proofUrl);
}

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepositoryImpl(ref.read(deliveryDataSourceProvider));
});
