import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/delivery_order_model.dart';

class DeliveryRemoteDataSource {
  DeliveryRemoteDataSource(this._client);
  final ApiClient _client;

  Future<List<DeliveryOrderModel>> getAssignedOrders() async {
    final response = await _client.get(ApiEndpoints.deliveryAssigned);
    final items = response.data as List<dynamic>;
    return items
        .map((e) => DeliveryOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(
    String orderId,
    String status, {
    String? proofUrl,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (proofUrl != null) data['proof_url'] = proofUrl;
    await _client.patch(ApiEndpoints.deliveryUpdateStatus(orderId), data: data);
  }

  Future<String> uploadProof(String orderId, String filePath) async {
    final extension = filePath.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      _ => DioMediaType('image', 'jpeg'),
    };
    final response = await _client.post(
      ApiEndpoints.deliveryUploadProof(orderId),
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          contentType: contentType,
        ),
      }),
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return (response.data as Map<String, dynamic>)['proof_url'] as String;
  }
}

final deliveryDataSourceProvider = Provider<DeliveryRemoteDataSource>((ref) {
  return DeliveryRemoteDataSource(ref.read(apiClientProvider));
});
