import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/address_entity.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/offer_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._dataSource);
  final CustomerRemoteDataSource _dataSource;

  @override
  Future<List<ProductEntity>> getProducts({
    String? category,
    bool? featured,
    bool? trending,
    int page = 1,
    int limit = 20,
  }) => _dataSource.getProducts(
    category: category,
    featured: featured,
    trending: trending,
    page: page,
    limit: limit,
  );

  @override
  Future<List<ProductEntity>> getAllProducts({String? category}) async {
    const pageSize = 100;
    final products = <ProductEntity>[];
    var page = 1;

    while (true) {
      final batch = await _dataSource.getProducts(
        category: category,
        page: page,
        limit: pageSize,
      );
      products.addAll(batch);
      if (batch.length < pageSize) return products;
      page += 1;
    }
  }

  @override
  Future<ProductEntity> getProductById(String id) =>
      _dataSource.getProductById(id);

  @override
  Future<List<CategoryEntity>> getCategories() => _dataSource.getCategories();

  @override
  Future<List<BannerEntity>> getBanners() => _dataSource.getBanners();

  @override
  Future<List<OfferEntity>> getActiveOffers() => _dataSource.getActiveOffers();

  @override
  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal) =>
      _dataSource.validateCoupon(code, subtotal);

  @override
  Future<List<AddressEntity>> getAddresses() => _dataSource.getAddresses();

  @override
  Future<AddressEntity> createAddress(Map<String, dynamic> data) =>
      _dataSource.createAddress(data);

  @override
  Future<AddressEntity> updateAddress(String id, Map<String, dynamic> data) =>
      _dataSource.updateAddress(id, data);

  @override
  Future<void> deleteAddress(String id) => _dataSource.deleteAddress(id);

  @override
  Future<void> setDefaultAddress(String id) =>
      _dataSource.setDefaultAddress(id);

  @override
  Future<Map<String, dynamic>> createRazorpayOrder(Map<String, dynamic> data) =>
      _dataSource.createRazorpayOrder(data);

  @override
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) =>
      _dataSource.verifyPayment(data);

  @override
  Future<OrderEntity> placeOrder(Map<String, dynamic> data) =>
      _dataSource.placeOrder(data);

  @override
  Future<List<OrderEntity>> getMyOrders() => _dataSource.getMyOrders();

  @override
  Future<OrderEntity> getOrderById(String id) => _dataSource.getOrderById(id);
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.read(customerDataSourceProvider));
});
