import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/core/network/api_client.dart';
import 'package:snap_print/core/network/api_endpoints.dart';
import 'package:snap_print/features/ai_editor/data/upload_repository.dart';

class _FakeApiClient extends ApiClient {
  String? path;
  FormData? formData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    formData = data as FormData;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data:
          <String, dynamic>{
                'public_url':
                    'https://cdn.example.com/customizations/user/photo.png',
              }
              as T,
    );
  }
}

void main() {
  test('maps Apple HEIC and HEIF uploads to their real MIME types', () {
    expect(imageContentTypeForFilename('IMG_1234.HEIC'), 'image/heic');
    expect(imageContentTypeForFilename('portrait.heif'), 'image/heif');
  });

  test(
    'uploads through the validated backend endpoint as multipart data',
    () async {
      final client = _FakeApiClient();
      final repository = UploadRepository(client);

      final url = await repository.uploadBytes(
        bytes: const [137, 80, 78, 71],
        filename: 'photo.png',
        contentType: 'image/png',
      );

      expect(client.path, ApiEndpoints.uploadImage);
      expect(client.formData?.files.single.key, 'file');
      expect(client.formData?.files.single.value.filename, 'photo.png');
      expect(
        client.formData?.files.single.value.contentType.toString(),
        'image/png',
      );
      expect(url, 'https://cdn.example.com/customizations/user/photo.png');
    },
  );
}
