import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/social_providers.dart';
import 'product_card.dart';

/// Amazon's "Frequently bought together" from real co-purchase history.
class BoughtTogetherStrip extends ConsumerWidget {
  const BoughtTogetherStrip({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(boughtTogetherProvider(productId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, s) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently bought together',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, s) => const SizedBox(width: 10),
                itemBuilder: (context, i) => SizedBox(
                  width: 160,
                  child: ProductCard(product: products[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
