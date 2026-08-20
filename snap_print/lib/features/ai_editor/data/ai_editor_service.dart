import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/ai_editor_models.dart';
import '../domain/editor_document.dart';

/// Gemini image generation can take well beyond the app's default 15s
/// timeout — give edit/analyze calls more room before failing.
///
/// Production workers should respond in seconds; one minute leaves enough
/// room for cold starts without hanging checkout/editor flows indefinitely.
final _aiCallOptions = Options(
  sendTimeout: const Duration(minutes: 1),
  receiveTimeout: const Duration(minutes: 1),
);

class AiEditorService {
  AiEditorService(this._client);
  final ApiClient _client;

  Future<AiEditorCapabilities> capabilities() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.aiPhotoStatus,
    );
    return AiEditorCapabilities.fromJson(response.data ?? const {});
  }

  Future<bool> isEnabled() async {
    return (await capabilities()).enabled;
  }

  Future<BackgroundRemovalResult> removeBackground({
    required String imageUrl,
    bool highQuality = true,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.aiPhotoRemoveBackground,
      data: {
        'image_url': imageUrl,
        'quality': highQuality ? 'high' : 'standard',
        'refine_foreground': true,
        'preserve_existing_alpha': true,
      },
      options: _aiCallOptions,
    );
    return BackgroundRemovalResult.fromJson(response.data ?? const {});
  }

  Future<AiExportResult> export({
    required EditorDocument document,
    required String selectedSize,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.aiPhotoExport,
      data: {
        'image_url': document.workingImageUrl,
        'background': document.background.toJson(),
        'adjustments': document.adjustments.toJson(),
        'transform': document.transform.toJson(),
        'selected_size': selectedSize,
        'output_format': 'auto',
      },
      options: _aiCallOptions,
    );
    return AiExportResult.fromJson(response.data ?? const {});
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
      options: _aiCallOptions,
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
      options: _aiCallOptions,
    );
    return AiPrintAnalysis.fromJson(response.data ?? const {});
  }
}

final aiEditorServiceProvider = Provider<AiEditorService>((ref) {
  return AiEditorService(ref.read(apiClientProvider));
});
