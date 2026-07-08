import 'package:dio/dio.dart';

/// Thin HTTP client that drives the exact same REST endpoints the admin-web
/// React panel calls. admin-web has no client-side business logic beyond
/// hitting these routes, so an authenticated call here is functionally
/// equivalent to an admin clicking the corresponding button in the panel.
class AdminApi {
  AdminApi({required this.baseUrl});
  final String baseUrl;
  late final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  String? _token;

  Future<void> login({String username = 'admin', String password = 'TempAudit2026!'}) async {
    final resp = await _dio.post('/auth/admin/login', data: {
      'username': username,
      'password': password,
    });
    _token = resp.data['access_token'] as String;
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  // ---- Products ----
  Future<String> createProduct({
    required String name,
    required String category,
    String? categoryId,
    required double basePrice,
    bool isFeatured = false,
    bool isTrending = false,
    int stockQuantity = 50,
    List<Map<String, dynamic>> sizes = const [],
  }) async {
    final resp = await _dio.post('/admin/products', data: {
      'name': name,
      'category': category,
      'category_id': ?categoryId,
      'base_price': basePrice,
      'sizes': sizes,
      'images': <String>[],
      'stock_quantity': stockQuantity,
      'is_featured': isFeatured,
      'is_trending': isTrending,
    });
    return resp.data['id'] as String;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> changes) =>
      _dio.put('/admin/products/$id', data: changes);

  Future<void> deleteProduct(String id) => _dio.delete('/admin/products/$id');

  // ---- Categories ----
  Future<String> createCategory({required String name, String icon = 'tag', int sortOrder = 0}) async {
    final resp = await _dio.post('/admin/categories', data: {
      'name': name,
      'icon': icon,
      'sort_order': sortOrder,
    });
    return resp.data['id'] as String;
  }

  Future<void> updateCategory(String id, Map<String, dynamic> changes) =>
      _dio.put('/admin/categories/$id', data: changes);

  Future<void> deleteCategory(String id) => _dio.delete('/admin/categories/$id');

  // ---- Banners ----
  Future<String> createBanner({required String title, String imageUrl = 'https://picsum.photos/800/300', int sortOrder = 0}) async {
    final resp = await _dio.post('/admin/banners', data: {
      'title': title,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    });
    return resp.data['id'] as String;
  }

  Future<void> updateBanner(String id, Map<String, dynamic> changes) =>
      _dio.put('/admin/banners/$id', data: changes);

  Future<void> deleteBanner(String id) => _dio.delete('/admin/banners/$id');

  // ---- Coupons ----
  Future<String> createCoupon({
    required String code,
    String discountType = 'percent',
    double value = 10,
    double minOrder = 0,
    int? maxUses,
  }) async {
    final resp = await _dio.post('/admin/coupons', data: {
      'code': code,
      'discount_type': discountType,
      'value': value,
      'min_order': minOrder,
      'max_uses': ?maxUses,
    });
    return resp.data['id'] as String;
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> changes) =>
      _dio.put('/admin/coupons/$id', data: changes);

  Future<void> deleteCoupon(String id) => _dio.delete('/admin/coupons/$id');

  // ---- Orders ----
  Future<void> updateOrderStatus(String orderId, String status) =>
      _dio.patch('/admin/orders/$orderId', data: {'status': status});

  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    final resp = await _dio.get('/admin/orders/$orderId');
    return resp.data as Map<String, dynamic>;
  }

  // ---- Delivery settings ----
  Future<void> updateDeliverySetting(String type, Map<String, dynamic> changes) =>
      _dio.put('/admin/delivery-settings/$type', data: changes);

  // ---- Generic app settings ----
  Future<void> updateSetting(String key, Map<String, dynamic> value) =>
      _dio.put('/admin/settings/$key', data: {'value': value});

  // ---- Notifications ----
  Future<void> broadcastNotification({required String title, required String body}) =>
      _dio.post('/admin/notifications/broadcast', data: {'title': title, 'body': body});

  Dio get raw => _dio;
}

/// Minimal helper for driving customer-facing actions directly against the
/// backend (used for order placement, since Razorpay's native checkout UI
/// cannot be scripted).
class CustomerApi {
  CustomerApi({required this.baseUrl, required this.token});
  final String baseUrl;
  final String token;
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Authorization': 'Bearer $token'},
  ));

  Future<String> createAddress() async {
    final resp = await _dio.post('/addresses', data: {
      'full_address': '123 QA Test Street',
      'city': 'Bengaluru',
      'pincode': '560001',
      'is_default': true,
    });
    return resp.data['id'] as String;
  }

  Future<String> placeOrder({
    required String productId,
    required String size,
    required double price,
    required String addressId,
    String? couponCode,
  }) async {
    final resp = await _dio.post('/orders', data: {
      'address_id': addressId,
      'delivery_type': 'free',
      'coupon_code': ?couponCode,
      'items': [
        {
          'product_id': productId,
          'qty': 1,
          'size': size,
          'price': price,
        }
      ],
    });
    return resp.data['id'] as String;
  }
}
