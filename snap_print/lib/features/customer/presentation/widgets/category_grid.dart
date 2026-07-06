import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/catalog_provider.dart';

const _iconMap = {
  'photo': Icons.photo_rounded,
  'coffee': Icons.coffee_rounded,
  'book': Icons.photo_album_rounded,
  'frame': Icons.crop_rounded,
  'tv': Icons.tv_rounded,
  'gift': Icons.card_giftcard_rounded,
};

const _gradientColors = [
  [Color(0xFF43A047), Color(0xFF1B5E20)],
  [Color(0xFFAB47BC), Color(0xFF4A148C)],
  [Color(0xFFEF5350), Color(0xFFB71C1C)],
  [Color(0xFF42A5F5), Color(0xFF0D47A1)],
];

class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
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
    return GestureDetector(
      onTap: () => context.push(AppRoutes.productListPath(category.name)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, darkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: darkColor.withValues(alpha: 0.40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    category.name.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withValues(alpha: 0.80),
                        size: 14,
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
