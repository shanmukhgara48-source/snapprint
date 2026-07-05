import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../customer/presentation/widgets/order_status_chip.dart';
import '../providers/delivery_provider.dart';

class DeliveryHomeScreen extends ConsumerWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(assignedOrdersProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Deliveries'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: AppStrings.assignedOrders),
              Tab(text: AppStrings.inProgress),
              Tab(text: AppStrings.completedOrders),
            ],
          ),
        ),
        body: ordersAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, s) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('$e'),
                TextButton(
                  onPressed: () => ref.invalidate(assignedOrdersProvider),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
          data: (orders) {
            final assigned = orders
                .where((o) => o.status == 'confirmed')
                .toList();
            final inProgress = orders
                .where((o) =>
                    o.status == 'picked_up' ||
                    o.status == 'out_for_delivery')
                .toList();
            final completed = orders
                .where((o) => o.status == 'delivered')
                .toList();

            return TabBarView(
              children: [
                _OrderList(orders: assigned, emptyMessage: AppStrings.noAssignedOrders, onRefresh: () async => ref.invalidate(assignedOrdersProvider)),
                _OrderList(orders: inProgress, emptyMessage: 'No orders in progress', onRefresh: () async => ref.invalidate(assignedOrdersProvider)),
                _OrderList(orders: completed, emptyMessage: 'No completed orders', onRefresh: () async => ref.invalidate(assignedOrdersProvider)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.emptyMessage, required this.onRefresh});
  final List orders;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final order = orders[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context
                  .push(AppRoutes.deliveryOrderDetailPath(order.id)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        OrderStatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _AddressRow(
                      icon: Icons.store_outlined,
                      label: 'Pickup',
                      address: order.pickupAddress,
                      color: AppColors.info,
                    ),
                    const SizedBox(height: 6),
                    _AddressRow(
                      icon: Icons.location_on_outlined,
                      label: 'Deliver to',
                      address:
                          '${order.deliveryAddress}, ${order.deliveryCity}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${order.itemCount} items',
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Text(
                          '₹${order.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
