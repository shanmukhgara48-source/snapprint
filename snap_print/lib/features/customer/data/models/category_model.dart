import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    super.imageUrl,
    super.sortOrder,
    super.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: _stringValue(json['id']),
    name: _stringValue(json['name']),
    icon: _stringValue(json['icon']),
    imageUrl: _nullableStringValue(json['image_url']),
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    isActive: json['is_active'] as bool? ?? true,
  );

  static String _stringValue(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String? _nullableStringValue(Object? value) {
    final text = _stringValue(value).trim();
    return text.isEmpty ? null : text;
  }
}
