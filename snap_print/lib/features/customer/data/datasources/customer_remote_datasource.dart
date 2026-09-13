import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/address_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/offer_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

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
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _client.post(
      ApiEndpoints.cartCalculate,
      data: {'items': items},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> validateCoupon(
    String code,
    double subtotal,
  ) async {
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
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      ApiEndpoints.addressDetail(id),
      data: data,
    );
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) =>
      _client.delete(ApiEndpoints.addressDetail(id));

  Future<void> setDefaultAddress(String id) =>
      _client.put(ApiEndpoints.addressSetDefault(id));

  Future<Map<String, dynamic>> createRazorpayOrder(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      ApiEndpoints.razorpayCreateOrder,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiEndpoints.razorpayVerify,
      data: data,
    );
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

  // ── Amazon parity: reviews, wishlist, returns, discovery ──

  Future<ReviewSummaryModel> getReviewSummary(String productId) async {
    final response = await _client.get(
      ApiEndpoints.productReviewSummary(productId),
    );
    return ReviewSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ReviewModel>> getReviews(
    String productId, {
    String sort = 'helpful',
  }) async {
    final response = await _client.get(
      ApiEndpoints.productReviews(productId),
      queryParameters: {'sort': sort},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> createReview(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      ApiEndpoints.productReviews(productId),
      data: data,
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReviewModel> voteHelpful(String reviewId, bool currentlyVoted) async {
    // Backend toggles; we return a lightweight copy — callers refetch lists.
    final response = await _client.post(ApiEndpoints.reviewHelpful(reviewId));
    final data = response.data as Map<String, dynamic>;
    return ReviewModel(
      id: reviewId,
      productId: '',
      rating: 0,
      title: '',
      body: '',
      reviewer: '',
      verifiedPurchase: false,
      helpfulCount: (data['helpful_count'] as num).toInt(),
      voted: data['voted'] as bool? ?? !currentlyVoted,
      createdAt: DateTime.now(),
    );
  }

  Future<Map<String, Map<String, double>>> getBatchRatings(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    final response = await _client.post(
      ApiEndpoints.productsRatings,
      data: {'ids': ids},
    );
    final raw = response.data as Map<String, dynamic>;
    return {
      for (final e in raw.entries)
        e.key: {
          'avg': ((e.value as Map)['avg'] as num).toDouble(),
          'count': ((e.value as Map)['count'] as num).toDouble(),
        },
    };
  }

  Future<List<ProductModel>> getBoughtTogether(String productId) async {
    final response = await _client.get(
      ApiEndpoints.productBoughtTogether(productId),
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> getWishlist() async {
    final response = await _client.get(ApiEndpoints.wishlist);
    final items = response.data as List<dynamic>;
    return items
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getWishlistIds() async {
    final response = await _client.get(ApiEndpoints.wishlistIds);
    final ids = (response.data as Map<String, dynamic>)['product_ids'] as List;
    return ids.map((e) => e.toString()).toSet();
  }

  Future<void> addToWishlist(String productId) =>
      _client.post(ApiEndpoints.wishlistItem(productId));

  Future<void> removeFromWishlist(String productId) =>
      _client.delete(ApiEndpoints.wishlistItem(productId));

  Future<Map<String, dynamic>> requestReturn(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.returns, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMyReturns() async {
    final response = await _client.get(ApiEndpoints.myReturns);
    final items = response.data as List<dynamic>;
    return items.map((e) => e as Map<String, dynamic>).toList();
  }
}

final customerDataSourceProvider = Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSource(ref.read(apiClientProvider));
});
