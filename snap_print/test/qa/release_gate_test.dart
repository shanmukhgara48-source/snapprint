import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_print/core/network/api_client.dart';
import 'package:snap_print/core/router/app_router.dart';
import 'package:snap_print/features/ai_editor/data/ai_editor_repository.dart';
import 'package:snap_print/features/ai_editor/data/ai_editor_service.dart';
import 'package:snap_print/features/ai_editor/data/local_image_processor.dart';
import 'package:snap_print/features/ai_editor/data/upload_repository.dart';
import 'package:snap_print/features/ai_editor/domain/ai_editor_models.dart';
import 'package:snap_print/features/ai_editor/domain/editor_document.dart';
import 'package:snap_print/features/ai_editor/domain/local_image_metrics.dart';
import 'package:snap_print/features/ai_editor/presentation/providers/ai_editor_provider.dart';
import 'package:snap_print/features/ai_editor/presentation/screens/ai_photo_editor_screen.dart';
import 'package:snap_print/features/customer/domain/entities/category_entity.dart';
import 'package:snap_print/features/customer/presentation/providers/catalog_provider.dart';
import 'package:snap_print/features/customer/presentation/widgets/category_grid.dart';

const _editorArgs = AiPhotoEditorArgs(
  imageUrl: 'https://example.com/original.jpg',
  productName: 'Premium Photo Print',
  selectedSize: '4x6',
);

const _mockCategories = [
  CategoryEntity(
    id: 'prints',
    name: 'Photo Prints',
    icon: 'image',
    imageUrl: '',
    sortOrder: 1,
  ),
  CategoryEntity(
    id: 'frames',
    name: 'Frames',
    icon: 'frame',
    imageUrl: '',
    sortOrder: 2,
  ),
  CategoryEntity(
    id: 'hidden',
    name: 'Hidden Category',
    icon: 'gift',
    imageUrl: '',
    sortOrder: 3,
    isActive: false,
  ),
];

class _ServerEditCall {
  const _ServerEditCall({required this.operation, required this.prompt});

  final String operation;
  final String prompt;
}

/// Deterministic test double for every remote or CPU-heavy editor dependency.
class _FakeAiEditorRepository extends AiEditorRepository {
  _FakeAiEditorRepository()
    : super(
        service: AiEditorService(ApiClient()),
        localProcessor: LocalImageProcessor(),
        uploadRepository: UploadRepository(ApiClient()),
      );

  final serverEdits = <_ServerEditCall>[];
  EditorDocument? exportedDocument;

  @override
  Future<AiEditorCapabilities> capabilities() async =>
      const AiEditorCapabilities(
        enabled: true,
        backgroundRemoval: true,
        generativeEditing: true,
        model: 'qa-fake-model',
        maxSourceBytes: 50 * 1024 * 1024,
        maxSourcePixels: 50 * 1000 * 1000,
      );

  @override
  Future<AiPrintAnalysis> analyze({
    required String imageUrl,
    required String productName,
    required String selectedSize,
  }) async => const AiPrintAnalysis(
    score: 96,
    resolution: '1200 x 1800 px',
    dpiEstimate: '300 DPI',
    blur: 'Low',
    noise: 'Low',
    exposure: 'Good',
    faces: '1 face detected',
    cropRecommendation: 'Keep the subject centered.',
    suggestions: ['Ready to print.'],
  );

  @override
  Future<LocalImageMetrics> computeLocalMetrics(String imageUrl) async =>
      const LocalImageMetrics(
        width: 1200,
        height: 1800,
        fileSizeBytes: 2 * 1024 * 1024,
      );

  @override
  Future<AiEditResult> editOnServer({
    required String imageUrl,
    required String operation,
    required String productName,
    required String selectedSize,
    String prompt = '',
    String? maskImageBase64,
    String? previousInteractionId,
    bool rightsConfirmed = false,
  }) async {
    serverEdits.add(_ServerEditCall(operation: operation, prompt: prompt));
    return AiEditResult(
      editedImageUrl: 'https://example.com/edited-${serverEdits.length}.png',
      operation: operation,
      interactionId: 'interaction-${serverEdits.length}',
      summary: 'Edit completed.',
    );
  }

