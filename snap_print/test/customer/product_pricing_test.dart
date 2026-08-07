import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/features/customer/data/models/product_model.dart';

void main() {
  test('size price replaces a missing base price throughout the catalog', () {
    final product = ProductModel.fromJson({
      'id': 'print-1',
      'name': 'Photo Print',
      'category': 'photo_prints',
      'base_price': 0,
      'sizes': [
        {'label': '8x10', 'price': 199},
        {'label': '4x6', 'price': 49},
      ],
      'images': <String>[],
    });

    expect(product.effectivePrice, 49);
    expect(product.hasKnownPrice, isTrue);
    expect(product.priceLabel, 'From ₹49');
    expect(product.isInStock, isTrue);
  });

  test('legacy starting price is accepted and unknown price is explicit', () {
    final legacy = ProductModel.fromJson({
      'id': 'legacy',
      'name': 'Legacy Print',
      'category': 'photo_prints',
      'starting_price': 79,
      'sizes': <Map<String, dynamic>>[],
      'images': <String>[],
    });
    final unavailable = ProductModel.fromJson({
      'id': 'unknown',
      'name': 'Unknown Print',
      'category': 'photo_prints',
      'sizes': <Map<String, dynamic>>[],
      'images': <String>[],
    });

    expect(legacy.effectivePrice, 79);
    expect(unavailable.hasKnownPrice, isFalse);
    expect(unavailable.priceLabel, 'Price unavailable');
  });

  test('catalog-only products are visible but cannot be ordered', () {
    final product = ProductModel.fromJson({
      'id': 'catalog-only',
      'name': 'Layflat Photo Albums',
      'category': 'Photo Books',
      'base_price': 0,
      'sizes': <Map<String, dynamic>>[],
      'images': <String>[],
      'is_orderable': false,
      'material': 'Premium photo paper',
      'dimensions': '8x8 to 12x18 inches',
      'options_summary': '24-50 pages',
      'delivery_info': 'Cash on delivery available',
    });

    expect(product.priceLabel, 'Pricing coming soon');
    expect(product.canOrder, isFalse);
    expect(product.material, 'Premium photo paper');
    expect(product.dimensions, '8x8 to 12x18 inches');
  });

  test(
    'tracked zero inventory is sold out while untracked products are unlimited',
    () {
      final soldOut = ProductModel.fromJson({
        'id': 'sold-out',
        'name': 'Sold Out Print',
        'category': 'photo_prints',
        'base_price': 49,
        'stock_quantity': 0,
        'tracks_inventory': true,
        'sizes': <Map<String, dynamic>>[],
        'images': <String>[],
      });
      final unlimited = ProductModel.fromJson({
        'id': 'unlimited',
        'name': 'Unlimited Print',
        'category': 'photo_prints',
        'base_price': 49,
        'stock_quantity': 0,
        'tracks_inventory': false,
        'sizes': <Map<String, dynamic>>[],
        'images': <String>[],
      });

      expect(soldOut.isInStock, isFalse);
      expect(unlimited.isInStock, isTrue);
    },
  );
}
