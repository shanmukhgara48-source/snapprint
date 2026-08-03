import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

String imageContentTypeForFilename(String filename) {
  final extension = filename.contains('.')
      ? filename.split('.').last.toLowerCase()
      : '';
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    _ => 'image/jpeg',
  };
}

/// Authenticated image upload shared by customization and local editor flows.
class UploadRepository {
  UploadRepository(this._client);
  final ApiClient _client;

  Future<String> uploadBytes({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.uploadImage,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      }),
      options: Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final publicUrl = response.data?['public_url'] as String?;
    if (publicUrl == null) throw Exception('Invalid upload response');
    return publicUrl;
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.read(apiClientProvider));
});
