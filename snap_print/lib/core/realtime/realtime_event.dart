/// A domain event pushed by the backend over WebSocket.
///
/// Mirrors the server envelope emitted by `app/services/event_bus.py`:
/// `{"type": "event", "topic": ..., "action": ..., "entity_id": ..., "data": ..., "ts": ..., "v": 1}`
class RealtimeEvent {
  const RealtimeEvent({
    required this.topic,
    required this.action,
    this.entityId,
    this.data,
  });

  final String topic;
  final String action;
  final String? entityId;
  final Map<String, dynamic>? data;

  static RealtimeEvent? tryParse(Map<String, dynamic> json) {
    final topic = json['topic'];
    final action = json['action'];
    if (topic is! String || action is! String) return null;
    return RealtimeEvent(
      topic: topic,
      action: action,
      entityId: json['entity_id'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  @override
  String toString() => 'RealtimeEvent($topic.$action id=$entityId)';
}

/// Topics emitted by the backend — keep in sync with event_bus.py.
abstract final class RealtimeTopics {
  static const product = 'product';
  static const category = 'category';
  static const banner = 'banner';
  static const coupon = 'coupon';
  static const deliverySetting = 'delivery_setting';
  static const setting = 'setting';
  static const order = 'order';
  static const review = 'review';
  static const user = 'user';
}

abstract final class RealtimeActions {
  static const created = 'created';
  static const updated = 'updated';
  static const deleted = 'deleted';
  static const statusChanged = 'status_changed';
  static const assigned = 'assigned';
  static const roleChanged = 'role_changed';
}
