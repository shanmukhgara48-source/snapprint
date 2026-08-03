import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/premium_network_image.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/catalog_provider.dart';

const _iconMap = {
  'image': Icons.photo_rounded,
  'photo': Icons.photo_rounded,
  'coffee': Icons.coffee_rounded,
  'book': Icons.photo_album_rounded,
  'frame': Icons.crop_rounded,
  'tv': Icons.tv_rounded,
  'gift': Icons.card_giftcard_rounded,
};

const _gradientColors = [
  [Color(0xFF111111), Color(0xFFC9A227)],
  [Color(0xFF302A25), Color(0xFFE9DDC4)],
  [Color(0xFF1B1B1B), Color(0xFF77716A)],
  [Color(0xFF252A2D), Color(0xFFD6BE77)],
];

class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const _CategorySkeleton(),
      error: (e, s) => _CategoryMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Categories unavailable',
        message: e.toString(),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(categoriesProvider),
      ),
      data: (categories) {
        assert(() {
          debugPrint('CategoryGrid received ${categories.length} categories');
          return true;
        }());
        final visibleCategories = categories
            .where((category) => category.isActive)
            .toList();
        if (visibleCategories.isEmpty) {
          return const _CategoryMessage(
            icon: Icons.category_outlined,
            title: 'No categories yet',
            message: 'New print categories will appear here soon.',
          );
        }
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final cardHeight = 180.0 + ((textScale - 1) * 60).clamp(0.0, 60.0);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: cardHeight,
          ),
          itemCount: visibleCategories.length,
          itemBuilder: (context, index) {
            final cat = visibleCategories[index];
            final colors = _gradientColors[index % _gradientColors.length];
            final icon = _iconMap[cat.icon] ?? Icons.category_rounded;
            return _CategoryCard(
              category: cat,
              icon: icon,
              color: colors[0],
              darkColor: colors[1],
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.color,
    required this.darkColor,
  });

  final CategoryEntity category;
  final IconData icon;
  final Color color;
  final Color darkColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        category.imageUrl ??
        kCategoryBannerImages[normalizeCategoryId(category.name)] ??
        '';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.productListPath(category.name)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, darkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: PremiumNetworkImage(
                imageUrl: imageUrl,
                categoryId: category.name,
                cacheWidth: 520,
                cacheHeight: 420,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      color.withValues(alpha: 0.54),
                      darkColor.withValues(alpha: 0.76),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -8,
              bottom: -12,
              child: Icon(
                icon,
                size: 92,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    category.name.replaceAll('_', ' '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Explore',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withValues(alpha: 0.80),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 12),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.08,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9E2),
          borderRadius: BorderRadius.circular(26),
        ),
      ),
    );
  }
}
