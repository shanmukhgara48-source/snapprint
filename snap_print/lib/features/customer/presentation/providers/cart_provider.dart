import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.totalPrice);

  double get deliveryCharge => deliveryPrice ?? deliveryType.price;

  double get total => (subtotal + deliveryCharge - discount).clamp(0, double.infinity);

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
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(CartItemEntity item) {
    final existing = state.items.indexWhere(
      (e) => e.productId == item.productId && e.selectedSize == item.selectedSize,
    );
    if (existing >= 0) {
      final updated = List<CartItemEntity>.from(state.items);
      updated[existing] =
          updated[existing].copyWith(quantity: updated[existing].quantity + item.quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
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
    final updated = state.items.map((e) {
      return e.cartItemId == cartItemId ? e.copyWith(quantity: quantity) : e;
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
    );
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
