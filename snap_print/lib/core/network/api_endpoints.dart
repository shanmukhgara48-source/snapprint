import 'package:flutter/foundation.dart' show kReleaseMode;

class ApiEndpoints {
  ApiEndpoints._();

  // Set SNAPPRINT_API_URL at build time via --dart-define=SNAPPRINT_API_URL=https://api.example.com
  // Defaults to Android emulator localhost for local development only.
  static const String _configuredBaseUrl = String.fromEnvironment(
    'SNAPPRINT_API_URL',
  );
  static const String _localDevBaseUrl = 'http://10.0.2.2:8000';

  static String get baseUrl {
    final value = _configuredBaseUrl.isEmpty
        ? (kReleaseMode
              ? throw StateError(
                  'SNAPPRINT_API_URL must be set for release builds.',
                )
              : _localDevBaseUrl)
        : _configuredBaseUrl;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority) {
      throw StateError('SNAPPRINT_API_URL must be an absolute URL.');
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError('SNAPPRINT_API_URL must use HTTPS in release builds.');
    }
    return value;
  }

  // Auth
  static const String verifyAuth = '/auth/verify';
  static const String devLogin = '/auth/dev-login';

  // Products
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';
  static const String productsSuggest = '/products/suggest';
  static const String productsRatings = '/products/ratings';
  static String productReviews(String id) => '/products/$id/reviews';
  static String productReviewSummary(String id) => '/products/$id/reviews/summary';
  static String productBoughtTogether(String id) => '/products/$id/bought-together';
  static String reviewHelpful(String id) => '/reviews/$id/helpful';

  // Wishlist
  static const String wishlist = '/wishlist';
  static const String wishlistIds = '/wishlist/ids';
  static String wishlistItem(String id) => '/wishlist/$id';

  // Returns
  static const String returns = '/returns';
  static const String myReturns = '/returns/me';

  // Categories
  static const String categories = '/categories';

  // Banners
  static const String banners = '/banners';

  // Cart
  static const String cartCalculate = '/cart/calculate';

  // Coupons
  static const String couponValidate = '/coupons/validate';
  static const String activeOffers = '/coupons/active';

  // Orders
  static const String orders = '/orders';
  static const String myOrders = '/orders/me';
  static String orderDetail(String id) => '/orders/$id';

  // Addresses
  static const String addresses = '/addresses';
  static String addressDetail(String id) => '/addresses/$id';
  static String addressSetDefault(String id) => '/addresses/$id/default';

  // Payments
  static const String razorpayCreateOrder = '/payments/razorpay/order';
  static const String razorpayVerify = '/payments/razorpay/verify';

  // Delivery
  static const String deliveryAssigned = '/delivery/assigned';
  static String deliveryUpdateStatus(String orderId) =>
      '/delivery/$orderId/status';
  static String deliveryUploadProof(String orderId) =>
      '/delivery/$orderId/proof';

  // Delivery Options (public)
  static const String deliveryOptions = '/delivery-options';

  // Uploads
  static const String uploadImage = '/upload/image';

  // AI Photo Editor
  static const String aiPhotoStatus = '/ai/photo/status';
  static const String aiPhotoEdit = '/ai/photo/edit';
  static const String aiPhotoAnalyze = '/ai/photo/analyze';
  static const String aiPhotoRemoveBackground = '/ai/photo/remove-background';
  static const String aiPhotoExport = '/ai/photo/export';

  // Admin
  static const String adminProducts = '/admin/products';
  static const String adminDeliverySettings = '/admin/delivery-settings';
  static String adminDeliverySetting(String type) =>
      '/admin/delivery-settings/$type';
  static const String adminOrders = '/admin/orders';
  static const String adminUsers = '/admin/users';
  static const String adminCoupons = '/admin/coupons';
  static const String adminDeliveryPartners = '/admin/delivery-partners';
  static String adminAssignDelivery(String orderId) =>
      '/admin/orders/$orderId/assign';
}
