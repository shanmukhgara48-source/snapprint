import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/premium_network_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/products_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_grid.dart';
import '../widgets/order_status_chip.dart';
import '../widgets/product_card.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _lastResumeRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final lastRefresh = _lastResumeRefresh;
      if (lastRefresh != null &&
          now.difference(lastRefresh) < const Duration(minutes: 2)) {
        return;
      }
      _lastResumeRefresh = now;
      _refreshAll();
    }
  }

  void _refreshAll() {
    ref.invalidate(myOrdersProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(bannersProvider);
    ref.invalidate(offersProvider);
    ref.invalidate(featuredProductsProvider);
    ref.invalidate(trendingProductsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);
    final ordersAsync = ref.watch(myOrdersProvider);

    final userName =
        authState.valueOrNull?.displayName ??
        authState.valueOrNull?.phone ??
        '';
    final firstName = userName.isNotEmpty
        ? userName.trim().split(' ').first
        : 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $firstName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              AppStrings.appTagline,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.push(AppRoutes.cart),
              ),
              if (cartState.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${cartState.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _refreshAll(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 112),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search prints, books, gifts…',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            if (_searchQuery.isNotEmpty)
              _SearchResults(query: _searchQuery)
            else ...[
              const SizedBox(height: 14),
              const _EditorialHero(),
              const SizedBox(height: 18),
              const BannerCarousel(),
              const SizedBox(height: 18),
              const _OffersStrip(),
              const SizedBox(height: 18),
              const _ServiceHighlights(),
              const SizedBox(height: 24),

              _SectionHeader(title: AppStrings.categories, onTap: null),
              const SizedBox(height: 12),
              const CategoryGrid(),
              const SizedBox(height: 30),

              _ProductCarouselSection(
                title: 'Featured Prints',
                provider: featuredProductsProvider,
              ),

              _ProductCarouselSection(
                title: 'Trending Products',
                provider: trendingProductsProvider,
              ),

              _SectionHeader(
                title: AppStrings.recentOrders,
                onTap: () => context.push(AppRoutes.orderHistory),
                actionLabel: AppStrings.viewAll,
              ),
              const SizedBox(height: 8),
              ordersAsync.when(
                loading: () => const _RecentOrderSkeleton(),
                error: (e, s) => _InlineErrorRow(
                  message: "Couldn't load your orders.",
                  onRetry: () => ref.invalidate(myOrdersProvider),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: _PremiumEmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: AppStrings.noOrders,
                        subtitle:
                            'Your handcrafted print orders will appear here.',
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: orders.take(3).length,
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: _luxuryCardDecoration(),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: const _GoldIconBubble(
                              icon: Icons.receipt_long_rounded,
                            ),
                            title: Text(
                              'Order #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}  •  ₹${order.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: OrderStatusChip(status: order.status),
                            onTap: () => context.push(
                              AppRoutes.orderConfirmationPath(order.id),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

BoxDecoration _luxuryCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AppColors.divider),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.045),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

class _EditorialHero extends StatelessWidget {
  const _EditorialHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PremiumNetworkImage(
            imageUrl: kCategoryBannerImages['photo_books']!,
            categoryId: 'photo_books',
            borderRadius: 28,
            cacheWidth: 1200,
            cacheHeight: 720,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Text(
                    'Museum-grade printing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Print Your\nMemories',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 38,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium photo books, gallery prints, frames, and gifts crafted with archival finishes.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 170,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.productListPath('photo_prints')),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: const Text('Start Printing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceHighlights extends StatelessWidget {
  const _ServiceHighlights();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_rounded, 'Fast delivery'),
      (Icons.verified_rounded, 'Archival quality'),
      (Icons.lock_rounded, 'Secure payment'),
      (Icons.star_rounded, '4.9 rated'),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 134,
            padding: const EdgeInsets.all(14),
            decoration: _luxuryCardDecoration(),
            child: Row(
              children: [
                _GoldIconBubble(icon: item.$1, size: 36, iconSize: 17),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GoldIconBubble extends StatelessWidget {
  const _GoldIconBubble({
    required this.icon,
    this.size = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(size / 2.6),
      ),
      child: Icon(icon, color: AppColors.accent, size: iconSize),
    );
  }
}

class _InlineErrorRow extends StatelessWidget {
  const _InlineErrorRow({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: GestureDetector(
        onTap: onRetry,
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$message Tap to retry.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap, this.actionLabel});
  final String title;
  final VoidCallback? onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (onTap != null && actionLabel != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCarouselSection extends ConsumerWidget {
  const _ProductCarouselSection({required this.title, required this.provider});
  final String title;
  final FutureProvider<List<ProductEntity>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(provider);

    return productsAsync.when(
      loading: () => _ProductCarouselSkeleton(title: title),
      error: (e, s) => _InlineErrorRow(
        message: "Couldn't load $title.",
        onRetry: () => ref.invalidate(provider),
      ),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: title, onTap: null),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  key: ValueKey('product-carousel-$title'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: products.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => SizedBox(
                    width: 168,
                    child: ProductCard(product: products[i]),
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

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchProductsProvider(query));

    return resultsAsync.when(
      loading: () => const _SearchSkeleton(),
      error: (e, s) => _InlineErrorRow(
        message: 'Search failed.',
        onRetry: () => ref.invalidate(searchProductsProvider(query)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: _PremiumEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results for "$query"',
              subtitle: 'Try photo prints, albums, frames, mugs, or calendars.',
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${products.length} result${products.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.76,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) => ProductCard(product: products[i]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OffersStrip extends ConsumerWidget {
  const _OffersStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);

    return offersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => _InlineErrorRow(
        message: "Couldn't load offers.",
        onRetry: () => ref.invalidate(offersProvider),
      ),
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 46,
          child: ListView.separated(
            key: const ValueKey('offers-strip'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: offers.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final offer = offers[i];
              final discount = offer.discountType == 'percent'
                  ? '${offer.value.toStringAsFixed(0)}% OFF'
                  : '₹${offer.value.toStringAsFixed(0)} OFF';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${offer.code} · $discount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  const _PremiumEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: _luxuryCardDecoration(),
      child: Column(
        children: [
          _GoldIconBubble(icon: icon, size: 58, iconSize: 27),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProductCarouselSkeleton extends StatelessWidget {
  const _ProductCarouselSkeleton({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, _) =>
                  const _ShimmerBlock(width: 168, height: 230),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderSkeleton extends StatelessWidget {
  const _RecentOrderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: _ShimmerBlock(width: double.infinity, height: 82),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.76,
        ),
        itemCount: 4,
        itemBuilder: (_, _) =>
            const _ShimmerBlock(width: double.infinity, height: 220),
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
