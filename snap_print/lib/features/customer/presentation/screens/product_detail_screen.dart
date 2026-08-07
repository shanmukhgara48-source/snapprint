import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/premium_network_image.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.productDetails),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load product',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(productId)),
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
    if (_selectedSizeIndex != null && widget.product.sizes.isNotEmpty) {
      return widget.product.sizes[_selectedSizeIndex!].price;
    }
    return widget.product.effectivePrice;
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
                // Hero image: backend image wins; premium resolver covers empty catalogs.
                AspectRatio(
                  aspectRatio: 1.2,
                  child: PremiumNetworkImage(
                    imageUrl: resolveNetworkProductImage(
                      productId: product.id,
                      categoryId: product.categoryName,
                      productName: product.name,
                      description: product.description,
                      imageUrl: product.imageUrl,
                    ),
                    categoryId: product.categoryName,
                    cacheWidth: 1080,
                    cacheHeight: 900,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        product.priceLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                      if (!product.isOrderable) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'This product is available to explore while pricing is finalized.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (!product.isInStock) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Currently out of stock',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],

                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          product.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],

                      if (product.sizes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.selectSize,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(product.sizes.length, (i) {
                            final size = product.sizes[i];
                            final isSelected = _selectedSizeIndex == i;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSizeIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.divider,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.10,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ]
                                      : null,
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
                          }),
                        ),
                      ],

                      // Material
                      if (product.material != null &&
                          product.material!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _InfoRow(
                          icon: Icons.layers_outlined,
                          label: 'Material',
                          value: product.material!,
                        ),
                      ],

                      if (product.dimensions != null &&
                          product.dimensions!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.straighten_rounded,
                          label: 'Dimensions',
                          value: product.dimensions!,
                        ),
                      ],

                      if (product.optionsSummary != null &&
                          product.optionsSummary!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.tune_rounded,
                          label: 'Options',
                          value: product.optionsSummary!,
                        ),
                      ],

                      // Delivery
                      if (product.deliveryInfo != null &&
                          product.deliveryInfo!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Delivery',
                          value: product.deliveryInfo!,
                        ),
                      ],

                      if (product.priceNote != null &&
                          product.priceNote!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Pricing',
                          value: product.priceNote!,
                        ),
                      ],

                      const SizedBox(height: 20),
                      const _GuaranteeGrid(),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          product.hasKnownPrice
                              ? '₹${_selectedPrice.toStringAsFixed(0)}'
                              : 'Not priced',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      label: !product.isOrderable || !product.hasKnownPrice
                          ? 'Pricing coming soon'
                          : product.isInStock
                          ? AppStrings.customize
                          : 'Out of stock',
                      icon: Icons.edit_rounded,
                      onPressed: product.canOrder
                          ? () => context.push(
                              AppRoutes.customize,
                              extra: {
                                'productId': product.id,
                                'productName': product.name,
                                'preselectedSize':
                                    _selectedSizeIndex != null &&
                                        product.sizes.isNotEmpty
                                    ? product.sizes[_selectedSizeIndex!].label
                                    : null,
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GuaranteeGrid extends StatelessWidget {
  const _GuaranteeGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.workspace_premium_rounded, 'Archival finish'),
      (Icons.local_shipping_rounded, 'Tracked delivery'),
      (Icons.verified_user_rounded, 'Secure checkout'),
      (Icons.auto_awesome_rounded, 'Expert color care'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(item.$1, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
