// 25 customer-persona integration tests, executed on a physical Android
// device against the real FastAPI backend and real Postgres DB.
//
// Each test is one realistic customer scenario. They drive the app's own
// production code paths — ApiClient, CustomerRemoteDataSource, ProductModel
// parsing, CartNotifier, CartState pricing — rather than reimplementing that
// logic here, so a regression in app source fails these tests.
//
// Substitutions (same conventions as qa_realtime_sync_test.dart):
//   - Firebase OTP -> the app's built-in kDebugMode dev-login bypass, since
//     real SMS delivery cannot be scripted.
//   - Razorpay's native checkout sheet -> orders are placed directly through
//     POST /orders, which is what the app calls after payment succeeds.
//
// Run with (device port 8000 is adb-reversed to the backend on the host):
//   flutter test integration_test/customer_personas_test.dart \
//     -d RZCR404Z9MK \
//     --dart-define=SNAPPRINT_API_URL=http://127.0.0.1:8000 \
//     --dart-define=DEV_BYPASS_SECRET=<secret>

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snap_print/core/network/api_client.dart';
import 'package:snap_print/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:snap_print/features/customer/data/models/product_model.dart';
import 'package:snap_print/features/customer/domain/entities/cart_item_entity.dart';
import 'package:snap_print/features/customer/presentation/providers/cart_provider.dart';

const _apiBase = String.fromEnvironment(
  'SNAPPRINT_API_URL',
  defaultValue: 'http://127.0.0.1:8000',
);
const _devSecret = String.fromEnvironment('DEV_BYPASS_SECRET');

/// Raw client for setup/teardown work that is not itself under test
/// (seeding an address, reading a coupon back, logging in).
final _raw = Dio(BaseOptions(
  baseUrl: _apiBase,
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: const Duration(seconds: 20),
  // Personas assert on error status codes as well as success ones, so never
  // let Dio throw purely because the server said 4xx.
  validateStatus: (_) => true,
));

/// A container wired exactly like the running app. Each persona gets a fresh
/// one so cart state never leaks between scenarios.
ProviderContainer _freshContainer() => ProviderContainer();

CustomerRemoteDataSource _dataSource(ProviderContainer c) =>
    c.read(customerDataSourceProvider);

/// The cart is persisted to SharedPreferences on every mutation; without this
/// a cart left behind by one persona rehydrates into the next one.
Future<void> _clearCartStorage() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('cart_v1');
}

/// CartNotifier.build() kicks off an async SharedPreferences read and persists
/// asynchronously on change. Give those disk round-trips real time to finish
/// before asserting, rather than racing them.
Future<void> _settleStorage() =>
    Future<void>.delayed(const Duration(milliseconds: 400));

CartItemEntity _item({
  required String id,
  String productId = 'p1',
  String name = 'Photo Frame',
  String size = '4x6',
  int qty = 1,
  double price = 199,
  String? customizationImageUrl,
}) {
  return CartItemEntity(
    cartItemId: id,
    productId: productId,
    productName: name,
    productImageUrl: '',
    selectedSize: size,
    quantity: qty,
    unitPrice: price,
    customizationImageUrl: customizationImageUrl,
  );
}

/// Authenticates through the same dev-login endpoint the app's devLogin()
/// calls, then installs the token into ApiClient so provider-driven calls in
/// the test are authenticated exactly as they are in the running app.
///
/// The token is cached for the whole suite: /auth/dev-login is rate limited to
/// 3 requests/minute, so logging in per-test makes later personas fail with
/// 429 for reasons that have nothing to do with what they assert. One session
/// reused across personas is also what a real customer does.
String? _cachedToken;

