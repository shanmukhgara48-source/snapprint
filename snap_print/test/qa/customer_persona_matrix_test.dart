import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_print/core/utils/validators.dart';
import 'package:snap_print/features/ai_editor/domain/local_image_metrics.dart';
import 'package:snap_print/features/ai_editor/domain/prompt_edit_intent.dart';
import 'package:snap_print/features/customer/data/models/product_model.dart';
import 'package:snap_print/features/customer/domain/checkout_rules.dart';
import 'package:snap_print/features/customer/domain/entities/cart_item_entity.dart';
import 'package:snap_print/features/customer/domain/entities/category_entity.dart';
import 'package:snap_print/features/customer/presentation/providers/cart_provider.dart';
import 'package:snap_print/features/customer/presentation/providers/catalog_provider.dart';
import 'package:snap_print/features/customer/presentation/widgets/category_grid.dart';

typedef _Validator = String? Function(String? value);

class _ValidationPersona {
  const _ValidationPersona(
    this.name,
    this.validator,
    this.value, {
    required this.isValid,
  });

  final String name;
  final _Validator validator;
  final String? value;
  final bool isValid;
}

class _PromptPersona {
  const _PromptPersona(this.name, this.prompt, this.operation, this.execution);

  final String name;
  final String prompt;
  final String operation;
  final PromptEditExecution execution;
}

class _CatalogPersona {
  const _CatalogPersona(
    this.name, {
    required this.basePrice,
    required this.sizePrices,
    required this.stock,
    required this.tracksInventory,
    required this.expectedPrice,
    required this.inStock,
  });

  final String name;
  final double basePrice;
  final List<double> sizePrices;
  final int stock;
  final bool tracksInventory;
  final double expectedPrice;
  final bool inStock;
}

class _AccessibilityPersona {
  const _AccessibilityPersona(
    this.name,
    this.size,
    this.textScale,
    this.categoryName,
    this.brightness,
  );

  final String name;
  final Size size;
  final double textScale;
  final String categoryName;
  final Brightness brightness;
}

final _validationPersonas = <_ValidationPersona>[
  _ValidationPersona(
    'first-time user leaves phone empty',
    Validators.phone,
    null,
    isValid: false,
  ),
  _ValidationPersona(
    'returning user submits an empty phone',
    Validators.phone,
    '',
    isValid: false,
  ),
  _ValidationPersona(
    'user enters a nine-digit phone',
    Validators.phone,
    '987654321',
    isValid: false,
  ),
  _ValidationPersona(
    'user enters a valid phone',
    Validators.phone,
    '9876543210',
    isValid: true,
  ),
  _ValidationPersona(
    'user enters a formatted phone',
    Validators.phone,
    '(987) 654-3210',
    isValid: true,
  ),
  _ValidationPersona(
    'attacker submits SQL text as phone',
    Validators.phone,
    "1 OR 1=1--9876543210",
    isValid: false,
  ),
  _ValidationPersona(
    'user leaves OTP empty',
    Validators.otp,
    '',
    isValid: false,
  ),
  _ValidationPersona(
    'user enters a short OTP',
    Validators.otp,
    '12345',
    isValid: false,
  ),
  _ValidationPersona(
    'user enters letters in OTP',
    Validators.otp,
    '12AB56',
    isValid: false,
  ),
  _ValidationPersona(
    'user enters a valid OTP',
    Validators.otp,
    '123456',
    isValid: true,
  ),
  _ValidationPersona(
    'user enters a valid pincode',
    Validators.pincode,
    '500001',
    isValid: true,
  ),
  _ValidationPersona(
    'user enters emoji in pincode',
    Validators.pincode,
    '50000🙂',
    isValid: false,
  ),
  _ValidationPersona(
    'user submits whitespace-only name',
    Validators.required,
    '   ',
    isValid: false,
  ),
  _ValidationPersona(
    'user submits a Unicode name',
    Validators.required,
    'శాన్ముఖ్',
    isValid: true,
  ),
  _ValidationPersona(
    'user enters lowercase coupon',
    Validators.couponCode,
    'save20',
    isValid: true,
  ),
  _ValidationPersona(
    'user enters a short coupon',
    Validators.couponCode,
    'A1',
    isValid: false,
  ),
  _ValidationPersona(
    'attacker submits XSS as coupon',
    Validators.couponCode,
    '<script>alert(1)</script>',
    isValid: false,
  ),
  _ValidationPersona(
    'free product uses zero price',
    Validators.price,
    '0',
    isValid: true,
  ),
  _ValidationPersona(
    'invalid NaN price is rejected',
    Validators.price,
    'NaN',
    isValid: false,
  ),
  _ValidationPersona(
    'infinite price is rejected',
    Validators.price,
    'Infinity',
    isValid: false,
  ),
];

