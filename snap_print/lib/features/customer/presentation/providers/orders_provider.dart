import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../domain/entities/order_entity.dart';

final myOrdersProvider = FutureProvider<List<OrderEntity>>((ref) async {
  return ref.read(customerDataSourceProvider).getMyOrders();
});

final orderDetailProvider =
    FutureProvider.family<OrderEntity, String>((ref, id) async {
  return ref.read(customerDataSourceProvider).getOrderById(id);
});
