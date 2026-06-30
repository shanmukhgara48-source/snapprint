class DeliveryOrderEntity {
  const DeliveryOrderEntity({
    required this.id,
    required this.status,
    required this.customerPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryPincode,
    required this.totalPrice,
    required this.itemCount,
    this.deliveryLat,
    this.deliveryLng,
    this.proofUrl,
    this.assignedAt,
  });

  final String id;
  final String status;
  final String customerPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryPincode;
  final double totalPrice;
  final int itemCount;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? proofUrl;
  final DateTime? assignedAt;
}
