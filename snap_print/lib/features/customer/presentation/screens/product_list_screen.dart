import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/product_images.dart';
import '../providers/catalog_provider.dart';
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
        color: Color(0xFF43A047),
        darkColor: Color(0xFF1B5E20),
      );
    case 'photo_books':
      return const _CategoryMeta(
        title: 'Photo Books',
        description: 'Beautifully crafted books to relive your memories',
        icon: Icons.photo_album_rounded,
        color: Color(0xFFAB47BC),
        darkColor: Color(0xFF4A148C),
      );
    case 'frames_wall_decor':
      return const _CategoryMeta(
        title: 'Frames & Wall Decor',
        description: 'Stylish frames and wall art to decorate your space',
        icon: Icons.crop_rounded,
        color: Color(0xFFEF5350),
        darkColor: Color(0xFFB71C1C),
      );
    case 'personalized_gifts':
      return const _CategoryMeta(
        title: 'Personalised Gifts',
        description: 'Unique personalised gifts for every occasion',
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFF42A5F5),
        darkColor: Color(0xFF0D47A1),
      );
    default:
      return _CategoryMeta(
        title: _prettify(category),
        description: '',
        icon: Icons.image_outlined,
        color: AppColors.primary,
        darkColor: AppColors.primaryDark,
      );
  }
}

String _prettify(String slug) => slug
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(category));
    // `category` is a category id when navigated from the home grid; the
    // presentation metadata below is keyed by the category's slug name.
    final slug = ref.watch(categoriesProvider).maybeWhen(
          data: (cats) =>
              cats
                  .where((c) => c.id == category)
                  .map((c) => c.name)
                  .firstOrNull ??
              category,
          orElse: () => category,
        );
    final meta = _meta(slug);
    final bannerUrl = kCategoryBannerImages[slug] ?? '';

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, s) => Scaffold(
          appBar: AppBar(title: Text(meta.title)),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
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
                      // Category banner image
                      if (bannerUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: bannerUrl,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [meta.color, meta.darkColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [meta.color, meta.darkColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),

                      // Gradient overlay so title is readable
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
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
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 64, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('No products available'),
                      ],
                    ),
                  ),
                )
              else ...[
                // Product count
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${products.length} product${products.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Product grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ProductCard(product: products[i]),
                      childCount: products.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
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
