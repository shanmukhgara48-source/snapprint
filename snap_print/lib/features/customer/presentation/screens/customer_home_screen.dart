import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
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
        authState.valueOrNull?.displayName ?? authState.valueOrNull?.phone ?? '';
    final firstName =
        userName.isNotEmpty ? userName.trim().split(' ').first : 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $firstName 👋',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Text(
              AppStrings.appTagline,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
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
                      color: Colors.red,
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
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search prints, books, gifts…',
                  hintStyle: const TextStyle(
                      fontSize: 14, color: AppColors.textHint),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textHint),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close,
                              color: AppColors.textHint, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            if (_searchQuery.isNotEmpty)
              _SearchResults(query: _searchQuery)
            else ...[
              const SizedBox(height: 12),

              // Banner carousel
              const BannerCarousel(),
              const SizedBox(height: 16),

              // Offers strip
              const _OffersStrip(),
              const SizedBox(height: 12),

              // Categories section
              _SectionHeader(
                title: AppStrings.categories,
                onTap: null,
              ),
              const SizedBox(height: 12),
              const CategoryGrid(),
              const SizedBox(height: 28),

              // Featured Products section
              _ProductCarouselSection(
                title: 'Featured Products',
                provider: featuredProductsProvider,
              ),

              // Trending Products section
              _ProductCarouselSection(
                title: 'Trending Products',
                provider: trendingProductsProvider,
              ),

              // Recent Orders section
              _SectionHeader(
                title: AppStrings.recentOrders,
                onTap: () => context.push(AppRoutes.orderHistory),
                actionLabel: AppStrings.viewAll,
              ),
              const SizedBox(height: 8),
              ordersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child:
                      Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, s) => const SizedBox.shrink(),
                data: (orders) {
                  if (orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.divider, width: 1),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 44, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text(AppStrings.noOrders,
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Your orders will appear here',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.take(3).length,
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: AppColors.divider, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_outlined,
                                color: AppColors.primary),
                          ),
                          title: Text(
                            'Order #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${order.itemCount} item${order.itemCount != 1 ? 's' : ''} · ₹${order.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: OrderStatusChip(status: order.status),
                          onTap: () => context.push(
                              AppRoutes.orderConfirmationPath(order.id)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onTap,
    this.actionLabel,
  });
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
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
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
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
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
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 140,
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
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('No results for "$query"',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${products.length} result${products.length != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) =>
                    ProductCard(product: products[i]),
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
      error: (e, s) => const SizedBox.shrink(),
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: offers.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final offer = offers[i];
              final discount = offer.discountType == 'percent'
                  ? '${offer.value.toStringAsFixed(0)}% OFF'
                  : '₹${offer.value.toStringAsFixed(0)} OFF';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${offer.code} · $discount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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
