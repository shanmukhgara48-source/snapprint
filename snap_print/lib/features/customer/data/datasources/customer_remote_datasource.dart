import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/address_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/offer_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class CustomerRemoteDataSource {
  CustomerRemoteDataSource(this._client);
  final ApiClient _client;

  Future<List<ProductModel>> getProducts({
    String? category,
    bool? featured,
    bool? trending,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (category != null) params['category'] = category;
    if (featured != null) params['featured'] = featured;
    if (trending != null) params['trending'] = trending;
    final response = await _client.get(
      ApiEndpoints.products,
      queryParameters: params,
    );
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await _client.get(ApiEndpoints.productDetail(id));
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get(ApiEndpoints.categories);
    final items = response.data as List<dynamic>;
    return items
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BannerModel>> getBanners() async {
    final response = await _client.get(ApiEndpoints.banners);
    final items = response.data as List<dynamic>;
    return items
        .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OfferModel>> getActiveOffers() async {
    final response = await _client.get(ApiEndpoints.activeOffers);
    final items = response.data as List<dynamic>;
    return items
        .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> calculateCart(
      List<Map<String, dynamic>> items) async {
    final response =
        await _client.post(ApiEndpoints.cartCalculate, data: {'items': items});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> validateCoupon(
      String code, double subtotal) async {
    final response = await _client.post(
      ApiEndpoints.couponValidate,
      data: {'code': code, 'subtotal': subtotal},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<AddressModel>> getAddresses() async {
    final response = await _client.get(ApiEndpoints.addresses);
    final items = response.data as List<dynamic>;
    return items
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddressModel> createAddress(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.addresses, data: data);
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AddressModel> updateAddress(
      String id, Map<String, dynamic> data) async {
    final response =
        await _client.put(ApiEndpoints.addressDetail(id), data: data);
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) =>
      _client.delete(ApiEndpoints.addressDetail(id));

  Future<void> setDefaultAddress(String id) =>
      _client.put(ApiEndpoints.addressSetDefault(id));

  Future<Map<String, dynamic>> createRazorpayOrder(double amount) async {
    final response = await _client.post(
      ApiEndpoints.razorpayCreateOrder,
      data: {'amount': amount},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(
      Map<String, dynamic> data) async {
    final response =
        await _client.post(ApiEndpoints.razorpayVerify, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<OrderModel> placeOrder(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.orders, data: data);
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final response = await _client.get(ApiEndpoints.myOrders);
    final items = response.data as List<dynamic>;
    return items
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> getOrderById(String id) async {
    final response = await _client.get(ApiEndpoints.orderDetail(id));
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final customerDataSourceProvider = Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSource(ref.read(apiClientProvider));
});