const _promptPersonas = <_PromptPersona>[
  _PromptPersona(
    'one-tap monochrome',
    'Make it black and white',
    'filter',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'grayscale synonym',
    'Convert to grayscale',
    'filter',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'vintage filter',
    'Give this a vintage look',
    'filter',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'golden-hour filter',
    'Make it golden hour',
    'filter',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'cool winter filter',
    'Use a cool winter tone',
    'filter',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'HDR enhancement',
    'Increase contrast for HDR',
    'enhance',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'brightness enhancement',
    'Brighten this photo',
    'enhance',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'matte filter',
    'Apply a soft matte film look',
    'filter',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'cinematic filter',
    'Make it cinematic',
    'filter',
    PromptEditExecution.localAdjustment,
  ),
  _PromptPersona(
    'rotate transform',
    'Rotate clockwise',
    'rotate',
    PromptEditExecution.localTransform,
  ),
  _PromptPersona(
    'flip transform',
    'Flip this horizontally',
    'flip',
    PromptEditExecution.localTransform,
  ),
  _PromptPersona(
    'background cutout',
    'Remove the background',
    'background_removal',
    PromptEditExecution.backgroundRemoval,
  ),
  _PromptPersona(
    'beach replacement',
    'Replace background with beach',
    'background',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'dramatic sky replacement',
    'Replace the sky with a dramatic sunset',
    'background',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'background blur',
    'Blur background behind me',
    'background',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'remove crowd',
    'Remove people behind me',
    'object_removal',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'remove chair',
    'Remove the chair',
    'object_removal',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'owned watermark removal',
    'Remove the watermark',
    'object_removal',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'print upscale',
    'Upscale to 4K',
    'upscale',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'old-photo colorization',
    'Colorize this old photo',
    'colorize',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'scratch restoration',
    'Restore scratches and faded areas',
    'restore',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'portrait smile',
    'Add a natural smile to my face',
    'portrait',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'hair enhancement',
    'Enhance my hair naturally',
    'portrait',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'anime generation',
    'Turn this into anime',
    'filter',
    PromptEditExecution.server,
  ),
  _PromptPersona(
    'unrecognized creative edit',
    'Add sunglasses',
    'prompt',
    PromptEditExecution.server,
  ),
];

