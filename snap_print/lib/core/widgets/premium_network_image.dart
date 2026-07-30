import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';
import '../constants/product_images.dart';

class PremiumNetworkImage extends StatelessWidget {
  const PremiumNetworkImage({
    super.key,
    required this.imageUrl,
    this.categoryId = '',
    this.width,
    this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.cacheWidth = 720,
    this.cacheHeight = 720,
    this.fadeInDuration = const Duration(milliseconds: 260),
  });

  final String imageUrl;
  final String categoryId;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final int cacheWidth;
  final int cacheHeight;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final url = imageUrl.trim();

    Widget child;
    if (url.isEmpty) {
      child = PremiumImagePlaceholder(categoryId: categoryId);
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: const Duration(milliseconds: 120),
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        maxWidthDiskCache: cacheWidth,
        maxHeightDiskCache: cacheHeight,
        filterQuality: FilterQuality.medium,
        placeholder: (context, url) =>
            const PremiumImageShimmer(borderRadius: 0),
        errorWidget: (context, url, error) =>
            PremiumImagePlaceholder(categoryId: categoryId),
      );
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}

class PremiumImageShimmer extends StatelessWidget {
  const PremiumImageShimmer({super.key, this.borderRadius = 0});
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class PremiumImagePlaceholder extends StatelessWidget {
  const PremiumImagePlaceholder({super.key, this.categoryId = ''});
  final String categoryId;

  IconData get _icon {
    switch (normalizeCategoryId(categoryId)) {
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent.withValues(alpha: 0.86)],
        ),
      ),
      child: Center(
        child: Icon(
          _icon,
          color: Colors.white.withValues(alpha: 0.34),
          size: 58,
        ),
      ),
    );
  }
}
