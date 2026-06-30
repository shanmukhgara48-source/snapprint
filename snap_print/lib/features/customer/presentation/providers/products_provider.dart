import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firestore_product_datasource.dart';
import '../../domain/entities/product_entity.dart';

final productsProvider = FutureProvider.family<List<ProductEntity>, String?>(
  (ref, categoryId) async {
    final ds = ref.read(firestoreProductDataSourceProvider);
    return ds.getProducts(categoryId: categoryId);
  },
);

final productDetailProvider =
    FutureProvider.family<ProductEntity, String>((ref, id) async {
  final ds = ref.read(firestoreProductDataSourceProvider);
  return ds.getProductById(id);
});

final searchProductsProvider =
    FutureProvider.family<List<ProductEntity>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final ds = ref.read(firestoreProductDataSourceProvider);
  return ds.searchProducts(query.trim());
});