  @override
  Future<AiExportResult> export({
    required EditorDocument document,
    required String selectedSize,
  }) async {
    exportedDocument = document;
    return const AiExportResult(
      imageUrl: 'https://example.com/print-ready.png',
      width: 1200,
      height: 1800,
      mimeType: 'image/png',
      fileSizeBytes: 2 * 1024 * 1024,
      dpiEstimate: 300,
      processingMs: 10,
      warnings: [],
    );
  }
}

Future<void> _pumpFor(
  WidgetTester tester, {
  int frames = 10,
  Duration duration = const Duration(milliseconds: 50),
}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(duration);
  }
}

Future<ProviderContainer> _pumpEditor(
  WidgetTester tester,
  _FakeAiEditorRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [aiEditorRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AiPhotoEditorScreen(args: _editorArgs)),
    ),
  );
  await _pumpFor(tester);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Smoke test', () {
    testWidgets('AI editor initializes, applies an edit, and exports it', (
      tester,
    ) async {
      // Arrange: boot the real editor UI with deterministic backend results.
      final repository = _FakeAiEditorRepository();
      final container = await _pumpEditor(tester, repository);

      expect(find.text('Photo Editor'), findsOneWidget);
      expect(find.text('Use Photo'), findsOneWidget);

      // Act: exercise the shortest customer-critical edit-to-export path.
      await tester.enterText(
        find.byType(TextField).first,
        'Make this black and white',
      );
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await _pumpFor(tester);

      final editedState = container.read(aiEditorProvider(_editorArgs));
      expect(editedState.document.adjustments.saturation, -1);
      expect(editedState.canUndo, isTrue);

      await tester.tap(find.text('Use Photo'));
      await _pumpFor(tester);
      await tester.tap(find.text('Export and use'));
      await _pumpFor(tester);

      // Assert: export receives the edited document, not the original.
      expect(repository.exportedDocument, isNotNull);
      expect(repository.exportedDocument!.adjustments.saturation, -1);
      expect(tester.takeException(), isNull);
    });
  });

  group('Sanity test: prompt-based AI editing', () {
    testWidgets('background prompt uses the correct server operation', (
      tester,
    ) async {
      // Arrange: enable generative editing through the repository fake.
      final repository = _FakeAiEditorRepository();
      final container = await _pumpEditor(tester, repository);

      // Act: submit the narrow feature prompt changed by the latest release.
      const prompt = 'Replace the sky with a dramatic sunset';
      await tester.enterText(find.byType(TextField).first, prompt);
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await _pumpFor(tester);

      // Assert: prompt classification, result state, and history all agree.
      expect(repository.serverEdits, hasLength(1));
      expect(repository.serverEdits.single.operation, 'background');
      expect(repository.serverEdits.single.prompt, prompt);

      var state = container.read(aiEditorProvider(_editorArgs));
      expect(state.currentUrl, 'https://example.com/edited-1.png');
      expect(state.lastInteractionId, 'interaction-1');
      expect(state.canUndo, isTrue);

      container.read(aiEditorProvider(_editorArgs).notifier).undo();
      state = container.read(aiEditorProvider(_editorArgs));
      expect(state.currentUrl, _editorArgs.imageUrl);
      expect(state.canRedo, isTrue);

      container.read(aiEditorProvider(_editorArgs).notifier).redo();
      expect(
        container.read(aiEditorProvider(_editorArgs)).currentUrl,
        'https://example.com/edited-1.png',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Basic regression test: Categories', () {
    testWidgets('active categories still render and navigate correctly', (
      tester,
    ) async {
      // Arrange: mirror the backend contract with active and inactive records.
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: CategoryGrid()),
          ),
          GoRoute(
            path: AppRoutes.productList,
            builder: (_, state) => Scaffold(
              body: Text('catalog:${state.pathParameters['category']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith((ref) async => _mockCategories),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: filtering cannot blank the section when active data exists.
      expect(find.text('Photo Prints'), findsOneWidget);
      expect(find.text('Frames'), findsOneWidget);
      expect(find.text('Hidden Category'), findsNothing);
      expect(find.text('No categories yet'), findsNothing);

      // Act and assert: a category still opens its encoded catalog route.
      await tester.tap(find.text('Photo Prints'));
      await tester.pumpAndSettle();
      expect(find.text('catalog:Photo Prints'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
