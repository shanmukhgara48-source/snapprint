import '../../domain/entities/order_entity.dart';

class OrderTrackingEventModel extends OrderTrackingEvent {
  const OrderTrackingEventModel({
    required super.status,
    required super.timestamp,
  });

  factory OrderTrackingEventModel.fromJson(Map<String, dynamic> json) =>
      OrderTrackingEventModel(
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.totalPrice,
    required super.status,
    required super.createdAt,
    required super.itemCount,
    super.deliveryAddress,
    super.estimatedDelivery,
    super.trackingEvents,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'].toString(),
        totalPrice: (json['total_price'] as num).toDouble(),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        itemCount: json['item_count'] as int? ?? 0,
        deliveryAddress: json['delivery_address'] as String?,
        estimatedDelivery: json['estimated_delivery'] != null
            ? DateTime.parse(json['estimated_delivery'] as String)
            : null,
        trackingEvents: (json['tracking_events'] as List<dynamic>? ?? [])
            .map((e) =>
                OrderTrackingEventModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
