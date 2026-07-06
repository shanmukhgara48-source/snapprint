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
    this.deliveryInfo,
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
  final String? description;
  final String? material;
  final String? deliveryInfo;
  final int sortOrder;
  final int stockQuantity;
  final bool isFeatured;
  final bool isTrending;

  // Legacy getter so existing code using .category still compiles
  String get category => categoryId;

  // Primary/cover image — most call sites only need one image.
  String get imageUrl => images.isNotEmpty ? images.first : '';
}
