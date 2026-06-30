import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/product_entity.dart';
import '../repositories/customer_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';

class GetProductsUseCase {
  GetProductsUseCase(this._repository);
  final CustomerRepository _repository;

  Future<List<ProductEntity>> call({
    String? category,
    int page = 1,
    int limit = 20,
  }) =>
      _repository.getProducts(category: category, page: page, limit: limit);
}

final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  return GetProductsUseCase(ref.read(customerRepositoryProvider));
});
