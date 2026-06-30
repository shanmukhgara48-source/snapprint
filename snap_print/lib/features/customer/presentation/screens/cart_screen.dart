import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _applyingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final cart = ref.read(cartProvider);
    if (cart.subtotal <= 0) return;

    setState(() => _applyingCoupon = true);
    try {
      final result = await ref
          .read(customerRepositoryProvider)
          .validateCoupon(code, cart.subtotal);

      if (!mounted) return;

      final valid = result['valid'] == true;
      final message = result['message'] as String? ?? '';
      final discount = (result['discount_amount'] as num?)?.toDouble() ?? 0;

      if (valid) {
        ref.read(cartProvider.notifier).applyCoupon(code, discount);
        showSuccessSnackbar(context, message);
      } else {
        showErrorSnackbar(context, message);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Could not apply coupon');
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.cart)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 72, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(AppStrings.cartEmpty,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(AppStrings.cartEmptySubtitle,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Browse Products',
                width: 200,
                onPressed: () => context.go(AppRoutes.customerHome),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${AppStrings.cart} (${cart.itemCount})')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cart items
                ...cart.items.map((item) => Dismissible(
                      key: Key(item.cartItemId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                      ),
                      onDismissed: (_) =>
                          notifier.removeItem(item.cartItemId),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: item.customizationImageUrl ??
                                      item.productImageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorWidget: (c, u, e) => Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.accentLight,
                                    child: const Icon(Icons.image_outlined,
                                        color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(item.selectedSize,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity control
                              Row(
                                children: [
                                  _SmallQtyBtn(
                                    icon: Icons.remove,
                                    onTap: () => notifier.updateQuantity(
                                        item.cartItemId, item.quantity - 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  _SmallQtyBtn(
                                    icon: Icons.add,
                                    onTap: () => notifier.updateQuantity(
                                        item.cartItemId, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),

                const SizedBox(height: 8),

                // Coupon
                if (cart.couponCode != null)
                  // Applied state — show code chip with remove button
                  Row(
                    children: [
                      const Icon(Icons.local_offer,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${cart.couponCode!} applied',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          notifier.removeCoupon();
                          _couponController.clear();
                        },
                        child: const Text('Remove',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: const InputDecoration(
                            hintText: AppStrings.enterCouponCode,
                            prefixIcon: Icon(Icons.local_offer_outlined),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyingCoupon ? null : _applyCoupon,
                        child: _applyingCoupon
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(AppStrings.apply),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Price breakdown
                _PriceLine(
                    label: AppStrings.subtotal,
                    value: '₹${cart.subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                _PriceLine(
                  label: AppStrings.deliveryCharge,
                  value: cart.deliveryCharge == 0
                      ? AppStrings.free
                      : '₹${cart.deliveryCharge.toStringAsFixed(0)}',
                  valueColor: cart.deliveryCharge == 0
                      ? AppColors.success
                      : null,
                ),
                if (cart.discount > 0) ...[
                  const SizedBox(height: 6),
                  _PriceLine(
                    label: AppStrings.discount,
                    value: '- ₹${cart.discount.toStringAsFixed(0)}',
                    valueColor: AppColors.success,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                _PriceLine(
                  label: AppStrings.total,
                  value: '₹${cart.total.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: CustomButton(
                label: AppStrings.proceedToCheckout,
                onPressed: () => context.push(AppRoutes.checkout),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? (isBold ? AppColors.textPrimary : null),
          ),
        ),
      ],
    );
  }
}

class _SmallQtyBtn extends StatelessWidget {
  const _SmallQtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}
