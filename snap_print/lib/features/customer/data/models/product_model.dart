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
    super.startingPrice,
    super.description,
    super.material,
    super.deliveryInfo,
    super.minConfig,
    super.quantity,
    super.sizeDetails,
    super.sourceUrl,
    super.priceSource,
    super.confidenceScore,
    super.sortOrder,
    super.stockQuantity,
    super.isFeatured,
    super.isTrending,
  });

  // REST API factory — matches the Postgres-backed /products response shape.
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'].toString(),
    name: json['name'] as String,
    categoryId:
        json['category_id'] as String? ?? json['category'] as String? ?? '',
    categoryName: json['category'] as String? ?? '',
    basePrice:
        (json['base_price'] as num? ??
                json['basePrice'] as num? ??
                json['starting_price'] as num? ??
                json['startingPrice'] as num? ??
                0)
            .toDouble(),
    sizes: (json['sizes'] as List<dynamic>? ?? [])
        .map((s) => ProductSizeModel.fromJson(s as Map<String, dynamic>))
        .toList(),
    images: (json['images'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    startingPrice:
        (json['starting_price'] as num? ?? json['startingPrice'] as num?)
            ?.toInt(),
    description: json['description'] as String?,
    material: json['material'] as String?,
    deliveryInfo:
        json['delivery_info'] as String? ?? json['deliveryInfo'] as String?,
    minConfig: json['min_config'] as String? ?? json['minConfig'] as String?,
    quantity: json['quantity'] as String?,
    sizeDetails:
        json['size_details'] as String? ?? json['sizeDetails'] as String?,
    sourceUrl: json['source_url'] as String? ?? json['sourceUrl'] as String?,
    priceSource:
        json['price_source'] as String? ?? json['priceSource'] as String?,
    confidenceScore:
        json['confidence_score'] as String? ??
        json['confidenceScore'] as String?,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
    isFeatured: json['is_featured'] as bool? ?? false,
    isTrending: json['is_trending'] as bool? ?? false,
  );
}
