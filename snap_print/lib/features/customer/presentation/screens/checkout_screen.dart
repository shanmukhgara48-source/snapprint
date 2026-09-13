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
import '../../../../core/network/api_client.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/checkout_rules.dart';
import '../providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/delivery_options_provider.dart';
import '../providers/orders_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isPlacing = false;

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    final selectedAddress = ref.read(selectedAddressProvider);

    if (selectedAddress == null) {
      showErrorSnackbar(context, 'Please select a delivery address');
      return;
    }
    if (cart.items.isEmpty) {
      showErrorSnackbar(context, 'Your cart is empty');
      return;
    }

    setState(() => _isPlacing = true);

    try {
      final ds = ref.read(customerDataSourceProvider);
      if (!requiresOnlinePayment(cart.total)) {
        final order = await ds.placeOrder({
          'items': cart.items
              .map(
                (item) => {
                  'product_id': item.productId,
                  'qty': item.quantity,
                  'size': item.selectedSize,
                  'image_url': item.customizationImageUrl,
                  'price': item.unitPrice,
                },
              )
              .toList(),
          'address_id': selectedAddress.id,
          'delivery_type': cart.deliveryTypeKey,
          'source': 'mobile_app',
          if (cart.couponCode != null) 'coupon_code': cart.couponCode,
        });
        ref.read(cartProvider.notifier).clearCart();
        ref.invalidate(myOrdersProvider);
        if (mounted) {
          context.go(AppRoutes.orderConfirmationPath(order.id));
        }
        return;
      }
      final checkoutPayload = {
        'items': cart.items
            .map(
              (item) => {
                'product_id': item.productId,
                'qty': item.quantity,
                'size': item.selectedSize,
                'image_url': item.customizationImageUrl,
              },
            )
            .toList(),
        'address_id': selectedAddress.id,
        'delivery_type': cart.deliveryTypeKey,
        if (cart.couponCode != null) 'coupon_code': cart.couponCode,
      };
      final razorpayOrder = await ds.createRazorpayOrder(checkoutPayload);

      if (mounted) {
        context.push(
          AppRoutes.payment,
          extra: {
            'amount': (razorpayOrder['amount'] as num).toDouble(),
            'razorpayOrderId': razorpayOrder['razorpay_order_id'] as String,
            'addressId': selectedAddress.id,
            'deliveryType': cart.deliveryTypeKey,
            'couponCode': cart.couponCode,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is AppException
            ? e.message
            : 'Something went wrong. Please try again.';
        showErrorSnackbar(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final addressAsync = ref.watch(addressProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final deliveryOptionsAsync = ref.watch(deliveryOptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const _CheckoutSteps(currentStep: 2),
                const SizedBox(height: 24),
                Text(
                  AppStrings.deliveryOptions,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                deliveryOptionsAsync.when(
                  loading: () =>
                      const LinearProgressIndicator(color: AppColors.accent),
                  error: (e, s) => Text(
                    '$e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (options) => Column(
                    children: options.map((option) {
                      final selected = cart.deliveryTypeKey == option.type;
                      return GestureDetector(
                        onTap: () => cartNotifier.setDeliveryOption(
                          option.type,
                          option.price,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.divider,
                              width: selected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.045),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      option.daysLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: selected
                                                ? Colors.white70
                                                : AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                option.price == 0
                                    ? AppStrings.free
                                    : '₹${option.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: option.price == 0
                                      ? AppColors.success
                                      : selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.deliveryAddress,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.address),
                      child: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                addressAsync.when(
                  loading: () =>
                      const LinearProgressIndicator(color: AppColors.accent),
                  error: (e, s) => Text(
                    '$e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return Container(
                        decoration: _checkoutCardDecoration(),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            leading: const Icon(
                              Icons.add_location_alt_outlined,
                              color: AppColors.accent,
                            ),
                            title: const Text('Add delivery address'),
                            onTap: () => context.push(AppRoutes.address),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: addresses.map((addr) {
                        final isSelected = selectedAddress?.id == addr.id;
                        return GestureDetector(
                          onTap: () =>
                              ref.read(selectedAddressProvider.notifier).state =
                                  addr,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.045),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textHint,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${addr.fullAddress}, ${addr.city} - ${addr.pincode}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Your Items',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                _CartItemsPreview(items: cart.items),
                const SizedBox(height: 24),

                Text(
                  AppStrings.orderSummary,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: _checkoutCardDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: '${cart.itemCount} item(s)',
                          value: '₹${cart.subtotal.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: AppStrings.deliveryCharge,
                          value: cart.deliveryCharge == 0
                              ? AppStrings.free
                              : '₹${cart.deliveryCharge.toStringAsFixed(0)}',
                        ),
                        if (cart.discount > 0) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: AppStrings.discount,
                            value: '- ₹${cart.discount.toStringAsFixed(0)}',
                            valueColor: AppColors.success,
                          ),
                        ],
                        const Divider(height: 20),
                        _SummaryRow(
                          label: AppStrings.total,
                          value: '₹${cart.total.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                      ],
                    ),
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
                decoration: _checkoutCardDecoration(radius: 28),
                child: CustomButton(
                  label: AppStrings.placeOrder,
                  isLoading: _isPlacing,
                  onPressed: _placeOrder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSteps extends StatelessWidget {
  const _CheckoutSteps({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = ['Bag', 'Address', 'Payment'];
    return Row(
      children: List.generate(steps.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (index != steps.length - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }
}

BoxDecoration _checkoutCardDecoration({double radius = 24}) {
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

class _CartItemsPreview extends StatelessWidget {
  const _CartItemsPreview({required this.items});
  final List<CartItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, idx) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final imageUrl = item.customizationImageUrl?.isNotEmpty == true
              ? item.customizationImageUrl!
              : item.productImageUrl.isNotEmpty
              ? item.productImageUrl
              : resolveCartProductImage(
                  item.productId,
                  productName: item.productName,
                );
          return Column(
            children: [
              PremiumNetworkImage(
                imageUrl: imageUrl,
                categoryId: categoryFromProductId(
                  item.productId,
                  fallbackName: item.productName,
                ),
                width: 76,
                height: 76,
                borderRadius: 10,
                cacheWidth: 180,
                cacheHeight: 180,
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 76,
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
