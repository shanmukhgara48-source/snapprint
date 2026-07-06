import '../../domain/entities/offer_entity.dart';

class OfferModel extends OfferEntity {
  const OfferModel({
    required super.code,
    required super.discountType,
    required super.value,
    required super.minOrder,
    super.expiresAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) => OfferModel(
        code: json['code'] as String,
        discountType: json['discount_type'] as String,
        value: (json['value'] as num).toDouble(),
        minOrder: (json['min_order'] as num?)?.toDouble() ?? 0,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
      );
}
