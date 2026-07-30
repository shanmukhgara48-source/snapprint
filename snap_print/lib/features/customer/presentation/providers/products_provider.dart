import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/product_entity.dart';

final productsProvider = FutureProvider.family<List<ProductEntity>, String?>((
  ref,
  categoryId,
) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getProducts(category: categoryId, limit: 100);
});

final featuredProductsProvider = FutureProvider<List<ProductEntity>>((
  ref,
) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getProducts(featured: true, limit: 20);
});

final trendingProductsProvider = FutureProvider<List<ProductEntity>>((
  ref,
) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getProducts(trending: true, limit: 20);
});

final productDetailProvider = FutureProvider.family<ProductEntity, String>((
  ref,
  id,
) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getProductById(id);
});

final searchProductsProvider =
    FutureProvider.family<List<ProductEntity>, String>((ref, query) async {
      if (query.trim().isEmpty) return [];
      final products = await ref.watch(productsProvider(null).future);
      final lower = query.trim().toLowerCase();
      return products
          .where(
            (p) =>
                p.name.toLowerCase().contains(lower) ||
                p.categoryName.toLowerCase().contains(lower) ||
                (p.description?.toLowerCase().contains(lower) ?? false),
          )
          .toList();
    });
