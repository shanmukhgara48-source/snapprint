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
    this.startingPrice,
    this.description,
    this.material,
    this.deliveryInfo,
    this.minConfig,
    this.quantity,
    this.sizeDetails,
    this.sourceUrl,
    this.priceSource,
    this.confidenceScore,
    this.sortOrder = 0,
    this.stockQuantity = 0,
    this.isFeatured = false,
    this.isTrending = false,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final List<ProductSize> sizes;
  final List<String> images;
  final int? startingPrice;
  final String? description;
  final String? material;
  final String? deliveryInfo;
  final String? minConfig;
  final String? quantity;
  final String? sizeDetails;
  final String? sourceUrl;
  final String? priceSource;
  final String? confidenceScore;
  final int sortOrder;
  final int stockQuantity;
  final bool isFeatured;
  final bool isTrending;

  // Legacy getter so existing code using .category still compiles
  String get category => categoryId;

  // Primary/cover image — most call sites only need one image.
  String get imageUrl => images.isNotEmpty ? images.first : '';

  /// The price to show and charge. Some API rows carry only `starting_price`
  /// and leave `base_price` at 0 — falling back keeps those from displaying ₹0.
  double get effectivePrice =>
      basePrice > 0 ? basePrice : (startingPrice?.toDouble() ?? 0);

  bool get hasKnownPrice => effectivePrice > 0;

  String get priceLabel => hasKnownPrice
      ? '₹${effectivePrice.toStringAsFixed(0)}'
      : 'Price unavailable';
}
