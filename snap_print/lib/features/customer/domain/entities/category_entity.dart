class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String icon;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
}
