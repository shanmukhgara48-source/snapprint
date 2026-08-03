import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/features/ai_editor/domain/local_image_metrics.dart';

void main() {
  group('LocalImageMetrics.dpiFor', () {
    test('matches backend _estimate_dpi formula for a known case', () {
      // 1200x1800 px at "4x6" => min(1200/4, 1800/6) = min(300, 300) = 300
      const metrics = LocalImageMetrics(
        width: 1200,
        height: 1800,
        fileSizeBytes: 2000000,
      );
      expect(metrics.dpiFor('4x6'), 300);
      expect(metrics.dpiLabelFor('4x6'), '~300 DPI');
      expect(metrics.isLowResolutionFor('4x6'), isFalse);
    });

    test('parses size labels with an "in" suffix and surrounding text', () {
      const metrics = LocalImageMetrics(
        width: 2400,
        height: 3000,
        fileSizeBytes: 4000000,
      );
      // "8x10 in" => min(2400/8, 3000/10) = min(300, 300) = 300
      expect(metrics.dpiFor('8x10 in'), 300);
    });

    test('parses spaced and quoted catalog size labels', () {
      const metrics = LocalImageMetrics(
        width: 1200,
        height: 1800,
        fileSizeBytes: 2000000,
      );
      expect(metrics.dpiFor('4 x 6" glossy'), 300);
    });

    test('flags low resolution below 300 DPI', () {
      const metrics = LocalImageMetrics(
        width: 600,
        height: 900,
        fileSizeBytes: 500000,
      );
      // "4x6" => min(600/4, 900/6) = min(150, 150) = 150
      expect(metrics.dpiFor('4x6'), 150);
      expect(metrics.isLowResolutionFor('4x6'), isTrue);
    });

    test('returns null for an unparsable size label', () {
      const metrics = LocalImageMetrics(
        width: 1200,
        height: 1800,
        fileSizeBytes: 2000000,
      );
      expect(metrics.dpiFor('Standard'), isNull);
      expect(metrics.dpiLabelFor('Standard'), 'Select a size for DPI estimate');
      expect(metrics.isLowResolutionFor('Standard'), isFalse);
    });

    test('returns null when dimensions are unknown', () {
      const metrics = LocalImageMetrics(width: 0, height: 0, fileSizeBytes: 0);
      expect(metrics.dpiFor('4x6'), isNull);
      expect(metrics.resolutionLabel, 'Unknown');
    });
  });

  group('LocalImageMetrics labels', () {
    test('formats file size in B / KB / MB', () {
      expect(
        const LocalImageMetrics(
          width: 1,
          height: 1,
          fileSizeBytes: 500,
        ).fileSizeLabel,
        '500 B',
      );
      expect(
        const LocalImageMetrics(
          width: 1,
          height: 1,
          fileSizeBytes: 20 * 1024,
        ).fileSizeLabel,
        '20 KB',
      );
      expect(
        const LocalImageMetrics(
          width: 1,
          height: 1,
          fileSizeBytes: 5 * 1024 * 1024,
        ).fileSizeLabel,
        '5.0 MB',
      );
    });

    test('computes megapixels and the 300 DPI print size estimate', () {
      const metrics = LocalImageMetrics(
        width: 3000,
        height: 2000,
        fileSizeBytes: 1,
      );
      expect(metrics.megapixels, 6.0);
      expect(metrics.estimatedPrintSizeAt300Dpi, '10.0 x 6.7 in');
    });
  });
}
