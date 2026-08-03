import 'editor_document.dart';

class AiEditorCapabilities {
  const AiEditorCapabilities({
    required this.enabled,
    required this.backgroundRemoval,
    required this.generativeEditing,
    required this.model,
    required this.maxSourceBytes,
    required this.maxSourcePixels,
  });

  final bool enabled;
  final bool backgroundRemoval;
  final bool generativeEditing;
  final String model;
  final int maxSourceBytes;
  final int maxSourcePixels;

  factory AiEditorCapabilities.fromJson(Map<String, dynamic> json) =>
      AiEditorCapabilities(
        enabled: json['enabled'] == true,
        backgroundRemoval: json['background_removal'] == true,
        generativeEditing: json['generative_editing'] == true,
        model: json['model'] as String? ?? 'Not configured',
        maxSourceBytes: (json['max_source_bytes'] as num?)?.toInt() ?? 0,
        maxSourcePixels: (json['max_source_pixels'] as num?)?.toInt() ?? 0,
      );
}

class BackgroundRemovalResult {
  const BackgroundRemovalResult({
    required this.foregroundUrl,
    required this.width,
    required this.height,
    required this.subjectBounds,
    required this.model,
    required this.processingMs,
    required this.warnings,
  });

  final String foregroundUrl;
  final int width;
  final int height;
  final NormalizedRect subjectBounds;
  final String model;
  final int processingMs;
  final List<String> warnings;

  factory BackgroundRemovalResult.fromJson(Map<String, dynamic> json) =>
      BackgroundRemovalResult(
        foregroundUrl: json['foreground_url'] as String,
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
        subjectBounds: NormalizedRect.fromJson(
          json['subject_bounds'] as Map<String, dynamic>,
        ),
        model: json['model'] as String? ?? '',
        processingMs: (json['processing_ms'] as num?)?.toInt() ?? 0,
        warnings: (json['warnings'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList(),
      );
}

class AiExportResult {
  const AiExportResult({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.processingMs,
    required this.warnings,
    this.dpiEstimate,
  });

  final String imageUrl;
  final int width;
  final int height;
  final String mimeType;
  final int fileSizeBytes;
  final int? dpiEstimate;
  final int processingMs;
  final List<String> warnings;

  factory AiExportResult.fromJson(Map<String, dynamic> json) => AiExportResult(
    imageUrl: json['image_url'] as String,
    width: (json['width'] as num).toInt(),
    height: (json['height'] as num).toInt(),
    mimeType: json['mime_type'] as String,
    fileSizeBytes: (json['file_size_bytes'] as num).toInt(),
    dpiEstimate: (json['dpi_estimate'] as num?)?.toInt(),
    processingMs: (json['processing_ms'] as num?)?.toInt() ?? 0,
    warnings: (json['warnings'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList(),
  );
}

class AiEditResult {
  const AiEditResult({
    required this.editedImageUrl,
    required this.operation,
    this.interactionId,
    this.summary = '',
  });

  final String editedImageUrl;
  final String operation;
  final String? interactionId;
  final String summary;

  factory AiEditResult.fromJson(Map<String, dynamic> json) => AiEditResult(
    editedImageUrl: json['edited_image_url'] as String,
    operation: json['operation'] as String,
    interactionId: json['interaction_id'] as String?,
    summary: json['summary'] as String? ?? '',
  );
}

class AiPrintAnalysis {
  const AiPrintAnalysis({
    required this.score,
    required this.resolution,
    required this.dpiEstimate,
    required this.blur,
    required this.noise,
    required this.exposure,
    required this.faces,
    required this.cropRecommendation,
    required this.suggestions,
  });

  final int score;
  final String resolution;
  final String dpiEstimate;
  final String blur;
  final String noise;
  final String exposure;
  final String faces;
  final String cropRecommendation;
  final List<String> suggestions;

  factory AiPrintAnalysis.fromJson(Map<String, dynamic> json) =>
      AiPrintAnalysis(
        score: json['score'] as int? ?? 0,
        resolution: json['resolution'] as String? ?? 'Unknown',
        dpiEstimate: json['dpi_estimate'] as String? ?? 'Unknown',
        blur: json['blur'] as String? ?? 'Unknown',
        noise: json['noise'] as String? ?? 'Unknown',
        exposure: json['exposure'] as String? ?? 'Unknown',
        faces: json['faces'] as String? ?? 'Unknown',
        cropRecommendation:
            json['crop_recommendation'] as String? ?? 'Keep faces centered.',
        suggestions: (json['suggestions'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
      );
}
