import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/realtime_event.dart';
import '../../../core/realtime/realtime_service.dart';
import '../../customer/presentation/providers/cart_provider.dart';
import '../../customer/presentation/providers/catalog_provider.dart';
import '../../customer/presentation/providers/delivery_options_provider.dart';
import '../../customer/presentation/providers/orders_provider.dart';
import '../../customer/presentation/providers/products_provider.dart';
import '../../delivery/presentation/providers/delivery_provider.dart';

/// Bridges backend push events to Riverpod: each event invalidates only the
/// providers that depend on the changed data, so only the widgets watching
/// them rebuild (e.g. a banner change refreshes the banner carousel alone,
/// never the whole Home screen).
///
/// Keep this provider watched from a root widget (the app shells) so it stays
/// alive for the whole session.
final realtimeSyncProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  final sub = service.events.listen((event) => _dispatch(ref, event));
  ref.onDispose(sub.cancel);
});

void _dispatch(Ref ref, RealtimeEvent event) {
  switch (event.topic) {
    case RealtimeTopics.product:
      _onProductEvent(ref, event);
    case RealtimeTopics.category:
      ref.invalidate(categoriesProvider);
      // Category rename/visibility affects product listings too.
      ref.invalidate(productsProvider);
    case RealtimeTopics.banner:
      ref.invalidate(bannersProvider);
    case RealtimeTopics.coupon:
      ref.invalidate(offersProvider);
    case RealtimeTopics.deliverySetting:
      _onDeliverySettingEvent(ref, event);
    case RealtimeTopics.order:
      _onOrderEvent(ref, event);
    default:
      break; // setting/user events have no live consumers yet
  }
}

void _onProductEvent(Ref ref, RealtimeEvent event) {
  // Refresh every product listing (family invalidate covers all categories),
  // the home sections, and any visible search results.
  ref.invalidate(productsProvider);
  ref.invalidate(featuredProductsProvider);
  ref.invalidate(trendingProductsProvider);
  ref.invalidate(searchProductsProvider);

  final id = event.entityId;
  if (id != null) {
    // An open Product Details screen refetches in place.
    ref.invalidate(productDetailProvider(id));
  }

  // Live cart repricing — the event carries the full product payload.
  final cart = ref.read(cartProvider.notifier);
  if (event.action == RealtimeActions.deleted) {
    if (id != null) cart.removeProductItems(id);
    return;
  }
  final data = event.data;
  if (id == null || data == null) return;

  final sizePrices = <String, double>{};
  final sizes = data['sizes'];
  if (sizes is List) {
    for (final entry in sizes) {
      if (entry is Map && entry['label'] is String && entry['price'] is num) {
        sizePrices[entry['label'] as String] =
            (entry['price'] as num).toDouble();
      }
    }
  }
  cart.applyProductUpdate(
    productId: id,
    basePrice: (data['base_price'] as num?)?.toDouble() ?? 0,
    sizePrices: sizePrices,
    isActive: data['is_active'] as bool? ?? true,
  );
}

void _onDeliverySettingEvent(Ref ref, RealtimeEvent event) {
  ref.invalidate(deliveryOptionsProvider);
  final data = event.data;
  final type = event.entityId;
  final price = (data?['price'] as num?)?.toDouble();
  if (type != null && price != null) {
    ref.read(cartProvider.notifier).applyDeliverySettingUpdate(type, price);
  }
}

void _onOrderEvent(Ref ref, RealtimeEvent event) {
  // Customer side: order history list + any open order detail screen.
  ref.invalidate(myOrdersProvider);
  final id = event.entityId;
  if (id != null) {
    ref.invalidate(orderDetailProvider(id));
  }
  // Delivery-partner side: assigned orders list (new assignment or status).
  ref.invalidate(assignedOrdersProvider);
}
