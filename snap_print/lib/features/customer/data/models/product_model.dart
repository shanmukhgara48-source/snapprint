import 'package:cloud_firestore/cloud_firestore.dart';
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
    required super.imageUrl,
    super.description,
    super.material,
    super.deliveryInfo,
    super.sortOrder,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      basePrice: (json['basePrice'] as num).toDouble(),
      sizes: (json['sizes'] as List<dynamic>? ?? [])
          .map((s) => ProductSizeModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String?,
      material: json['material'] as String?,
      deliveryInfo: json['deliveryInfo'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  // Legacy REST API factory (keeps existing backend calls working)
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        categoryId: json['category'] as String? ?? '',
        categoryName: json['category'] as String? ?? '',
        basePrice: (json['base_price'] as num).toDouble(),
        sizes: (json['sizes'] as List<dynamic>? ?? [])
            .map((s) => ProductSizeModel.fromJson(s as Map<String, dynamic>))
            .toList(),
        imageUrl: json['image_url'] as String? ?? '',
        description: json['description'] as String?,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'basePrice': basePrice,
        'sizes': sizes
            .map((s) => ProductSizeModel(label: s.label, price: s.price).toJson())
            .toList(),
        'imageUrl': imageUrl,
        'description': description,
        'material': material,
        'deliveryInfo': deliveryInfo,
        'sortOrder': sortOrder,
        'isActive': true,
      };
}
