class OrderTrackingEvent {
  const OrderTrackingEvent({
    required this.status,
    required this.timestamp,
  });
  final String status;
  final DateTime timestamp;
}

class OrderEntity {
  const OrderEntity({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.itemCount,
    this.deliveryAddress,
    this.estimatedDelivery,
    this.trackingEvents = const [],
  });

  final String id;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final int itemCount;
  final String? deliveryAddress;
  final DateTime? estimatedDelivery;
  final List<OrderTrackingEvent> trackingEvents;
}