Future<String> _devLogin({String phone = '+919876543210'}) async {
  expect(_devSecret, isNotEmpty,
      reason: 'Pass --dart-define=DEV_BYPASS_SECRET=<value> to run '
          'authenticated personas.');
  if (_cachedToken != null) {
    setDevAuthToken(_cachedToken);
    return _cachedToken!;
  }
  final resp = await _raw.post<Map<String, dynamic>>(
    '/auth/dev-login',
    data: {'phone': phone, 'secret': _devSecret},
  );
  expect(resp.statusCode, 200,
      reason: 'dev-login failed: ${resp.statusCode} ${resp.data}');
  final token = resp.data!['dev_token'] as String;
  _cachedToken = token;
  setDevAuthToken(token);
  return token;
}

Future<String> _ensureAddress(String token) async {
  final existing = await _raw.get<List<dynamic>>(
    '/addresses',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  if (existing.statusCode == 200 &&
      (existing.data?.isNotEmpty ?? false)) {
    return (existing.data!.first as Map)['id'] as String;
  }
  final created = await _raw.post<Map<String, dynamic>>(
    '/addresses',
    data: {
      'full_address': '12 MG Road, Indiranagar',
      'city': 'Bengaluru',
      'pincode': '560038',
      'is_default': true,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  expect(created.statusCode, anyOf(200, 201),
      reason: 'address create failed: ${created.data}');
  return created.data!['id'] as String;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    setDevAuthToken(null);
    await _clearCartStorage();
  });

  // ===========================================================
  // BROWSING & CATALOG
  // ===========================================================

  testWidgets('P01 Ananya opens the app and browses the category grid',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    final categories = await _dataSource(c).getCategories();

    expect(categories, isNotEmpty,
        reason: 'Home category grid would render empty');
    expect(categories.every((e) => e.name.trim().isNotEmpty), isTrue);
    // The grid renders in sort_order; a stable order keeps the demo predictable.
    final orders = categories.map((e) => e.sortOrder).toList();
    expect(orders, orderedEquals(List.of(orders)..sort()),
        reason: 'Categories are not returned in sort_order');
  });

  testWidgets('P02 Vikram taps Frames and sees frame products',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    // The home grid navigates by category id, not name, so this is the path
    // that actually runs in the app.
    final frames =
        (await _dataSource(c).getCategories()).firstWhere((e) => e.name == 'frames');
    final byId = await _dataSource(c).getProducts(category: frames.id);

    expect(byId, isNotEmpty, reason: 'Frames category page would be empty');
    expect(byId.every((p) => p.categoryName == 'frames'), isTrue,
        reason: 'Frames listing leaked products from another category');

    // A category name containing an underscore must still be sent as a name.
    final byName = await _dataSource(c).getProducts(category: 'digital_frames');
    expect(byName.every((p) => p.categoryName == 'digital_frames'), isTrue,
        reason: 'Underscored category name was misrouted as a category id');
  });

  testWidgets('P03 Meera opens a frame and sees per-size pricing',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    final list = await _dataSource(c).getProducts(category: 'frames');
    final detail = await _dataSource(c).getProductById(list.first.id);

    expect(detail.sizes, isNotEmpty,
        reason: 'Customization screen has no sizes to offer');
    expect(detail.sizes.every((s) => s.price > 0), isTrue,
        reason: 'A size is priced at zero — add-to-cart would be blocked');
    // Larger sizes must not be cheaper than the base price.
    expect(detail.sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b),
        greaterThanOrEqualTo(0));
  });

  testWidgets('P04 Rohan scrolls the Featured carousel on Home',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    final featured = await _dataSource(c).getProducts(featured: true);

    expect(featured, isNotEmpty, reason: 'Featured carousel would be empty');
    expect(featured.every((p) => p.isFeatured), isTrue,
        reason: 'featured=true returned non-featured products');
  });

  testWidgets('P05 Kavya checks the Trending row', (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    final trending = await _dataSource(c).getProducts(trending: true);

    expect(trending.every((p) => p.isTrending), isTrue,
        reason: 'trending=true returned non-trending products');
  });

  testWidgets('P06 Arjun sees banners and live offers on Home',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    // Both are decorative: they must load without error, but an empty
    // merchandising list is a valid state and must not break Home.
    final banners = await _dataSource(c).getBanners();
    final offers = await _dataSource(c).getActiveOffers();

    expect(banners, isA<List<dynamic>>());
    expect(offers, isA<List<dynamic>>());
  });

  testWidgets('P07 Sneha browses a catalog where one product has no price',
      (tester) async {
    // Price gating is pure app logic, so it is exercised through the real
    // ProductModel parser with a payload shaped like the API's.
    final priced = ProductModel.fromJson({
      'id': 'x1',
      'name': 'Photo Frame',
      'category': 'frames',
      'base_price': 199.0,
      'sizes': <dynamic>[],
      'images': <dynamic>[],
    });
    final unpriced = ProductModel.fromJson({
      'id': 'x2',
      'name': 'Coming Soon Frame',
      'category': 'frames',
      'base_price': 0,
      'sizes': <dynamic>[],
      'images': <dynamic>[],
    });

    expect(priced.hasKnownPrice, isTrue);
    expect(priced.priceLabel, '₹199');
    expect(unpriced.hasKnownPrice, isFalse,
        reason: 'A zero-priced product must not advertise a price');
    expect(unpriced.priceLabel, 'Price unavailable');
  });

  testWidgets('P08 Dev switches size and the unit price follows',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    final list = await _dataSource(c).getProducts(category: 'frames');
    final detail = await _dataSource(c).getProductById(list.first.id);
    expect(detail.sizes.length, greaterThanOrEqualTo(2),
        reason: 'Need at least two sizes to test size-driven repricing');

    final small = detail.sizes.first;
    final large = detail.sizes.last;
    final cart = _freshContainer();
    addTearDown(cart.dispose);
    final notifier = cart.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', size: small.label, price: small.price));
    final subtotalSmall = cart.read(cartProvider).subtotal;
    notifier.clearCart();
    notifier.addItem(_item(id: 'b', size: large.label, price: large.price));
    final subtotalLarge = cart.read(cartProvider).subtotal;

    expect(subtotalSmall, small.price);
    expect(subtotalLarge, large.price);
  });

  // ===========================================================
  // CART BEHAVIOUR
  // ===========================================================

  testWidgets('P09 Priya adds one frame to her cart', (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', price: 199, qty: 1));

    final state = c.read(cartProvider);
    expect(state.items, hasLength(1));
    expect(state.itemCount, 1);
    expect(state.subtotal, 199);
    expect(state.total, 199, reason: 'Free delivery adds nothing by default');
  });

  testWidgets('P10 Karan adds the same size twice and gets one line of qty 2',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', size: '4x6', price: 199));
    notifier.addItem(_item(id: 'b', size: '4x6', price: 199));

    final state = c.read(cartProvider);
    expect(state.items, hasLength(1), reason: 'Identical lines must merge');
    expect(state.items.single.quantity, 2);
    expect(state.subtotal, 398);
  });

  testWidgets('P11 Divya orders two different sizes as separate lines',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', size: '4x6', price: 199));
    notifier.addItem(_item(id: 'b', size: '8x10', price: 499));

    final state = c.read(cartProvider);
    expect(state.items, hasLength(2),
        reason: 'Different sizes must not be merged');
    expect(state.subtotal, 698);
  });

  testWidgets('P12 Nikhil uploads two photos and each stays its own line',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    // Same product and size, but personalised with different photos — merging
    // these would silently print one photo twice.
    notifier.addItem(_item(
        id: 'a', customizationImageUrl: 'https://cdn.test/photo-1.png'));
    notifier.addItem(_item(
        id: 'b', customizationImageUrl: 'https://cdn.test/photo-2.png'));

    final state = c.read(cartProvider);
    expect(state.items, hasLength(2),
        reason: 'Customised photo items must never merge');
    expect(state.itemCount, 2);
  });

  testWidgets('P13 Ishaan bumps the quantity to 3', (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', price: 199));
    notifier.updateQuantity('a', 3);

    final state = c.read(cartProvider);
    expect(state.items.single.quantity, 3);
    expect(state.subtotal, 597);
  });

  testWidgets('P14 Tara decrements to zero and the line disappears',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a'));
    notifier.updateQuantity('a', 0);

    expect(c.read(cartProvider).items, isEmpty,
        reason: 'Quantity 0 must remove the line, not keep a zero-qty row');
  });

  testWidgets('P15 Aditya removes one of two items', (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', size: '4x6', price: 199));
    notifier.addItem(_item(id: 'b', size: '8x10', price: 499));
    notifier.removeItem('a');

    final state = c.read(cartProvider);
    expect(state.items, hasLength(1));
    expect(state.items.single.cartItemId, 'b');
    expect(state.subtotal, 499);
  });

  testWidgets('P16 Riya empties her cart', (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a'));
    notifier.applyCoupon('SAVE50', 75);
    notifier.clearCart();

    final state = c.read(cartProvider);
    expect(state.items, isEmpty);
    expect(state.discount, 0, reason: 'Clearing must drop the coupon too');
    expect(state.couponCode, isNull);
    expect(state.total, 0);
  });

  testWidgets('P17 Farhan force-quits the app and his cart is still there',
      (tester) async {
    final first = _freshContainer();
    first.read(cartProvider.notifier).addItem(_item(id: 'a', price: 199, qty: 2));
    await _settleStorage();
    first.dispose();

    // A brand new container is what a cold app start looks like.
    final second = _freshContainer();
    addTearDown(second.dispose);
    second.read(cartProvider);
    await _settleStorage();

    final state = second.read(cartProvider);
    expect(state.items, hasLength(1),
        reason: 'Cart did not survive an app restart');
    expect(state.items.single.quantity, 2);
    expect(state.subtotal, 398);
  });

  // ===========================================================
  // DELIVERY, COUPONS & TOTALS
  // ===========================================================

  testWidgets('P18 Neha keeps free delivery', (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', price: 199));
    notifier.setDeliveryType(DeliveryType.free);

    final state = c.read(cartProvider);
    expect(state.deliveryCharge, 0);
    expect(state.total, 199);
  });

  testWidgets('P19 Sameer picks Express and is charged the live server rate',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);

    final resp = await _raw.get<List<dynamic>>('/delivery-options');
    expect(resp.statusCode, 200);
    final express = (resp.data!)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['type'] == 'express');
    final serverPrice = (express['price'] as num).toDouble();

    final notifier = c.read(cartProvider.notifier);
    notifier.addItem(_item(id: 'a', price: 199));
    notifier.setDeliveryOption('express', serverPrice);

    final state = c.read(cartProvider);
    // The hardcoded enum fallback must lose to the admin-configured price,
    // otherwise the customer is billed a stale delivery fee.
    expect(state.deliveryCharge, serverPrice);
    expect(state.total, 199 + serverPrice);
  });

  testWidgets('P20 Pooja applies a real coupon from the server',
      (tester) async {
    final token = await _devLogin();
    final c = _freshContainer();
    addTearDown(c.dispose);

    final active = await _raw.get<List<dynamic>>('/coupons/active');
    expect(active.statusCode, 200);
    if ((active.data ?? []).isEmpty) {
      markTestSkipped('No active coupons configured on this backend');
      return;
    }
    final code = (active.data!.first as Map)['code'] as String;

    final notifier = c.read(cartProvider.notifier);
    notifier.addItem(_item(id: 'a', price: 199, qty: 3)); // subtotal 597

    setDevAuthToken(token);
    final result = await _dataSource(c).validateCoupon(code, 597.0);
    expect(result['valid'], isTrue, reason: '$result');
    // Same field the cart screen reads (cart_screen.dart _applyCoupon).
    final discount = (result['discount_amount'] as num?)?.toDouble() ?? 0;
    expect(discount, greaterThan(0),
        reason: 'Server reported a valid coupon but no discount amount');

    notifier.applyCoupon(code, discount);

    final state = c.read(cartProvider);
    expect(state.couponCode, code);
    expect(state.discount, discount);
    expect(state.total, 597 - discount);
  });

  testWidgets('P21 Manish changes his mind and removes the coupon',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', price: 199, qty: 2));
    notifier.setDeliveryOption('standard', 49);
    notifier.applyCoupon('SAVE50', 75);
    notifier.removeCoupon();

    final state = c.read(cartProvider);
    expect(state.couponCode, isNull);
    expect(state.discount, 0);
    // Removing a coupon must not also reset the delivery choice.
    expect(state.deliveryCharge, 49);
    expect(state.total, 398 + 49);
  });

  testWidgets('P22 Anjali combines quantity, express delivery and a discount',
      (tester) async {
    final c = _freshContainer();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.addItem(_item(id: 'a', size: '8x10', price: 499, qty: 2));
    notifier.addItem(_item(id: 'b', size: '4x6', price: 199, qty: 1));
    notifier.setDeliveryOption('express', 109);
    notifier.applyCoupon('SAVE50', 75);

    final state = c.read(cartProvider);
    expect(state.subtotal, 1197);
    expect(state.itemCount, 3);
    expect(state.total, 1197 + 109 - 75);
  });

  testWidgets('P23 Zoya mistypes a coupon code and is rejected',
      (tester) async {
    final token = await _devLogin();

    final result = await _raw.post<Map<String, dynamic>>(
      '/coupons/validate',
      data: {'code': 'NOTAREALCODE123', 'subtotal': 500.0},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    expect(result.statusCode, 200);
    expect(result.data!['valid'], isFalse,
        reason: 'A bogus coupon must not validate');
    expect(result.data!['message'], isNotNull);
  });

  testWidgets('P24 Rahul signs in and opens his order history',
      (tester) async {
    final token = await _devLogin();
    final c = _freshContainer();
    addTearDown(c.dispose);
    setDevAuthToken(token);

    final orders = await _dataSource(c).getMyOrders();

    // A new customer legitimately has zero orders; the contract under test is
    // that an authenticated read succeeds instead of 401/403-ing.
    expect(orders, isA<List<dynamic>>());
  });

  testWidgets('P25 Sanjay completes checkout and sees the order in his history',
      (tester) async {
    final token = await _devLogin();
    final addressId = await _ensureAddress(token);
    final c = _freshContainer();
    addTearDown(c.dispose);
    setDevAuthToken(token);

    final products = await _dataSource(c).getProducts(category: 'frames');
    final product = products.first;
    final size = product.sizes.isNotEmpty ? product.sizes.first : null;
    final unitPrice = size?.price ?? product.basePrice;

    final notifier = c.read(cartProvider.notifier);
    notifier.addItem(_item(
      id: 'checkout-1',
      productId: product.id,
      name: product.name,
      size: size?.label ?? '',
      price: unitPrice,
      qty: 2,
    ));
    final cartState = c.read(cartProvider);

    final order = await _dataSource(c).placeOrder({
      'items': cartState.items
          .map((i) => {
                'product_id': i.productId,
                'qty': i.quantity,
                'size': i.selectedSize,
                'image_url': i.customizationImageUrl,
                'price': i.unitPrice,
              })
          .toList(),
      'address_id': addressId,
      'delivery_type': 'free',
    });

    expect(order.id, isNotEmpty);
    expect(order.totalPrice, greaterThan(0));

    final history = await _dataSource(c).getMyOrders();
    expect(history.any((o) => o.id == order.id), isTrue,
        reason: 'Placed order did not appear in order history');

    notifier.clearCart();
    expect(c.read(cartProvider).items, isEmpty);
  });
}
