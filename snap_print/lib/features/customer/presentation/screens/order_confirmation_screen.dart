import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../providers/orders_provider.dart';
import '../providers/social_providers.dart';
import '../widgets/order_status_chip.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.orderConfirmed)),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
        child: orderAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, s) => _SuccessView(
            orderId: orderId,
            estimatedDelivery: null,
            detailsUnavailable: true,
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
          data: (order) => _SuccessView(
            orderId: order.id,
            estimatedDelivery: order.estimatedDelivery,
            status: order.status,
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends ConsumerWidget {
  const _SuccessView({
    required this.orderId,
    required this.estimatedDelivery,
    this.status,
    this.detailsUnavailable = false,
    this.onRetry,
  });
  final String orderId;
  final DateTime? estimatedDelivery;
  final String? status;
  final bool detailsUnavailable;
  final VoidCallback? onRetry;

  static const _returnable = {
    'confirmed',
    'picked_up',
    'out_for_delivery',
    'delivered',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Success animation
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            AppStrings.orderPlaced,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your order has been placed successfully!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (detailsUnavailable) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your order was placed, but its latest details could not be loaded.',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retry',
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Order details card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _DetailRow(label: AppStrings.orderId, value: '#$orderId'),
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      OrderStatusChip(status: status!),
                    ],
                  ),
                ],
                if (estimatedDelivery != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: AppStrings.estimatedDelivery,
                    value: DateFormat('dd MMM yyyy').format(estimatedDelivery!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          CustomButton(
            label: AppStrings.trackOrder,
            icon: Icons.local_shipping_outlined,
            onPressed: () => context.push(AppRoutes.orderHistory),
          ),
          const SizedBox(height: 12),
          _ReturnSection(orderId: orderId, status: status),
          const SizedBox(height: 12),
          CustomButton(
            label: AppStrings.continueShopping,
            isOutlined: true,
            onPressed: () => context.go(AppRoutes.customerHome),
          ),
        ],
      ),
    );
  }
}

class _ReturnSection extends ConsumerStatefulWidget {
  const _ReturnSection({required this.orderId, this.status});
  final String orderId;
  final String? status;

  @override
  ConsumerState<_ReturnSection> createState() => _ReturnSectionState();
}

class _ReturnSectionState extends ConsumerState<_ReturnSection> {
  static const _reasons = [
    ('damaged', 'Damaged / defective'),
    ('wrong_item', 'Wrong item'),
    ('quality_issue', 'Print quality issue'),
    ('late_delivery', 'Arrived too late'),
    ('changed_mind', 'Changed my mind'),
    ('other', 'Other'),
  ];

  String _reason = 'damaged';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(myReturnsProvider);
    return returnsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, s) => const SizedBox.shrink(),
      data: (returns) {
        Map<String, dynamic>? existing;
        for (final r in returns) {
          if (r['order_id'] == widget.orderId) {
            existing = r;
            break;
          }
        }
        if (existing != null) {
          final st = existing['status'] as String? ?? 'requested';
          final note = existing['admin_note'] as String?;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Return ${st.replaceAll('_', ' ')}${note != null && note.isNotEmpty ? ' — $note' : ''}',
              textAlign: TextAlign.center,
            ),
          );
        }
        if (widget.status == null ||
            !_SuccessView._returnable.contains(widget.status)) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need a return or refund?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: [
                  for (final r in _reasons)
                    DropdownMenuItem(value: r.$1, child: Text(r.$2)),
                ],
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: 10),
              CustomButton(
                label: _busy ? 'Submitting...' : 'Request return',
                isOutlined: true,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(customerDataSourceProvider).requestReturn({
        'order_id': widget.orderId,
        'reason': _reason,
      });
      ref.invalidate(myReturnsProvider);
      if (mounted) {
        showSuccessSnackbar(context, 'Return requested — we will update you soon.');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Could not request the return.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
