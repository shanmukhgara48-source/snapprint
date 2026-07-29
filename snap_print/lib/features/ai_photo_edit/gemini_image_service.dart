import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Thrown for any failure talking to the AI editing service — network, auth,
/// or the model declining to return an image (e.g. safety filters).
class GeminiImageException implements Exception {
  GeminiImageException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Client for the backend's Gemini image-edit proxy (`/ai/*`).
///
/// The Gemini API key deliberately lives on the server: a key baked into the
/// app with --dart-define is recoverable from the built APK/IPA and can be
/// used outside the app. The backend holds the key, authenticates the caller
/// and rate limits requests.
class GeminiImageService {
  GeminiImageService(this._client);
  final ApiClient _client;

  // Image generation routinely takes tens of seconds — well past ApiClient's
  // 15s defaults, so this one call gets its own budget.
  static Options get _editOptions => Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 90),
  );

  /// Whether the server has a Gemini key configured. UI should check this
  /// before offering AI editing rather than letting the call fail.
  Future<bool> isConfigured() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.aiStatus,
      );
      return response.data?['configured'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Sends [imageBytes] (and an optional [doodleBytes] mask overlay) plus
  /// [prompt] to the backend proxy and returns the edited image bytes.
  Future<Uint8List> editImage({
    required Uint8List imageBytes,
    required String imageMimeType,
    required String prompt,
    Uint8List? doodleBytes,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.aiEditImage,
        options: _editOptions,
        data: {
          'image_base64': base64Encode(imageBytes),
          'mime_type': imageMimeType,
          'prompt': prompt,
          if (doodleBytes != null) 'doodle_base64': base64Encode(doodleBytes),
        },
      );

      final data = response.data?['image_base64'] as String?;
      if (data == null || data.isEmpty) {
        throw GeminiImageException(
          'The AI service did not return an edited image — try a different prompt.',
        );
      }
      return base64Decode(data);
    } on GeminiImageException {
      rethrow;
    } on DioException catch (e) {
      // ApiClient's error interceptor already maps the response to a friendly
      // AppException message (including the server's `detail`).
      final error = e.error;
      throw GeminiImageException(
        error is AppException
            ? error.message
            : 'AI editing failed — check your connection and try again.',
      );
    } catch (e) {
      throw GeminiImageException('Unexpected error: $e');
    }
  }
}

final geminiImageServiceProvider = Provider<GeminiImageService>(
  (ref) => GeminiImageService(ref.read(apiClientProvider)),
);

/// Cached feature flag for the AI editing entry points.
final aiEditAvailableProvider = FutureProvider<bool>(
  (ref) => ref.read(geminiImageServiceProvider).isConfigured(),
);
