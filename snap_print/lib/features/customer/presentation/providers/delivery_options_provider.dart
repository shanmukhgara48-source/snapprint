import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class DeliveryOptionModel {
  const DeliveryOptionModel({
    required this.type,
    required this.label,
    required this.price,
    required this.daysLabel,
  });

  final String type;
  final String label;
  final double price;
  final String daysLabel;

  factory DeliveryOptionModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOptionModel(
      type: json['type'] as String,
      label: json['label'] as String,
      price: (json['price'] as num).toDouble(),
      daysLabel: json['days_label'] as String,
    );
  }
}

final deliveryOptionsProvider =
    FutureProvider<List<DeliveryOptionModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get(ApiEndpoints.deliveryOptions);
  final items = response.data as List<dynamic>;
  return items
      .map((e) => DeliveryOptionModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
