import 'dart:math' as math;

/// On-device print-readiness metrics computed directly from image bytes —
/// no network round trip. Mirrors the DPI formula in the backend's
/// `_estimate_dpi` (backend/app/services/ai_photo_editor.py) so local and
/// server estimates never disagree.
class LocalImageMetrics {
  const LocalImageMetrics({
    required this.width,
    required this.height,
    required this.fileSizeBytes,
  });

  final int width;
  final int height;
  final int fileSizeBytes;

  double get megapixels => (width * height) / 1000000;

  String get resolutionLabel =>
      width > 0 && height > 0 ? '$width x $height px' : 'Unknown';

  String get fileSizeLabel {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  /// Estimated print DPI for a size label like `"4x6"` or `"8x10 in"`.
  /// Returns null when [selectedSize] can't be parsed as WxH inches.
  int? dpiFor(String selectedSize) {
    if (width <= 0 || height <= 0) return null;
    final inches = _parseInches(selectedSize);
    if (inches == null) return null;
    final wIn = math.max(inches.$1, 0.1);
    final hIn = math.max(inches.$2, 0.1);
    return math.min(width / wIn, height / hIn).floor();
  }

  String dpiLabelFor(String selectedSize) {
    final dpi = dpiFor(selectedSize);
    if (dpi == null) return 'Select a size for DPI estimate';
    return '~$dpi DPI';
  }

  bool isLowResolutionFor(String selectedSize) {
    final dpi = dpiFor(selectedSize);
    return dpi != null && dpi < 300;
  }

  /// Largest size this image can print at the recommended 300 DPI.
  String get estimatedPrintSizeAt300Dpi {
    if (width <= 0 || height <= 0) return 'Unknown';
    final wIn = width / 300;
    final hIn = height / 300;
    return '${wIn.toStringAsFixed(1)} x ${hIn.toStringAsFixed(1)} in';
  }

  static (double, double)? _parseInches(String selectedSize) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*[x×]\s*(\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(selectedSize);
    if (match == null) return null;
    final w = double.tryParse(match.group(1)!);
    final h = double.tryParse(match.group(2)!);
    if (w == null || h == null) return null;
    return (w, h);
  }
}
