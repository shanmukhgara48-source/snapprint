import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/cart_item_entity.dart';

enum DeliveryType { free, standard, express }

extension DeliveryTypeExt on DeliveryType {
  String get label {
    switch (this) {
      case DeliveryType.free:
        return 'Free Delivery';
      case DeliveryType.standard:
        return 'Standard Delivery';
      case DeliveryType.express:
        return 'Express Delivery';
    }
  }

  double get price {
    switch (this) {
      case DeliveryType.free:
        return 0;
      case DeliveryType.standard:
        return 49;
      case DeliveryType.express:
        return 99;
    }
  }

  String get days {
    switch (this) {
      case DeliveryType.free:
        return '5-7 business days';
      case DeliveryType.standard:
        return '3-4 business days';
      case DeliveryType.express:
        return '1-2 business days';
    }
  }
}

class CartState {
  const CartState({
    this.items = const [],
    this.deliveryType = DeliveryType.free,
    this.deliveryTypeKey = 'free',
    this.deliveryPrice,
    this.couponCode,
    this.discount = 0,
  });

  final List<CartItemEntity> items;
  final DeliveryType deliveryType;

  /// The selected delivery type key (e.g. 'free', 'standard', 'express') from API.
  final String deliveryTypeKey;

  /// Price from the API response (overrides enum default when set).
  final double? deliveryPrice;
  final String? couponCode;
  final double discount;

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  double get deliveryCharge => deliveryPrice ?? deliveryType.price;

  double get total =>
      (subtotal + deliveryCharge - discount).clamp(0, double.infinity);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItemEntity>? items,
    DeliveryType? deliveryType,
    String? deliveryTypeKey,
    double? deliveryPrice,
    String? couponCode,
    double? discount,
  }) {
    return CartState(
      items: items ?? this.items,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryTypeKey: deliveryTypeKey ?? this.deliveryTypeKey,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'deliveryTypeKey': deliveryTypeKey,
    'deliveryPrice': deliveryPrice,
    'couponCode': couponCode,
    'discount': discount,
  };

  factory CartState.fromJson(Map<String, dynamic> json) {
    final typeKey = json['deliveryTypeKey'] as String? ?? 'free';
    return CartState(
      items: (json['items'] as List? ?? [])
          .map(
            (e) => CartItemEntity.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      deliveryType: DeliveryType.values.firstWhere(
        (e) => e.name == typeKey,
        orElse: () => DeliveryType.free,
      ),
      deliveryTypeKey: typeKey,
      deliveryPrice: (json['deliveryPrice'] as num?)?.toDouble(),
      couponCode: json['couponCode'] as String?,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  static const _prefsKey = 'cart_v1';
  static const maxQuantityPerItem = 99;

  @override
  CartState build() {
    // Persist on every change; hydration below is async so the very first
    // frame renders an empty cart, then fills in once disk read completes.
    listenSelf((_, next) => _persist(next));
    _hydrate();
    return const CartState();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = CartState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt/outdated cart payload from a previous app version — drop it
      // rather than crash the app on startup.
      await prefs.remove(_prefsKey);
    }
  }

  Future<void> _persist(CartState cartState) async {
    final prefs = await SharedPreferences.getInstance();
    if (cartState.items.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, jsonEncode(cartState.toJson()));
    }
  }

  void addItem(CartItemEntity item) {
    // Photo items (with customization image) are always unique line items — never merge
    final hasCustomization =
        item.customizationImageUrl != null &&
        item.customizationImageUrl!.isNotEmpty;
    if (hasCustomization) {
      state = state.copyWith(items: [...state.items, item]);
      return;
    }

    // Non-photo items: merge by productId + selectedSize
    final existing = state.items.indexWhere(
      (e) =>
          e.productId == item.productId &&
          e.selectedSize == item.selectedSize &&
          (e.customizationImageUrl == null || e.customizationImageUrl!.isEmpty),
    );
    if (existing >= 0) {
      final updated = List<CartItemEntity>.from(state.items);
      updated[existing] = updated[existing].copyWith(
        quantity: (updated[existing].quantity + item.quantity).clamp(
          1,
          maxQuantityPerItem,
        ),
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          item.copyWith(quantity: item.quantity.clamp(1, maxQuantityPerItem)),
        ],
      );
    }
  }

  void removeItem(String cartItemId) {
    state = state.copyWith(
      items: state.items.where((e) => e.cartItemId != cartItemId).toList(),
    );
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    final boundedQuantity = quantity.clamp(1, maxQuantityPerItem);
    final updated = state.items.map((e) {
      return e.cartItemId == cartItemId
          ? e.copyWith(quantity: boundedQuantity)
          : e;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void setDeliveryType(DeliveryType type) {
    state = state.copyWith(deliveryType: type, deliveryTypeKey: type.name);
  }

  /// Called from checkout screen with API-fetched option data.
  void setDeliveryOption(String typeKey, double price) {
    final mapped = DeliveryType.values.firstWhere(
      (e) => e.name == typeKey,
      orElse: () => DeliveryType.free,
    );
    state = state.copyWith(
      deliveryType: mapped,
      deliveryTypeKey: typeKey,
      deliveryPrice: price,
    );
  }

  void applyCoupon(String code, double discount) {
    state = state.copyWith(couponCode: code, discount: discount);
  }

  void removeCoupon() {
    state = CartState(
      items: state.items,
      deliveryType: state.deliveryType,
      deliveryTypeKey: state.deliveryTypeKey,
      deliveryPrice: state.deliveryPrice,
      // couponCode and discount reset to defaults (null / 0)
    );
  }

  void clearCart() {
    state = const CartState();
  }

  /// Realtime sync: admin changed a product — reprice matching cart lines so
  /// subtotal/total update live. A deactivated/deleted product is removed.
  void applyProductUpdate({
    required String productId,
    required double basePrice,
    required Map<String, double> sizePrices,
    required bool isActive,
  }) {
    if (!state.items.any((e) => e.productId == productId)) return;

    if (!isActive) {
      removeProductItems(productId);
      return;
    }

    final updated = state.items.map((item) {
      if (item.productId != productId) return item;
      final newPrice = sizePrices[item.selectedSize] ?? basePrice;
      return newPrice == item.unitPrice
          ? item
          : item.copyWith(unitPrice: newPrice);
    }).toList();
    state = state.copyWith(items: updated);
  }

  /// Realtime sync: product deleted by admin — drop its cart lines.
  void removeProductItems(String productId) {
    if (!state.items.any((e) => e.productId == productId)) return;
    state = state.copyWith(
      items: state.items.where((e) => e.productId != productId).toList(),
    );
  }

  /// Realtime sync: admin changed delivery charges — reprice the selected
  /// delivery option so the cart total updates live.
  void applyDeliverySettingUpdate(String typeKey, double price) {
    if (state.deliveryTypeKey != typeKey) return;
    if (state.deliveryPrice == price) return;
    state = state.copyWith(deliveryPrice: price);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
