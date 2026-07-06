class ApiEndpoints {
  ApiEndpoints._();

  // Set SNAPPRINT_API_URL at build time via --dart-define=SNAPPRINT_API_URL=https://api.example.com
  // Defaults to Android emulator localhost for local development only.
  static const String baseUrl = String.fromEnvironment(
    'SNAPPRINT_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Auth
  static const String verifyAuth = '/auth/verify';
  static const String devLogin = '/auth/dev-login';

  // Products
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';

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
  static String deliveryUpdateStatus(String orderId) => '/delivery/$orderId/status';

  // Delivery Options (public)
  static const String deliveryOptions = '/delivery-options';

  // Admin
  static const String adminProducts = '/admin/products';
  static const String adminDeliverySettings = '/admin/delivery-settings';
  static String adminDeliverySetting(String type) => '/admin/delivery-settings/$type';
  static const String adminOrders = '/admin/orders';
  static const String adminUsers = '/admin/users';
  static const String adminCoupons = '/admin/coupons';
  static const String adminDeliveryPartners = '/admin/delivery-partners';
  static String adminAssignDelivery(String orderId) => '/admin/orders/$orderId/assign';
}
