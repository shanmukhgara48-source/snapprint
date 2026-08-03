import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/features/ai_editor/domain/ai_editor_models.dart';
import 'package:snap_print/features/ai_editor/domain/editor_document.dart';

void main() {
  group('production editor contracts', () {
    test('parses capabilities and background-removal metadata', () {
      final capabilities = AiEditorCapabilities.fromJson(const {
        'enabled': true,
        'background_removal': true,
        'generative_editing': false,
        'model': 'BiRefNet_HR-matting',
        'max_source_bytes': 52428800,
        'max_source_pixels': 50000000,
      });
      final result = BackgroundRemovalResult.fromJson(const {
        'foreground_url': 'https://cdn.example.com/cutout.png',
        'width': 4000,
        'height': 3000,
        'subject_bounds': {
          'left': 0.1,
          'top': 0.05,
          'width': 0.8,
          'height': 0.9,
        },
        'model': 'BiRefNet_HR-matting',
        'processing_ms': 850,
        'warnings': <String>[],
      });

      expect(capabilities.backgroundRemoval, isTrue);
      expect(capabilities.model, 'BiRefNet_HR-matting');
      expect(result.width, 4000);
      expect(result.subjectBounds.height, 0.9);
    });

    test('round-trips a non-destructive editor document', () {
      const document = EditorDocument(
        sourceUrl: 'https://cdn.example.com/original.jpg',
        foregroundUrl: 'https://cdn.example.com/cutout.png',
        sourceWidth: 3000,
        sourceHeight: 2000,
        subjectBounds: NormalizedRect(
          left: 0.1,
          top: 0.1,
          width: 0.8,
          height: 0.8,
        ),
        background: EditorBackground(
          kind: EditorBackgroundKind.gradient,
          gradientStart: '#FFFFFF',
          gradientEnd: '#DDE7F2',
        ),
        adjustments: EditorAdjustments(
          exposure: 0.25,
          temperature: 0.1,
          sharpness: 0.4,
        ),
        transform: EditorTransform(
          crop: NormalizedRect(left: 0.05, top: 0.1, width: 0.9, height: 0.8),
          rotationQuarterTurns: 1,
          offsetX: 0.12,
          offsetY: -0.08,
        ),
      );

      final restored = EditorDocument.fromJson(document.toJson());
      expect(restored.workingImageUrl, document.foregroundUrl);
      expect(restored.background.kind, EditorBackgroundKind.gradient);
      expect(restored.adjustments.exposure, 0.25);
      expect(restored.transform.crop?.width, 0.9);
      expect(restored.transform.rotationQuarterTurns, 1);
      expect(restored.transform.offsetX, 0.12);
      expect(restored.transform.offsetY, -0.08);
    });
  });

  group('AiEditResult.fromJson', () {
    test('parses the full backend contract', () {
      final result = AiEditResult.fromJson(const {
        'edited_image_url': 'https://cdn.example.com/edited.jpg',
        'operation': 'background',
        'interaction_id': 'int-123',
        'summary': 'Replaced background with studio white.',
      });

      expect(result.editedImageUrl, 'https://cdn.example.com/edited.jpg');
      expect(result.operation, 'background');
      expect(result.interactionId, 'int-123');
      expect(result.summary, 'Replaced background with studio white.');
    });

    test('defaults optional fields when missing', () {
      final result = AiEditResult.fromJson(const {
        'edited_image_url': 'https://cdn.example.com/edited.jpg',
        'operation': 'enhance',
      });

      expect(result.interactionId, isNull);
      expect(result.summary, '');
    });
  });

  group('AiPrintAnalysis.fromJson', () {
    test('parses the full backend contract', () {
      final analysis = AiPrintAnalysis.fromJson(const {
        'score': 82,
        'resolution': '1200 x 1800 px',
        'dpi_estimate': '~300 DPI',
        'blur': 'Low',
        'noise': 'Low',
        'exposure': 'Good',
        'faces': '1 face detected',
        'crop_recommendation': 'Keep the subject centered.',
        'suggestions': ['Looks print-ready.'],
      });

      expect(analysis.score, 82);
      expect(analysis.resolution, '1200 x 1800 px');
      expect(analysis.dpiEstimate, '~300 DPI');
      expect(analysis.suggestions, ['Looks print-ready.']);
    });

    test('falls back to sane defaults for a missing/empty payload', () {
      final analysis = AiPrintAnalysis.fromJson(const {});

      expect(analysis.score, 0);
      expect(analysis.resolution, 'Unknown');
      expect(analysis.dpiEstimate, 'Unknown');
      expect(analysis.cropRecommendation, 'Keep faces centered.');
      expect(analysis.suggestions, isEmpty);
    });
  });
}
