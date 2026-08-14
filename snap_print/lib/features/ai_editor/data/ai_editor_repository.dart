import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/ai_editor_models.dart';
import '../domain/local_image_metrics.dart';
import '../domain/editor_document.dart';
import 'ai_editor_service.dart';
import 'local_image_processor.dart';
import 'upload_repository.dart';

/// Stable boundary between editor state and remote processing/storage.
class AiEditorRepository {
  AiEditorRepository({
    required AiEditorService service,
    required LocalImageProcessor localProcessor,
    required UploadRepository uploadRepository,
  }) : _service = service,
       _local = localProcessor,
       _upload = uploadRepository;

  final AiEditorService _service;
  final LocalImageProcessor _local;
  final UploadRepository _upload;

  Future<bool> isEnabled() => _service.isEnabled();

  Future<AiEditorCapabilities> capabilities() => _service.capabilities();

  Future<BackgroundRemovalResult> removeBackground(String imageUrl) =>
      _service.removeBackground(imageUrl: imageUrl);

  Future<AiExportResult> export({
    required EditorDocument document,
    required String selectedSize,
  }) => _service.export(document: document, selectedSize: selectedSize);

  Future<AiPrintAnalysis> analyze({
    required String imageUrl,
    required String productName,
    required String selectedSize,
  }) => _service.analyze(
    imageUrl: imageUrl,
    productName: productName,
    selectedSize: selectedSize,
  );

  Future<AiEditResult> editOnServer({
    required String imageUrl,
    required String operation,
    required String productName,
    required String selectedSize,
    String prompt = '',
    String? maskImageBase64,
    String? previousInteractionId,
    bool rightsConfirmed = false,
  }) => _service.edit(
    imageUrl: imageUrl,
    operation: operation,
    prompt: prompt,
    productName: productName,
    selectedSize: selectedSize,
    maskImageBase64: maskImageBase64,
    previousInteractionId: previousInteractionId,
    rightsConfirmed: rightsConfirmed,
  );

  /// Downloads [imageUrl], computes on-device metrics, without uploading
  /// anything — used for the print-quality panel.
  Future<LocalImageMetrics> computeLocalMetrics(String imageUrl) async {
    final bytes = await _local.downloadBytes(imageUrl);
    return _local.metricsFromBytes(bytes);
  }

  Future<String> uploadCustomBackground({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) => _upload.uploadBytes(
    bytes: bytes,
    filename: filename,
    contentType: contentType,
  );

  /// A friendly, non-technical message for the given error, for
  /// `showErrorSnackbar`.
  String friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('Gemini AI editor is not configured')) {
      return 'AI Photo Studio is not configured yet.';
    }
    if (text.contains('watermark')) {
      return 'Please confirm image rights first.';
    }
    if (error is UnsupportedImageFormatException ||
        error is ImageTooLargeException) {
      return text;
    }
    // Dio wraps the underlying cause in DioException.error rather than
    // throwing it directly, and DioException/AppException.toString() never
    // include the class name — so unwrap and type-check instead of
    // substring-matching, which never matched anything here.
    final cause = error is DioException ? (error.error ?? error) : error;
    if (cause is UnauthorizedException) {
      return 'Your session has expired. Please sign in again.';
    }
    if (cause is NetworkException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error is DioException &&
        (error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionTimeout)) {
      return 'This is taking longer than expected. Please try again.';
    }
    return 'AI edit failed. Please try another edit or use the original photo.';
  }
}

final aiEditorRepositoryProvider = Provider<AiEditorRepository>((ref) {
  return AiEditorRepository(
    service: ref.read(aiEditorServiceProvider),
    localProcessor: LocalImageProcessor(),
    uploadRepository: ref.read(uploadRepositoryProvider),
  );
});
