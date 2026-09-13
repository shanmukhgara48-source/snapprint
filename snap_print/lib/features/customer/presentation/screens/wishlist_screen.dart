import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../providers/social_providers.dart';
import '../widgets/product_card.dart';

/// Amazon "List": saved products, synced across web and app.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(wishlistProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              const Text('Please sign in to view your wishlist.'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 56,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nothing saved yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap the heart on any product to keep it here.'),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.customerHome),
                      child: const Text(AppStrings.continueShopping),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(wishlistProvider.notifier).refresh();
              ref.invalidate(wishlistProductsProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) => ProductCard(product: products[i]),
            ),
          );
        },
      ),
    );
  }
}
