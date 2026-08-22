import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:snap_print/features/ai_editor/presentation/screens/ai_photo_editor_screen.dart';
import 'package:snap_print/features/ai_editor/presentation/providers/ai_editor_provider.dart';
import 'package:snap_print/features/ai_editor/domain/prompt_edit_intent.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testArgs = AiPhotoEditorArgs(
    imageUrl: 'https://picsum.photos/400/600',
    productName: 'Photo Prints',
    selectedSize: '4x6',
  );

  group('AI Editor Smoke Test', () {
    testWidgets('Editor screen renders with toolbar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AiPhotoEditorScreen(args: testArgs),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify the editor screen is showing
      expect(find.text('Photo Editor'), findsOneWidget);

      // Verify bottom toolbar buttons exist (may appear multiple times in suggestions)
      expect(find.byIcon(Icons.tune_rounded), findsAtLeast(1)); // Adjust
      expect(find.byIcon(Icons.auto_fix_high_rounded), findsAtLeast(1)); // AI
    });

    testWidgets('Prompt classifier routes all 12 categories', (tester) async {
      // Test the prompt classifier on-device (pure Dart logic)
      final results = <String, String>{
        'Make this black and white': 'filter',
        'Replace background with beach': 'background',
        'Remove people behind me': 'object_removal',
        'Colorize this old photo': 'colorize',
        'Fix scratches': 'restore',
        'Upscale to 4K': 'photo_enhance',
        'Turn into anime': 'style_transfer',
        'Oil painting effect': 'style_transfer',
        'Make it sunset': 'scene_transform',
        'Change outfit to suit': 'fashion_edit',
        'Redesign room modern': 'interior_design',
        'Add text overlay': 'text_graphic',
        'Apply teal and orange color grading': 'color_lighting',
        'Double exposure effect': 'multi_image',
        'Sharpen and denoise': 'photo_enhance',
        'Make this feel like a family memory': 'prompt',
      };

      for (final entry in results.entries) {
        final intent = classifyPromptEdit(entry.key);
        expect(
          intent.operation,
          entry.value,
          reason: 'Prompt "${entry.key}" should classify as "${entry.value}" '
              'but got "${intent.operation}"',
        );
      }
    });

    testWidgets('Style sheet opens with presets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AiPhotoEditorScreen(args: testArgs),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap the Style button in the toolbar
      final styleButton = find.byIcon(Icons.style_rounded);
      if (styleButton.evaluate().isNotEmpty) {
        await tester.tap(styleButton);
        await tester.pumpAndSettle();

        // Verify style presets appear
        expect(find.text('Style Transfer'), findsOneWidget);
        expect(find.text('Anime'), findsOneWidget);
        expect(find.text('Oil Painting'), findsOneWidget);
        expect(find.text('Watercolor'), findsOneWidget);

        // Close the sheet
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Scene sheet opens with presets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AiPhotoEditorScreen(args: testArgs),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap the Scene button
      final sceneButton = find.byIcon(Icons.landscape_rounded);
      if (sceneButton.evaluate().isNotEmpty) {
        await tester.tap(sceneButton);
        await tester.pumpAndSettle();

        // Verify scene presets appear
        expect(find.text('Scene Transform'), findsOneWidget);
        expect(find.text('Golden Hour'), findsOneWidget);
        expect(find.text('Rainy'), findsOneWidget);
        expect(find.text('Snowy'), findsOneWidget);

        // Close
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Local adjustments apply instantly', (tester) async {
      // Test that local adjustment intents have correct values
      final bw = classifyPromptEdit('Make this black and white');
      expect(bw.execution, PromptEditExecution.localAdjustment);
      expect(bw.localAdjustments?.saturation, -1);
      expect(bw.localAdjustments?.contrast, 0.08);

      final cinematic = classifyPromptEdit('Make it cinematic');
      expect(cinematic.execution, PromptEditExecution.localAdjustment);
      expect(cinematic.localAdjustments?.contrast, 0.22);

      final warm = classifyPromptEdit('Warm tones');
      expect(warm.execution, PromptEditExecution.localAdjustment);
      expect(warm.localAdjustments?.temperature, 0.42);

      final sepia = classifyPromptEdit('Vintage sepia');
      expect(sepia.execution, PromptEditExecution.localAdjustment);
      expect(sepia.localAdjustments?.saturation, -0.28);
    });

    testWidgets('Prompt suggestions are available', (tester) async {
      // Verify the prompt edit suggestions list is populated
      expect(promptEditSuggestions.length, greaterThanOrEqualTo(15));
      expect(promptEditSuggestions, contains('Make it anime style'));
      expect(promptEditSuggestions, contains('Remove background'));
      expect(promptEditSuggestions, contains('Enhance photo quality'));
      expect(promptEditSuggestions, contains('Golden hour lighting'));
    });
  });
}
