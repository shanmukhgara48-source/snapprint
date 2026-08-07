import '../../domain/entities/product_entity.dart';

class ProductSizeModel extends ProductSize {
  const ProductSizeModel({required super.label, required super.price});

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) =>
      ProductSizeModel(
        label: json['label'] as String,
        price: (json['price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'label': label, 'price': price};
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.categoryId,
    required super.categoryName,
    required super.basePrice,
    required super.sizes,
    required super.images,
    super.description,
    super.material,
    super.dimensions,
    super.optionsSummary,
    super.deliveryInfo,
    super.priceNote,
    super.sortOrder,
    super.stockQuantity,
    super.tracksInventory,
    super.isFeatured,
    super.isTrending,
    super.isOrderable,
  });

  // REST API factory — matches the Postgres-backed /products response shape.
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'].toString(),
    name: json['name'] as String,
    categoryId:
        json['category_id'] as String? ?? json['category'] as String? ?? '',
    categoryName: json['category'] as String? ?? '',
    basePrice:
        (json['base_price'] as num? ?? json['starting_price'] as num? ?? 0)
            .toDouble(),
    sizes: (json['sizes'] as List<dynamic>? ?? [])
        .map((s) => ProductSizeModel.fromJson(s as Map<String, dynamic>))
        .toList(),
    images: (json['images'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    description: json['description'] as String?,
    material: json['material'] as String?,
    dimensions: json['dimensions'] as String?,
    optionsSummary: json['options_summary'] as String?,
    deliveryInfo: json['delivery_info'] as String?,
    priceNote: json['price_note'] as String?,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
    tracksInventory: json['tracks_inventory'] as bool? ?? false,
    isFeatured: json['is_featured'] as bool? ?? false,
    isTrending: json['is_trending'] as bool? ?? false,
    isOrderable: json['is_orderable'] as bool? ?? true,
  );
}
