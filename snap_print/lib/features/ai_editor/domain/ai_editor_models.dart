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
