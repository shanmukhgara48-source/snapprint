import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.productDetails)),
      body: productAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, s) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load product',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(productDetailProvider(productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (product) => _ProductDetailBody(product: product),
      ),
    );
  }
}

class _ProductDetailBody extends StatefulWidget {
  const _ProductDetailBody({required this.product});
  final ProductEntity product;

  @override
  State<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<_ProductDetailBody> {
  int? _selectedSizeIndex;

  double get _selectedPrice {
    if (_selectedSizeIndex != null &&
        widget.product.sizes.isNotEmpty) {
      return widget.product.sizes[_selectedSizeIndex!].price;
    }
    return widget.product.basePrice;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image — prefer Firestore URL, fall back to local map
                AspectRatio(
                  aspectRatio: 1.2,
                  child: () {
                    final imageUrl = product.imageUrl.isNotEmpty
                        ? product.imageUrl
                        : resolveProductImage(product.id, product.categoryId);
                    return imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(
                              color: AppColors.accentLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (ctx, url, err) =>
                                _PlaceholderImage(category: product.categoryId),
                          )
                        : _PlaceholderImage(category: product.categoryId);
                  }(),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Name
                      Text(product.name,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),

                      // Price
                      Text(
                        'Starting from ₹${product.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),

                      // Description
                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(product.description!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],

                      // Sizes
                      if (product.sizes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(AppStrings.selectSize,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            product.sizes.length,
                            (i) {
                              final size = product.sizes[i];
                              final isSelected = _selectedSizeIndex == i;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedSizeIndex = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    '${size.label}  ₹${size.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Material
                      if (product.material != null &&
                          product.material!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _InfoRow(
                          icon: Icons.layers_outlined,
                          label: 'Material',
                          value: product.material!,
                        ),
                      ],

                      // Delivery
                      if (product.deliveryInfo != null &&
                          product.deliveryInfo!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Delivery',
                          value: product.deliveryInfo!,
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // CTA
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        '₹${_selectedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    label: AppStrings.customize,
                    icon: Icons.edit_rounded,
                    onPressed: () => context.push(
                      AppRoutes.customize,
                      extra: {
                        'productId': product.id,
                        'productName': product.name,
                        'preselectedSize': _selectedSizeIndex != null &&
                                product.sizes.isNotEmpty
                            ? product.sizes[_selectedSizeIndex!].label
                            : null,
                      },
                    ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.category});
  final String category;

  List<Color> get _colors {
    switch (category) {
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

  IconData get _icon {
    switch (category) {
      case 'photo_prints':
        return Icons.photo_rounded;
      case 'photo_books':
        return Icons.photo_album_rounded;
      case 'frames_wall_decor':
        return Icons.crop_rounded;
      case 'personalized_gifts':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(_icon, size: 80, color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }
}
