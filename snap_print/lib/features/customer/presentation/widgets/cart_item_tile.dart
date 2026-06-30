import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/utils/helpers.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../providers/cart_provider.dart';

class CartItemTile extends ConsumerWidget {
  const CartItemTile({super.key, required this.item});

  final CartItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);

    return Dismissible(
      key: ValueKey(item.cartItemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => cart.removeItem(item.cartItemId),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail: customization photo → catalog product image → gradient placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _ProductThumbnail(item: item),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.selectedSize,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Helpers.formatPrice(item.unitPrice * item.quantity),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        _QuantityStepper(
                          quantity: item.quantity,
                          onDecrement: () {
                            if (item.quantity > 1) {
                              cart.updateQuantity(
                                  item.cartItemId, item.quantity - 1);
                            } else {
                              cart.removeItem(item.cartItemId);
                            }
                          },
                          onIncrement: () => cart.updateQuantity(
                              item.cartItemId, item.quantity + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.item});
  final CartItemEntity item;

  List<Color> _gradientColors() {
    final cat = categoryFromProductId(item.productId);
    switch (cat) {
      case 'photo_prints':
        return [const Color(0xFF1B5E20), const Color(0xFF66BB6A)];
      case 'photo_books':
        return [const Color(0xFF4A148C), const Color(0xFFAB47BC)];
      case 'frames_wall_decor':
        return [const Color(0xFFB71C1C), const Color(0xFFEF5350)];
      case 'personalized_gifts':
        return [const Color(0xFF0D47A1), const Color(0xFF42A5F5)];
      default:
        return [AppColors.primaryDark, AppColors.primary];
    }
  }

  Widget _gradient() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_outlined, color: Colors.white54, size: 28),
      );

  @override
  Widget build(BuildContext context) {
    final catalogUrl = resolveCartProductImage(item.productId);

    // 1. User's customization photo (the actual print)
    if (item.customizationImageUrl != null &&
        item.customizationImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.customizationImageUrl!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => catalogUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: catalogUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, err) => _gradient(),
              )
            : _gradient(),
        errorWidget: (ctx, url, err) => catalogUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: catalogUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, err2) => _gradient(),
              )
            : _gradient(),
      );
    }

    // 2. Catalog product image
    if (catalogUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: catalogUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorWidget: (ctx, url, err) => _gradient(),
      );
    }

    // 3. Gradient placeholder
    return _gradient();
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
    return Row(
      children: [
        _StepButton(
          icon: quantity == 1 ? Icons.delete_outline : Icons.remove,
          color: quantity == 1 ? AppColors.error : AppColors.primary,
          onTap: onDecrement,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          color: AppColors.primary,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