const _catalogPersonas = <_CatalogPersona>[
  _CatalogPersona(
    'standard priced print',
    basePrice: 49,
    sizePrices: [],
    stock: 10,
    tracksInventory: true,
    expectedPrice: 49,
    inStock: true,
  ),
  _CatalogPersona(
    'size-only priced print',
    basePrice: 0,
    sizePrices: [79],
    stock: 5,
    tracksInventory: true,
    expectedPrice: 79,
    inStock: true,
  ),
  _CatalogPersona(
    'lowest size is displayed',
    basePrice: 199,
    sizePrices: [149, 99],
    stock: 8,
    tracksInventory: true,
    expectedPrice: 99,
    inStock: true,
  ),
  _CatalogPersona(
    'sold-out tracked print',
    basePrice: 49,
    sizePrices: [],
    stock: 0,
    tracksInventory: true,
    expectedPrice: 49,
    inStock: false,
  ),
  _CatalogPersona(
    'untracked made-to-order print',
    basePrice: 49,
    sizePrices: [],
    stock: 0,
    tracksInventory: false,
    expectedPrice: 49,
    inStock: true,
  ),
  _CatalogPersona(
    'free promotional sample',
    basePrice: 0,
    sizePrices: [0],
    stock: 1,
    tracksInventory: true,
    expectedPrice: 0,
    inStock: true,
  ),
  _CatalogPersona(
    'decimal-priced print',
    basePrice: 49.5,
    sizePrices: [],
    stock: 2,
    tracksInventory: true,
    expectedPrice: 49.5,
    inStock: true,
  ),
  _CatalogPersona(
    'large canvas price',
    basePrice: 9999,
    sizePrices: [12999],
    stock: 2,
    tracksInventory: true,
    expectedPrice: 9999,
    inStock: true,
  ),
  _CatalogPersona(
    'negative size is ignored',
    basePrice: 120,
    sizePrices: [-10, 150],
    stock: 2,
    tracksInventory: true,
    expectedPrice: 120,
    inStock: true,
  ),
  _CatalogPersona(
    'zero base falls back to positive size',
    basePrice: 0,
    sizePrices: [0, 250],
    stock: 2,
    tracksInventory: true,
    expectedPrice: 250,
    inStock: true,
  ),
  _CatalogPersona(
    'high inventory product',
    basePrice: 20,
    sizePrices: [30],
    stock: 10000,
    tracksInventory: true,
    expectedPrice: 20,
    inStock: true,
  ),
  _CatalogPersona(
    'negative tracked stock is unavailable',
    basePrice: 20,
    sizePrices: [],
    stock: -1,
    tracksInventory: true,
    expectedPrice: 20,
    inStock: false,
  ),
  _CatalogPersona(
    'book with multiple sizes',
    basePrice: 700,
    sizePrices: [600, 800, 1200],
    stock: 4,
    tracksInventory: true,
    expectedPrice: 600,
    inStock: true,
  ),
  _CatalogPersona(
    'frame with equal prices',
    basePrice: 300,
    sizePrices: [300, 300],
    stock: 4,
    tracksInventory: true,
    expectedPrice: 300,
    inStock: true,
  ),
  _CatalogPersona(
    'gift with no known price',
    basePrice: 0,
    sizePrices: [],
    stock: 4,
    tracksInventory: true,
    expectedPrice: 0,
    inStock: true,
  ),
  _CatalogPersona(
    'single remaining item',
    basePrice: 149,
    sizePrices: [],
    stock: 1,
    tracksInventory: true,
    expectedPrice: 149,
    inStock: true,
  ),
  _CatalogPersona(
    'untracked negative stock is ignored',
    basePrice: 149,
    sizePrices: [],
    stock: -5,
    tracksInventory: false,
    expectedPrice: 149,
    inStock: true,
  ),
  _CatalogPersona(
    'premium decimal canvas',
    basePrice: 2500.75,
    sizePrices: [3000.25],
    stock: 6,
    tracksInventory: true,
    expectedPrice: 2500.75,
    inStock: true,
  ),
  _CatalogPersona(
    'base above cheaper size',
    basePrice: 500,
    sizePrices: [450],
    stock: 6,
    tracksInventory: true,
    expectedPrice: 450,
    inStock: true,
  ),
  _CatalogPersona(
    'base below all sizes',
    basePrice: 399,
    sizePrices: [499, 599],
    stock: 6,
    tracksInventory: true,
    expectedPrice: 399,
    inStock: true,
  ),
];

const _cartPersonaNames = <String>[
  'first-time single-item buyer',
  'returning standard-delivery buyer',
  'express-delivery power user',
  'rapid add-button tapper',
  'customized-photo buyer',
  'coupon user with partial discount',
  'coupon user receiving a free order',
  'buyer reopening a persisted cart',
  'buyer affected by admin repricing',
  'buyer using a large quantity',
  'buyer adding repeated customized photos',
  'buyer switching delivery options',
  'buyer with decimal item pricing',
  'buyer with discount above subtotal',
  'buyer after stock synchronization',
  'buyer with 99-item boundary pressure',
  'buyer mixing rapid taps and coupon',
  'buyer resuming checkout after navigation',
  'buyer after delivery-price synchronization',
  'buyer whose product is deactivated by admin',
];

