class OfferEntity {
  const OfferEntity({
    required this.code,
    required this.discountType,
    required this.value,
    required this.minOrder,
    this.expiresAt,
  });

  final String code;
  final String discountType;
  final double value;
  final double minOrder;
  final DateTime? expiresAt;
}
