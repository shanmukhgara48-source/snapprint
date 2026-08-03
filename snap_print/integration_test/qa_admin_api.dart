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

  Future<void> login({String? username, String? password}) async {
    const configuredUsername = String.fromEnvironment(
      'SNAPPRINT_ADMIN_USERNAME',
    );
    const configuredPassword = String.fromEnvironment(
      'SNAPPRINT_ADMIN_PASSWORD',
    );
    final resolvedUsername = username ?? configuredUsername;
    final resolvedPassword = password ?? configuredPassword;
    if (resolvedUsername.isEmpty || resolvedPassword.isEmpty) {
      throw StateError(
        'Admin credentials must be provided through test-only Dart defines.',
      );
    }

    final resp = await _dio.post(
      '/auth/admin/login',
      data: {'username': resolvedUsername, 'password': resolvedPassword},
    );
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
    final resp = await _dio.post(
      '/admin/products',
      data: {
        'name': name,
        'category': category,
        'category_id': ?categoryId,
        'base_price': basePrice,
        'sizes': sizes,
        'images': <String>[],
        'stock_quantity': stockQuantity,
        'is_featured': isFeatured,
        'is_trending': isTrending,
      },
    );
    return resp.data['id'] as String;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> changes) =>
      _dio.put('/admin/products/$id', data: changes);

  Future<void> deleteProduct(String id) => _dio.delete('/admin/products/$id');

  Future<void> cleanupQaFixtures() async {
    await _deleteMatching(
      '/admin/products',
      nameField: 'name',
      matches: (value) => value.startsWith('QA Mug '),
      deletePath: (id) => '/admin/products/$id',
      queryParameters: const {'q': 'QA Mug'},
    );
    await _deleteMatching(
      '/admin/categories',
      nameField: 'name',
      matches: (value) => value.startsWith('QA Cat '),
      deletePath: (id) => '/admin/categories/$id',
    );
    await _deleteMatching(
      '/admin/banners',
      nameField: 'title',
      matches: (value) => value.startsWith('QA Banner '),
      deletePath: (id) => '/admin/banners/$id',
    );
    await _deleteMatching(
      '/admin/coupons',
      nameField: 'code',
      matches: (value) => RegExp(r'^QA\d{1,5}$').hasMatch(value),
      deletePath: (id) => '/admin/coupons/$id',
    );
  }

  Future<void> deleteIfPresent(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
    }
  }

  Future<void> _deleteMatching(
    String listPath, {
    required String nameField,
    required bool Function(String value) matches,
    required String Function(String id) deletePath,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(listPath, queryParameters: queryParameters);
    final items = List<Map<String, dynamic>>.from(
      (response.data as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    for (final item in items) {
      final value = item[nameField]?.toString() ?? '';
      final id = item['id']?.toString();
      if (id != null && matches(value)) {
        await deleteIfPresent(deletePath(id));
      }
    }
  }

  // ---- Categories ----
  Future<String> createCategory({
    required String name,
    String icon = 'tag',
    int sortOrder = 0,
  }) async {
    final resp = await _dio.post(
      '/admin/categories',
      data: {'name': name, 'icon': icon, 'sort_order': sortOrder},
    );
    return resp.data['id'] as String;
  }

  Future<void> updateCategory(String id, Map<String, dynamic> changes) =>
      _dio.put('/admin/categories/$id', data: changes);

  Future<void> deleteCategory(String id) =>
      _dio.delete('/admin/categories/$id');

  // ---- Banners ----
  Future<String> createBanner({
    required String title,
    String imageUrl = 'https://picsum.photos/800/300',
    int sortOrder = 0,
  }) async {
    final resp = await _dio.post(
      '/admin/banners',
      data: {'title': title, 'image_url': imageUrl, 'sort_order': sortOrder},
    );
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
    final resp = await _dio.post(
      '/admin/coupons',
      data: {
        'code': code,
        'discount_type': discountType,
        'value': value,
        'min_order': minOrder,
        'max_uses': ?maxUses,
      },
    );
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
  Future<void> updateDeliverySetting(
    String type,
    Map<String, dynamic> changes,
  ) => _dio.put('/admin/delivery-settings/$type', data: changes);

  // ---- Generic app settings ----
  Future<void> updateSetting(String key, Map<String, dynamic> value) =>
      _dio.put('/admin/settings/$key', data: {'value': value});

  // ---- Notifications ----
  Future<void> broadcastNotification({
    required String title,
    required String body,
  }) => _dio.post(
    '/admin/notifications/broadcast',
    data: {'title': title, 'body': body},
  );

  Dio get raw => _dio;
}
