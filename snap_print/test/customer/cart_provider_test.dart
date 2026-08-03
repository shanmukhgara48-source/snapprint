import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_print/features/customer/domain/entities/cart_item_entity.dart';
import 'package:snap_print/features/customer/presentation/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cart quantities are bounded to the backend limit', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(cartProvider.notifier);
    const item = CartItemEntity(
      cartItemId: 'cart-1',
      productId: 'product-1',
      productName: 'Print',
      productImageUrl: '',
      selectedSize: '4x6',
      quantity: 80,
      unitPrice: 10,
    );

    notifier.addItem(item);
    notifier.addItem(item.copyWith(quantity: 80));
    expect(container.read(cartProvider).items.single.quantity, 99);

    notifier.updateQuantity(item.cartItemId, 500);
    expect(container.read(cartProvider).items.single.quantity, 99);
  });
}
