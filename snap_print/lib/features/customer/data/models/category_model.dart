import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    super.imageUrl,
    super.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}
