import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    // Prefer URL stored in Firestore; fall back to local map
    final imageUrl = product.imageUrl.isNotEmpty
        ? product.imageUrl
        : resolveProductImage(product.id, product.categoryId);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetailPath(product.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or gradient placeholder
              imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.shimmerBase,
                        highlightColor: AppColors.shimmerHighlight,
                        child: Container(color: AppColors.shimmerBase),
                      ),
                      errorWidget: (context, url, error) =>
                          _GradientPlaceholder(categoryId: product.categoryId),
                    )
                  : _GradientPlaceholder(categoryId: product.categoryId),

              // Bottom gradient for text legibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.35, 0.58, 1.0],
                    ),
                  ),
                ),
              ),

              // Price badge — top right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    product.priceLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              // Product name — bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.categoryId});
  final String categoryId;

  List<Color> get _colors {
    switch (categoryId) {
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
    switch (categoryId) {
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
        child: Icon(
          _icon,
          color: Colors.white.withValues(alpha: 0.30),
          size: 60,
        ),
      ),
    );
  }
}
