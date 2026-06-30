import '../../domain/entities/delivery_order_entity.dart';

class DeliveryOrderModel extends DeliveryOrderEntity {
  const DeliveryOrderModel({
    required super.id,
    required super.status,
    required super.customerPhone,
    required super.pickupAddress,
    required super.deliveryAddress,
    required super.deliveryCity,
    required super.deliveryPincode,
    required super.totalPrice,
    required super.itemCount,
    super.deliveryLat,
    super.deliveryLng,
    super.proofUrl,
    super.assignedAt,
  });

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) =>
      DeliveryOrderModel(
        id: json['id'].toString(),
        status: json['status'] as String,
        customerPhone: json['customer_phone'] as String? ?? '',
        pickupAddress: json['pickup_address'] as String? ?? '',
        deliveryAddress: json['delivery_address'] as String? ?? '',
        deliveryCity: json['delivery_city'] as String? ?? '',
        deliveryPincode: json['delivery_pincode'] as String? ?? '',
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
        itemCount: json['item_count'] as int? ?? 0,
        deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
        deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
        proofUrl: json['proof_url'] as String?,
        assignedAt: json['assigned_at'] != null
            ? DateTime.parse(json['assigned_at'] as String)
            : null,
      );
}
