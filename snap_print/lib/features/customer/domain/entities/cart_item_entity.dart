class CartItemEntity {
  const CartItemEntity({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.selectedSize,
    required this.quantity,
    required this.unitPrice,
    this.customizationImageUrl,
    this.customizationData,
  });

  final String cartItemId;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String selectedSize;
  final int quantity;
  final double unitPrice;
  final String? customizationImageUrl;
  final Map<String, dynamic>? customizationData;

  double get totalPrice => unitPrice * quantity;

  CartItemEntity copyWith({
    int? quantity,
    double? unitPrice,
    String? customizationImageUrl,
  }) {
    return CartItemEntity(
      cartItemId: cartItemId,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      selectedSize: selectedSize,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      customizationImageUrl:
          customizationImageUrl ?? this.customizationImageUrl,
      customizationData: customizationData,
    );
  }
}
