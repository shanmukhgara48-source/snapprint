import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../domain/entities/order_entity.dart';

// Waits for authProvider to resolve before calling the authenticated
// /orders/me endpoint. Without this, screens that watch both providers
// (e.g. CustomerHomeScreen) fire this request in parallel with the
// Firebase-token-for-app-token exchange in AuthNotifier._syncBackend,
// which loses the race on cold start and 401s before the token is set.
final myOrdersProvider = FutureProvider<List<OrderEntity>>((ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return [];
  return ref.read(customerDataSourceProvider).getMyOrders();
});

final orderDetailProvider =
    FutureProvider.family<OrderEntity, String>((ref, id) async {
  return ref.read(customerDataSourceProvider).getOrderById(id);
});
