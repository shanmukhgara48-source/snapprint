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
      expect(classifyPromptEdit('Upscale to 4K').operation, 'photo_enhance');
      expect(classifyPromptEdit('Turn into anime').operation, 'style_transfer');
    });

    test('routes extended 12-category operations correctly', () {
      expect(
        classifyPromptEdit('Oil painting effect').operation,
        'style_transfer',
      );
      expect(
        classifyPromptEdit('Make it sunset').operation,
        'scene_transform',
      );
      expect(
        classifyPromptEdit('Change outfit to suit').operation,
        'fashion_edit',
      );
      expect(
        classifyPromptEdit('Redesign room modern').operation,
        'interior_design',
      );
      expect(
        classifyPromptEdit('Add text overlay').operation,
        'text_graphic',
      );
      expect(
        classifyPromptEdit('Apply teal and orange color grading').operation,
        'color_lighting',
      );
      expect(
        classifyPromptEdit('Double exposure effect').operation,
        'multi_image',
      );
      expect(
        classifyPromptEdit('Sharpen and denoise').operation,
        'photo_enhance',
      );
    });

    test('uses generic prompt editing for unknown instructions', () {
      final intent = classifyPromptEdit('Make this feel like a family memory');

      expect(intent.execution, PromptEditExecution.server);
      expect(intent.operation, 'prompt');
    });
  });
}
