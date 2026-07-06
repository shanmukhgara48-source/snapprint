import '../../domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  const BannerModel({
    required super.id,
    required super.title,
    required super.imageUrl,
    super.linkAction,
    super.sortOrder,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        id: json['id'] as String,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String? ?? '',
        linkAction: json['link_action'] as String?,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}
