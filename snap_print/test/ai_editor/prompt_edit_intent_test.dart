import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/features/ai_editor/domain/prompt_edit_intent.dart';

void main() {
  group('classifyPromptEdit', () {
    test('routes instant filters to local adjustments', () {
      final bw = classifyPromptEdit('Make this black and white');
      final cinematic = classifyPromptEdit('Make it cinematic');

      expect(bw.execution, PromptEditExecution.localAdjustment);
      expect(bw.operation, 'filter');
      expect(bw.localAdjustments?.saturation, -1);
      expect(cinematic.execution, PromptEditExecution.localAdjustment);
      expect(cinematic.localAdjustments?.contrast, greaterThan(0.0));
    });

    test(
      'routes background and object prompts to dedicated server operations',
      () {
        expect(
          classifyPromptEdit('Replace background with beach').operation,
          'background',
        );
        expect(
          classifyPromptEdit(
            'Replace the sky with a dramatic sunset',
          ).operation,
          'background',
        );
        expect(
          classifyPromptEdit('Remove people behind me').operation,
          'object_removal',
        );
      },
    );

    test('routes restoration, colorization, upscale, and style prompts', () {
      expect(
        classifyPromptEdit('Colorize this old photo').operation,
        'colorize',
      );
      expect(classifyPromptEdit('Fix scratches').operation, 'restore');
      expect(classifyPromptEdit('Upscale to 4K').operation, 'upscale');
      expect(classifyPromptEdit('Turn into anime').operation, 'filter');
    });

    test('uses generic prompt editing for unknown instructions', () {
      final intent = classifyPromptEdit('Make this feel like a family memory');

      expect(intent.execution, PromptEditExecution.server);
      expect(intent.operation, 'prompt');
    });
  });
}
