import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_print/core/network/api_client.dart';
import 'package:snap_print/features/ai_editor/data/ai_editor_repository.dart';
import 'package:snap_print/features/ai_editor/data/ai_editor_service.dart';
import 'package:snap_print/features/ai_editor/data/local_image_processor.dart';
import 'package:snap_print/features/ai_editor/data/upload_repository.dart';
import 'package:snap_print/features/ai_editor/domain/ai_editor_models.dart';
import 'package:snap_print/features/ai_editor/domain/editor_operation.dart';
import 'package:snap_print/features/ai_editor/domain/local_image_metrics.dart';
import 'package:snap_print/features/ai_editor/presentation/screens/ai_photo_editor_screen.dart';

/// A repository double that never touches the network, so the screen's
/// initial load (status/analysis/local metrics) resolves deterministically
/// in a widget test instead of racing real HTTP calls.
class _FakeAiEditorRepository extends AiEditorRepository {
  _FakeAiEditorRepository()
    : super(
        service: AiEditorService(ApiClient()),
        localProcessor: LocalImageProcessor(),
        uploadRepository: UploadRepository(ApiClient()),
      );

  @override
  Future<bool> isEnabled() async => true;

  @override
  Future<AiEditorCapabilities> capabilities() async =>
      const AiEditorCapabilities(
        enabled: true,
        backgroundRemoval: true,
        generativeEditing: false,
        model: 'test-model',
        maxSourceBytes: 50000000,
        maxSourcePixels: 50000000,
      );

  @override
  Future<AiPrintAnalysis> analyze({
    required String imageUrl,
    required String productName,
    required String selectedSize,
  }) async => const AiPrintAnalysis(
    score: 90,
    resolution: '1200 x 1800 px',
    dpiEstimate: '~300 DPI',
    blur: 'Low',
    noise: 'Low',
    exposure: 'Good',
    faces: '1 face detected',
    cropRecommendation: 'Keep the subject centered.',
    suggestions: ['Looks print-ready.'],
  );

  @override
  Future<LocalImageMetrics> computeLocalMetrics(String imageUrl) async =>
      const LocalImageMetrics(
        width: 1200,
        height: 1800,
        fileSizeBytes: 2000000,
      );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const args = AiPhotoEditorArgs(
    imageUrl: 'https://example.com/original.jpg',
    productName: 'Photo Print',
    selectedSize: '4x6',
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size surfaceSize = const Size(800, 3000),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiEditorRepositoryProvider.overrideWithValue(
            _FakeAiEditorRepository(),
          ),
        ],
        child: const MaterialApp(home: AiPhotoEditorScreen(args: args)),
      ),
    );
    // Bounded pumps instead of pumpAndSettle: the processing-overlay spinner
    // and image shimmer placeholders animate on repeating tickers, so
    // settling would hang. A handful of short pumps drains the microtask
    // chain (_loadStatus/_analyze/_loadLocalMetrics) without waiting on
    // those tickers.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('renders the toolbar and analysis panel once data loads', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Photo Editor'), findsOneWidget);
    expect(find.text('Remove BG'), findsOneWidget);
    expect(find.text('Center'), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
    expect(find.text('Adjust'), findsOneWidget);
    expect(find.text('Use Photo'), findsOneWidget);
    expect(find.textContaining('~300 DPI'), findsOneWidget);
  });

  testWidgets('undo/redo are disabled with only the original in history', (
    tester,
  ) async {
    await pumpScreen(tester);

    final undoButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.undo_rounded),
    );
    final redoButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.redo_rounded),
    );
    expect(undoButton.onPressed, isNull);
    expect(redoButton.onPressed, isNull);
  });

  testWidgets('renders without overflow on a compact phone viewport', (
    tester,
  ) async {
    await pumpScreen(tester, surfaceSize: const Size(360, 640));

    expect(find.text('Photo Editor'), findsOneWidget);
    expect(find.text('Use Photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting Crop swaps the preview for the crop overlay', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Crop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Apply Crop'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
  });

  test('EditorTool.isServerDriven tags tools correctly', () {
    expect(EditorTool.crop.isServerDriven, isFalse);
    expect(EditorTool.transform.isServerDriven, isFalse);
    expect(EditorTool.adjust.isServerDriven, isFalse);
    expect(EditorTool.background.isServerDriven, isFalse);
    expect(EditorTool.magicEraser.isServerDriven, isTrue);
    expect(EditorTool.enhance.isServerDriven, isTrue);
    expect(EditorTool.none.isServerDriven, isFalse);
  });
}
