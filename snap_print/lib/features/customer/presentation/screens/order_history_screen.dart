import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_status_chip.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final user = userAsync.valueOrNull;
    final isGuest = user == null || user.id == 'guest';

    if (isGuest) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.orderHistory)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _OrderEmptyState(
              icon: Icons.lock_rounded,
              title: 'Sign in to view your orders',
              subtitle: 'Track and manage all your print orders.',
              action: ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Sign In'),
              ),
            ),
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.orderHistory)),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(myOrdersProvider),
        child: ordersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, s) {
            final isAuthError =
                e is AppException &&
                (e.message.toLowerCase().contains('authenticat') ||
                    e.message.toLowerCase().contains('unauthorized'));
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAuthError ? Icons.lock_outline : Icons.error_outline,
                        size: 48,
                        color: isAuthError
                            ? AppColors.textHint
                            : AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAuthError
                            ? 'Please sign in to view your orders'
                            : 'Failed to load orders',
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(myOrdersProvider),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          data: (orders) {
            if (orders.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: const SizedBox(
                  height: 400,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: _OrderEmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: AppStrings.noOrders,
                        subtitle:
                            'Your handcrafted print timeline will appear here.',
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final order = orders[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: _orderCardDecoration(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () =>
                        context.push(AppRoutes.orderConfirmationPath(order.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Order #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OrderStatusChip(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _statusProgress(order.status),
                              minHeight: 5,
                              backgroundColor: AppColors.divider,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(order.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${order.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Row(
                                children: [
                                  Text(
                                    AppStrings.trackOrder,
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.accent,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

double _statusProgress(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('delivered')) return 1;
  if (normalized.contains('out')) return 0.82;
  if (normalized.contains('shipped')) return 0.64;
  if (normalized.contains('processing')) return 0.46;
  if (normalized.contains('confirm')) return 0.3;
  if (normalized.contains('fail') || normalized.contains('cancel')) return 0.12;
  return 0.18;
}

BoxDecoration _orderCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AppColors.divider),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.045),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

class _OrderEmptyState extends StatelessWidget {
  const _OrderEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _orderCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    );
  }
}
