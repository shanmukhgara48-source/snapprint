import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/delivery_remote_datasource.dart';
import '../../domain/entities/delivery_order_entity.dart';

final assignedOrdersProvider =
    FutureProvider<List<DeliveryOrderEntity>>((ref) async {
  return ref.read(deliveryDataSourceProvider).getAssignedOrders();
});

class DeliveryStatusNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateStatus(
    String orderId,
    String status, {
    String? proofUrl,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deliveryDataSourceProvider).updateStatus(
            orderId,
            status,
            proofUrl: proofUrl,
          );
      ref.invalidate(assignedOrdersProvider);
    });
  }
}

final deliveryStatusProvider =
    AsyncNotifierProvider<DeliveryStatusNotifier, void>(
  DeliveryStatusNotifier.new,
);
