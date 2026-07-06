class BannerEntity {
  const BannerEntity({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkAction,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String? linkAction;
  final int sortOrder;
}
