import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/core/network/api_client.dart';
import 'package:snap_print/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:snap_print/features/customer/data/models/product_model.dart';
import 'package:snap_print/features/customer/data/repositories/customer_repository_impl.dart';

class _PagedCatalogDataSource extends CustomerRemoteDataSource {
  _PagedCatalogDataSource(this.catalog) : super(ApiClient());

  final List<ProductModel> catalog;
  final requestedPages = <int>[];

  @override
  Future<List<ProductModel>> getProducts({
    String? category,
    bool? featured,
    bool? trending,
    int page = 1,
    int limit = 20,
  }) async {
    requestedPages.add(page);
    final filtered = category == null
        ? catalog
        : catalog.where((product) => product.categoryName == category).toList();
    final start = (page - 1) * limit;
    if (start >= filtered.length) return [];
    final end = (start + limit).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }
}

void main() {
  test('repository drains every product page for browse and search', () async {
    final products = List.generate(
      122,
      (index) => ProductModel(
        id: '$index',
        name: 'Product $index',
        categoryId: 'photo-books',
        categoryName: 'Photo Books',
        basePrice: index < 100 ? 99 : 0,
        sizes: const [],
        images: const [],
        isOrderable: index < 100,
      ),
    );
    final dataSource = _PagedCatalogDataSource(products);
    final repository = CustomerRepositoryImpl(dataSource);

    final result = await repository.getAllProducts();

    expect(result, hasLength(122));
    expect(result.last.name, 'Product 121');
    expect(result.last.isOrderable, isFalse);
    expect(dataSource.requestedPages, [1, 2]);
  });
}
