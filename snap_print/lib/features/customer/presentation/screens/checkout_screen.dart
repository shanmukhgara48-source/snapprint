import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/delivery_options_provider.dart';

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
      final razorpayOrder = await ds.createRazorpayOrder(cart.total);

      if (mounted) {
        context.push(AppRoutes.payment, extra: {
          'amount': (razorpayOrder['amount'] as num).toDouble(),
          'razorpayOrderId': razorpayOrder['razorpay_order_id'] as String,
          'addressId': selectedAddress.id,
          'deliveryType': cart.deliveryTypeKey,
          'couponCode': cart.couponCode,
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e is AppException ? e.message : 'Something went wrong. Please try again.';
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
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Delivery Options
                Text(AppStrings.deliveryOptions,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                deliveryOptionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text('$e',
                      style: const TextStyle(color: AppColors.error)),
                  data: (options) => Column(
                    children: options.map((option) {
                      final selected = cart.deliveryTypeKey == option.type;
                      return GestureDetector(
                        onTap: () => cartNotifier.setDeliveryOption(
                            option.type, option.price),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accentLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(option.label,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(option.daysLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
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
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
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

                // Delivery Address
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.deliveryAddress,
                        style: Theme.of(context).textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.address),
                      child: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                addressAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) =>
                      Text('$e', style: const TextStyle(color: AppColors.error)),
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.add_location_alt_outlined,
                              color: AppColors.primary),
                          title: const Text('Add delivery address'),
                          onTap: () => context.push(AppRoutes.address),
                        ),
                      );
                    }
                    return Column(
                      children: addresses.map((addr) {
                        final isSelected = selectedAddress?.id == addr.id;
                        return GestureDetector(
                          onTap: () => ref
                              .read(selectedAddressProvider.notifier)
                              .state = addr,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentLight
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${addr.fullAddress}, ${addr.city} - ${addr.pincode}',
                                    style: const TextStyle(fontSize: 13),
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

                // Items preview
                Text('Your Items',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                _CartItemsPreview(items: cart.items),
                const SizedBox(height: 24),

                // Order Summary
                Text(AppStrings.orderSummary,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SummaryRow(
                            label: '${cart.itemCount} item(s)',
                            value: '₹${cart.subtotal.toStringAsFixed(0)}'),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: CustomButton(
                label: AppStrings.placeOrder,
                isLoading: _isPlacing,
                onPressed: _placeOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              : resolveCartProductImage(item.productId);
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) =>
                            _imgPlaceholder(item.productId),
                      )
                    : _imgPlaceholder(item.productId),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 76,
                child: Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
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

  Widget _imgPlaceholder(String productId) {
    final cat = categoryFromProductId(productId);
    final colors = switch (cat) {
      'photo_prints' => [const Color(0xFF1B5E20), const Color(0xFF66BB6A)],
      'photo_books' => [const Color(0xFF4A148C), const Color(0xFFAB47BC)],
      'frames_wall_decor' => [const Color(0xFFB71C1C), const Color(0xFFEF5350)],
      'personalized_gifts' => [const Color(0xFF0D47A1), const Color(0xFF42A5F5)],
      _ => [AppColors.primaryDark, AppColors.primary],
    };
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.white54, size: 28),
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
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor)),
      ],
    );
  }
}