const _accessibilityPersonas = <_AccessibilityPersona>[
  _AccessibilityPersona(
    'small Android phone',
    Size(320, 568),
    1,
    'Photo Prints',
    Brightness.light,
  ),
  _AccessibilityPersona(
    'compact phone with 130 percent text',
    Size(360, 640),
    1.3,
    'Photo Books',
    Brightness.light,
  ),
  _AccessibilityPersona(
    'large phone with 200 percent text',
    Size(412, 915),
    2,
    'Frames & Wall Decor',
    Brightness.light,
  ),
  _AccessibilityPersona(
    'small phone in dark mode',
    Size(320, 568),
    1,
    'Personalized Gifts',
    Brightness.dark,
  ),
  _AccessibilityPersona(
    'elderly user in dark mode',
    Size(412, 915),
    1.8,
    'Premium Canvas Prints',
    Brightness.dark,
  ),
  _AccessibilityPersona(
    'Unicode category name',
    Size(360, 800),
    1.4,
    'ఫోటో ప్రింట్లు',
    Brightness.light,
  ),
  _AccessibilityPersona(
    'emoji category name',
    Size(360, 800),
    1.4,
    'Birthday 🎉 Prints',
    Brightness.light,
  ),
  _AccessibilityPersona(
    'maximum backend category name',
    Size(412, 915),
    1.5,
    'A very long personalized premium photo category name designed for special celebrations and family memories',
    Brightness.light,
  ),
  _AccessibilityPersona(
    'landscape-like narrow height',
    Size(640, 360),
    1.2,
    'Square Prints',
    Brightness.dark,
  ),
  _AccessibilityPersona(
    'tablet-width customer',
    Size(800, 1280),
    2,
    'Wedding Albums',
    Brightness.light,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('100-customer simulation: input and security personas', () {
    for (var index = 0; index < _validationPersonas.length; index++) {
      final persona = _validationPersonas[index];
      test('persona ${index + 1}: ${persona.name}', () {
        final error = persona.validator(persona.value);
        expect(error == null, persona.isValid);
      });
    }
  });

  group('100-customer simulation: AI editing personas', () {
    for (var index = 0; index < _promptPersonas.length; index++) {
      final persona = _promptPersonas[index];
      test('persona ${index + 21}: ${persona.name}', () {
        final intent = classifyPromptEdit(persona.prompt);
        expect(intent.operation, persona.operation);
        expect(intent.execution, persona.execution);
      });
    }
  });

  group('100-customer simulation: catalog and stock personas', () {
    for (var index = 0; index < _catalogPersonas.length; index++) {
      final persona = _catalogPersonas[index];
      test('persona ${index + 46}: ${persona.name}', () {
        final product = ProductModel.fromJson({
          'id': 'persona-${index + 46}',
          'name': persona.name,
          'category_id': 'photo-prints',
          'category': 'Photo Prints',
          'base_price': persona.basePrice,
          'sizes': [
            for (
              var sizeIndex = 0;
              sizeIndex < persona.sizePrices.length;
              sizeIndex++
            )
              {
                'label': '${sizeIndex + 4}x${sizeIndex + 6}',
                'price': persona.sizePrices[sizeIndex],
              },
          ],
          'images': ['https://example.com/product.jpg'],
          'stock_quantity': persona.stock,
          'tracks_inventory': persona.tracksInventory,
        });

        expect(product.effectivePrice, persona.expectedPrice);
        expect(product.isInStock, persona.inStock);
        expect(product.imageUrl, isNotEmpty);
      });
    }
  });

  group('100-customer simulation: cart-to-checkout personas', () {
    for (var index = 0; index < _cartPersonaNames.length; index++) {
      test('persona ${index + 66}: ${_cartPersonaNames[index]}', () {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(cartProvider.notifier);

        final customized = index % 5 == 4;
        final initialQuantity = index == 15 ? 98 : (index % 5) + 1;
        final rapidAdds = index % 4;
        final originalPrice = 49.5 + index;
        final newPrice = 59.25 + index;
        final deliveryKey = DeliveryType.values[index % 3].name;
        final deliveryPrice = [0.0, 49.0, 99.0][index % 3];
        final discount = index == 6 || index == 13 ? 100000.0 : index * 5.0;

        final firstItem = CartItemEntity(
          cartItemId: 'cart-$index-0',
          productId: 'product-$index',
          productName: 'Persona Print $index',
          productImageUrl: 'https://example.com/product-$index.jpg',
          selectedSize: '4x6',
          quantity: initialQuantity,
          unitPrice: originalPrice,
          customizationImageUrl: customized
              ? 'https://example.com/custom-$index-0.jpg'
              : null,
        );
        notifier.addItem(firstItem);

        for (var tap = 0; tap < rapidAdds; tap++) {
          notifier.addItem(
            CartItemEntity(
              cartItemId: customized
                  ? 'cart-$index-${tap + 1}'
                  : firstItem.cartItemId,
              productId: firstItem.productId,
              productName: firstItem.productName,
              productImageUrl: firstItem.productImageUrl,
              selectedSize: firstItem.selectedSize,
              quantity: 1,
              unitPrice: originalPrice,
              customizationImageUrl: customized
                  ? 'https://example.com/custom-$index-${tap + 1}.jpg'
                  : null,
            ),
          );
        }

        notifier.setDeliveryOption(deliveryKey, deliveryPrice);
        notifier.applyCoupon('PERSONA$index', discount);
        notifier.applyProductUpdate(
          productId: firstItem.productId,
          basePrice: newPrice,
          sizePrices: const {},
          isActive: index != 19,
        );

        final state = container.read(cartProvider);
        if (index == 19) {
          expect(state.items, isEmpty);
          return;
        }

        final expectedLines = customized ? rapidAdds + 1 : 1;
        final expectedQuantity = customized
            ? initialQuantity + rapidAdds
            : math.min(
                initialQuantity + rapidAdds,
                CartNotifier.maxQuantityPerItem,
              );
        final expectedSubtotal = expectedQuantity * newPrice;
        final expectedTotal = math
            .max(0, expectedSubtotal + deliveryPrice - discount)
            .toDouble();

        expect(state.items, hasLength(expectedLines));
        expect(state.itemCount, expectedQuantity);
        expect(
          state.items.every(
            (item) => item.quantity <= CartNotifier.maxQuantityPerItem,
          ),
          isTrue,
        );
        expect(state.items.every((item) => item.unitPrice == newPrice), isTrue);
        expect(state.total, closeTo(expectedTotal, 0.001));
        expect(requiresOnlinePayment(state.total), expectedTotal > 0.005);

        final reopened = CartState.fromJson(state.toJson());
        expect(reopened.total, closeTo(state.total, 0.001));
        expect(reopened.itemCount, state.itemCount);
      });
    }
  });

  group('100-customer simulation: print-quality personas', () {
    const cases = [
      ('passport print', 1200, 1800, '4x6', 300, false),
      ('low-resolution poster', 600, 800, '12x18', 44, true),
      ('square print', 3000, 3000, '10x10', 300, false),
      ('decimal canvas', 2400, 3600, '8.5x12', 282, true),
      ('invalid size selection', 2400, 3600, 'Custom', null, false),
    ];
    for (var index = 0; index < cases.length; index++) {
      final persona = cases[index];
      test('persona ${index + 86}: ${persona.$1}', () {
        final metrics = LocalImageMetrics(
          width: persona.$2,
          height: persona.$3,
          fileSizeBytes: 2 * 1024 * 1024,
        );
        expect(metrics.dpiFor(persona.$4), persona.$5);
        expect(metrics.isLowResolutionFor(persona.$4), persona.$6);
      });
    }
  });

  group('100-customer simulation: accessibility and layout personas', () {
    for (var index = 0; index < _accessibilityPersonas.length; index++) {
      final persona = _accessibilityPersonas[index];
      testWidgets('persona ${index + 91}: ${persona.name}', (tester) async {
        tester.view.physicalSize = persona.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoriesProvider.overrideWith(
                (ref) async => [
                  CategoryEntity(
                    id: 'persona-category-$index',
                    name: persona.categoryName,
                    icon: 'image',
                    imageUrl: '',
                  ),
                ],
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(brightness: persona.brightness),
              home: MediaQuery(
                data: MediaQueryData(
                  size: persona.size,
                  textScaler: TextScaler.linear(persona.textScale),
                ),
                child: const Scaffold(
                  body: SingleChildScrollView(child: CategoryGrid()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(persona.categoryName), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
