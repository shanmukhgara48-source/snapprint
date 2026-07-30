import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/widgets/premium_network_image.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

class _CategoryMeta {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color darkColor;

  const _CategoryMeta({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.darkColor,
  });
}

_CategoryMeta _meta(String category) {
  switch (category) {
    case 'photo_prints':
      return const _CategoryMeta(
        title: 'Photo Prints',
        description: 'Premium quality prints from your favourite photos',
        icon: Icons.photo_rounded,
        color: Color(0xFFC9A227),
        darkColor: Color(0xFF111111),
      );
    case 'photo_books':
      return const _CategoryMeta(
        title: 'Photo Books',
        description: 'Beautifully crafted books to relive your memories',
        icon: Icons.photo_album_rounded,
        color: Color(0xFFE9DDC4),
        darkColor: Color(0xFF302A25),
      );
    case 'frames_wall_decor':
      return const _CategoryMeta(
        title: 'Frames & Wall Decor',
        description: 'Stylish frames and wall art to decorate your space',
        icon: Icons.crop_rounded,
        color: Color(0xFF77716A),
        darkColor: Color(0xFF111111),
      );
    case 'personalized_gifts':
      return const _CategoryMeta(
        title: 'Personalised Gifts',
        description: 'Unique personalised gifts for every occasion',
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFFD6BE77),
        darkColor: Color(0xFF252A2D),
      );
    default:
      return _CategoryMeta(
        title: category,
        description: '',
        icon: Icons.image_outlined,
        color: AppColors.primary,
        darkColor: AppColors.primaryDark,
      );
  }
}

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(category));
    final meta = _meta(category);
    final bannerUrl = kCategoryBannerImages[normalizeCategoryId(category)] ?? '';

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, s) => Scaffold(
          appBar: AppBar(title: Text(meta.title)),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                const Text('Failed to load products'),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(productsProvider(category)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (products) {
          return CustomScrollView(
            slivers: [
              // Hero category header
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: meta.darkColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    meta.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PremiumNetworkImage(
                        imageUrl: bannerUrl,
                        categoryId: category,
                        cacheWidth: 1200,
                        cacheHeight: 720,
                      ),

                      // Gradient overlay so title is readable
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.10),
                              meta.darkColor.withValues(alpha: 0.85),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),

                      // Decorative icon
                      Positioned(
                        right: 24,
                        top: 32,
                        child: Icon(
                          meta.icon,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_rounded,
                            size: 64,
                            color: AppColors.accent,
                          ),
                          SizedBox(height: 12),
                          Text('No products available'),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Product count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${products.length} product${products.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Product grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 112),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ProductCard(product: products[i]),
                      childCount: products.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.76,
                        ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
