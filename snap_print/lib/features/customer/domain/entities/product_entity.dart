class ProductSize {
  const ProductSize({required this.label, required this.price});
  final String label;
  final double price;
}

class ProductEntity {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.basePrice,
    required this.sizes,
    required this.images,
    this.description,
    this.material,
    this.dimensions,
    this.optionsSummary,
    this.deliveryInfo,
    this.priceNote,
    this.sortOrder = 0,
    this.stockQuantity = 0,
    this.tracksInventory = false,
    this.sku,
    this.compareAtPrice,
    this.isBestseller = false,
    this.isFeatured = false,
    this.isTrending = false,
    this.isOrderable = true,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final List<ProductSize> sizes;
  final List<String> images;
  final String? description;
  final String? material;
  final String? dimensions;
  final String? optionsSummary;
  final String? deliveryInfo;
  final String? priceNote;
  final int sortOrder;
  final int stockQuantity;
  final bool tracksInventory;
  final String? sku;
  final double? compareAtPrice;
  final bool isBestseller;
  final bool isFeatured;
  final bool isTrending;
  final bool isOrderable;

  // Legacy getter so existing code using .category still compiles
  String get category => categoryId;

  // Primary/cover image — most call sites only need one image.
  String get imageUrl => images.isNotEmpty ? images.first : '';

  double get effectivePrice {
    final prices = <double>[
      if (basePrice > 0) basePrice,
      ...sizes.where((size) => size.price > 0).map((size) => size.price),
    ];
    if (prices.isEmpty) return 0;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  bool get hasKnownPrice => effectivePrice > 0;

  String get priceLabel {
    if (!isOrderable) return 'Pricing coming soon';
    return hasKnownPrice
        ? 'From ₹${effectivePrice.toStringAsFixed(0)}'
        : 'Price unavailable';
  }

  bool get isInStock => !tracksInventory || stockQuantity > 0;

  bool get canOrder => isOrderable && hasKnownPrice && isInStock;

  /// Amazon-style deal: strike-through MRP + % off (display-only).
  bool get hasSale =>
      compareAtPrice != null && compareAtPrice! > effectivePrice && effectivePrice > 0;

  int get discountPercent => !hasSale
      ? 0
      : (((compareAtPrice! - effectivePrice) / compareAtPrice!) * 100).round();
}
