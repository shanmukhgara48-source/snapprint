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
    required this.imageUrl,
    this.description,
    this.material,
    this.deliveryInfo,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final List<ProductSize> sizes;
  final String imageUrl;
  final String? description;
  final String? material;
  final String? deliveryInfo;
  final int sortOrder;

  // Legacy getter so existing code using .category still compiles
  String get category => categoryId;
}
