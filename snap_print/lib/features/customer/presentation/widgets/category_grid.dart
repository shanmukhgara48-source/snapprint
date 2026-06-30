import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

class _CategoryItem {
  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.darkColor,
    required this.categoryId,
    required this.subtitle,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Color darkColor;
  final String categoryId;
  final String subtitle;
}

const _categories = [
  _CategoryItem(
    label: 'Photo Prints',
    icon: Icons.photo_rounded,
    color: Color(0xFF43A047),
    darkColor: Color(0xFF1B5E20),
    categoryId: 'photo_prints',
    subtitle: '6 products',
  ),
  _CategoryItem(
    label: 'Photo Books',
    icon: Icons.photo_album_rounded,
    color: Color(0xFFAB47BC),
    darkColor: Color(0xFF4A148C),
    categoryId: 'photo_books',
    subtitle: '8 products',
  ),
  _CategoryItem(
    label: 'Frames & Wall Decor',
    icon: Icons.crop_rounded,
    color: Color(0xFFEF5350),
    darkColor: Color(0xFFB71C1C),
    categoryId: 'frames_wall_decor',
    subtitle: '30 products',
  ),
  _CategoryItem(
    label: 'Personalised Gifts',
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFF42A5F5),
    darkColor: Color(0xFF0D47A1),
    categoryId: 'personalized_gifts',
    subtitle: '25 products',
  ),
];

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
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
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return GestureDetector(
          onTap: () => context.push(AppRoutes.productListPath(cat.categoryId)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cat.color, cat.darkColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cat.darkColor.withValues(alpha: 0.40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative large icon in background
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    cat.icon,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon chip
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.icon, color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        cat.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            cat.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
      },
    );
  }
}
