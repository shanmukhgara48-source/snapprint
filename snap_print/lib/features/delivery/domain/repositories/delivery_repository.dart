import '../entities/delivery_order_entity.dart';

abstract class DeliveryRepository {
  Future<List<DeliveryOrderEntity>> getAssignedOrders();
  Future<void> updateStatus(String orderId, String status, {String? proofUrl});
}
