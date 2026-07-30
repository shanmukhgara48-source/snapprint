import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/ai_editor_models.dart';

class AiEditorService {
  AiEditorService(this._client);
  final ApiClient _client;

  Future<bool> isEnabled() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.aiPhotoStatus,
    );
    return response.data?['enabled'] == true;
  }

  Future<AiEditResult> edit({
    required String imageUrl,
    required String operation,
    required String productName,
    required String selectedSize,
    String prompt = '',
    String? maskImageBase64,
    String? previousInteractionId,
    bool rightsConfirmed = false,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.aiPhotoEdit,
      data: {
        'image_url': imageUrl,
        'operation': operation,
        'prompt': prompt,
        'product_name': productName,
        'selected_size': selectedSize,
        'mask_image_base64': maskImageBase64,
        'previous_interaction_id': previousInteractionId,
        'rights_confirmed': rightsConfirmed,
      },
    );
    return AiEditResult.fromJson(response.data ?? const {});
  }

  Future<AiPrintAnalysis> analyze({
    required String imageUrl,
    required String productName,
    required String selectedSize,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.aiPhotoAnalyze,
      data: {
        'image_url': imageUrl,
        'product_name': productName,
        'selected_size': selectedSize,
      },
    );
    return AiPrintAnalysis.fromJson(response.data ?? const {});
  }
}

final aiEditorServiceProvider = Provider<AiEditorService>((ref) {
  return AiEditorService(ref.read(apiClientProvider));
});
