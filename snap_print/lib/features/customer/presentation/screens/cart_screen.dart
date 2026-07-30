import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../../../core/widgets/premium_network_image.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.cart)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: _cartCardDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _CartIconBubble(icon: Icons.shopping_bag_rounded),
                  const SizedBox(height: 18),
                  Text(
                    AppStrings.cartEmpty,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.cartEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Browse Products',
                    width: 210,
                    onPressed: () => context.go(AppRoutes.customerHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${AppStrings.cart} (${cart.itemCount})')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                ...cart.items.map(
                  (item) => Dismissible(
                    key: Key(item.cartItemId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                    onDismissed: (_) => notifier.removeItem(item.cartItemId),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: _cartCardDecoration(),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: PremiumNetworkImage(
                              imageUrl:
                                  item.customizationImageUrl ??
                                  (item.productImageUrl.isNotEmpty
                                      ? item.productImageUrl
                                      : resolveCartProductImage(
                                          item.productId,
                                          productName: item.productName,
                                        )),
                              categoryId: categoryFromProductId(
                                item.productId,
                                fallbackName: item.productName,
                              ),
                              width: 72,
                              height: 72,
                              borderRadius: 18,
                              cacheWidth: 180,
                              cacheHeight: 180,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.selectedSize,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _QuantityStepper(
                            quantity: item.quantity,
                            onDecrement: () => notifier.updateQuantity(
                              item.cartItemId,
                              item.quantity - 1,
                            ),
                            onIncrement: () => notifier.updateQuantity(
                              item.cartItemId,
                              item.quantity + 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _CouponPanel(
                  controller: _couponController,
                  couponCode: cart.couponCode,
                  isLoading: _applyingCoupon,
                  onApply: _applyCoupon,
                  onRemove: () {
                    notifier.removeCoupon();
                    _couponController.clear();
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cartCardDecoration(radius: 24),
                  child: Column(
                    children: [
                      _PriceLine(
                        label: AppStrings.subtotal,
                        value: '₹${cart.subtotal.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 8),
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
                        const SizedBox(height: 8),
                        _PriceLine(
                          label: AppStrings.discount,
                          value: '- ₹${cart.discount.toStringAsFixed(0)}',
                          valueColor: AppColors.success,
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      _PriceLine(
                        label: AppStrings.total,
                        value: '₹${cart.total.toStringAsFixed(0)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: _cartCardDecoration(radius: 28),
                child: CustomButton(
                  label: AppStrings.proceedToCheckout,
                  onPressed: () => context.push(AppRoutes.checkout),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponPanel extends StatelessWidget {
  const _CouponPanel({
    required this.controller,
    required this.couponCode,
    required this.isLoading,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String? couponCode;
  final bool isLoading;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (couponCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: _cartCardDecoration(radius: 20),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_rounded,
              color: AppColors.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '$couponCode applied',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onRemove,
              child: const Text(
                'Remove',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cartCardDecoration(radius: 22),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
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
            onPressed: isLoading ? null : onApply,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(AppStrings.apply),
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
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 20 : 14,
            fontWeight: FontWeight.w900,
            color: valueColor ?? (isBold ? AppColors.textPrimary : null),
          ),
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _SmallQtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          _SmallQtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        ],
      ),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 15, color: AppColors.primary),
      ),
    );
  }
}

class _CartIconBubble extends StatelessWidget {
  const _CartIconBubble({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(icon, size: 38, color: AppColors.accent),
    );
  }
}

BoxDecoration _cartCardDecoration({double radius = 24}) {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
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
