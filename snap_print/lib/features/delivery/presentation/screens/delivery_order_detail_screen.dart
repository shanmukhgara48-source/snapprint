import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../../customer/presentation/widgets/order_status_chip.dart';
import '../providers/delivery_provider.dart';

class DeliveryOrderDetailScreen extends ConsumerWidget {
  const DeliveryOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(assignedOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, s) => Center(child: Text('$e')),
        data: (orders) {
          final order = orders.where((o) => o.id == orderId).firstOrNull;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Status
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            OrderStatusChip(status: order.status),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Customer info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(order.customerPhone),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _callCustomer(
                                    context,
                                    order.customerPhone,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.call_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          AppStrings.callCustomer,
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Addresses
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AddressSection(
                              icon: Icons.store_outlined,
                              title: AppStrings.pickupLocation,
                              address: order.pickupAddress,
                              color: AppColors.info,
                            ),
                            const Divider(height: 20),
                            _AddressSection(
                              icon: Icons.location_on_rounded,
                              title: AppStrings.deliveryLocation,
                              address:
                                  '${order.deliveryAddress}, ${order.deliveryCity} - ${order.deliveryPincode}',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 10),
                    CustomButton(
                      label: AppStrings.navigate,
                      icon: Icons.navigation_rounded,
                      isOutlined: true,
                      onPressed: () => _openNavigation(
                        context,
                        latitude: order.deliveryLat,
                        longitude: order.deliveryLng,
                        address:
                            '${order.deliveryAddress}, ${order.deliveryCity} ${order.deliveryPincode}',
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ActionButtons(order: order, orderId: orderId),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _callCustomer(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) showErrorSnackbar(context, 'Cannot make call');
    }
  }

  Future<void> _openNavigation(
    BuildContext context, {
    required double? latitude,
    required double? longitude,
    required String address,
  }) async {
    final destination = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : address;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      showErrorSnackbar(context, 'Could not open navigation');
    }
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.order, required this.orderId});
  final dynamic order;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusNotifier = ref.read(deliveryStatusProvider.notifier);
    final isLoading = ref.watch(deliveryStatusProvider).isLoading;

    String? nextStatus;
    String? nextLabel;

    switch (order.status) {
      case 'confirmed':
        nextStatus = 'picked_up';
        nextLabel = AppStrings.pickedUp;
      case 'picked_up':
        nextStatus = 'out_for_delivery';
        nextLabel = 'Out for Delivery';
      case 'out_for_delivery':
        nextStatus = null;
        nextLabel = null;
    }

    return Column(
      children: [
        if (nextStatus != null)
          CustomButton(
            label: nextLabel!,
            isLoading: isLoading,
            onPressed: () async {
              await statusNotifier.updateStatus(orderId, nextStatus!);
              if (context.mounted) context.pop();
            },
          ),
        if (order.status == 'out_for_delivery') ...[
          const SizedBox(height: 8),
          CustomButton(
            label: AppStrings.uploadProof,
            icon: Icons.upload_rounded,
            onPressed: () => context.push(AppRoutes.deliveryProofPath(orderId)),
          ),
        ],
      ],
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.icon,
    required this.title,
    required this.address,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
