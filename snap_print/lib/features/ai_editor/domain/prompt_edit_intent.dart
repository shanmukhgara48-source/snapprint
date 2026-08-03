import 'editor_document.dart';

enum PromptEditExecution {
  localAdjustment,
  localTransform,
  backgroundRemoval,
  server,
}

class PromptEditIntent {
  const PromptEditIntent({
    required this.operation,
    required this.label,
    required this.execution,
    this.localAdjustments,
  });

  final String operation;
  final String label;
  final PromptEditExecution execution;
  final EditorAdjustments? localAdjustments;

  bool get usesGenerativeModel => execution == PromptEditExecution.server;
}

const promptEditSuggestions = <String>[
  'Make this black and white',
  'Colorize this old photo',
  'Turn this into anime',
  'Make it cinematic',
  'Remove the background',
  'Replace background with beach',
  'Upscale to 4K',
  'Restore old photo',
  'Blur background',
  'Make it look professional',
];

PromptEditIntent classifyPromptEdit(String rawPrompt) {
  final prompt = _normalize(rawPrompt);

  // Explicit edit commands take precedence over descriptive style words.
  // For example, "replace the sky with a dramatic sunset" is a background
  // replacement, not merely a local warm/cinematic filter.
  if (_containsAny(prompt, [
    'remove background',
    'remove the background',
    'transparent background',
    'make the background transparent',
    'cut out',
    'cutout',
  ])) {
    return const PromptEditIntent(
      operation: 'background_removal',
      label: 'Remove background',
      execution: PromptEditExecution.backgroundRemoval,
    );
  }
  if (_containsAny(prompt, [
    'replace background',
    'replace the background',
    'change background',
    'change the background',
    'blur background',
    'replace the sky',
    'change the sky',
    'sky with',
    'blue sky',
    'beach',
    'mountain',
    'forest',
    'office',
    'cafe',
    'space',
    'moon',
  ])) {
    return const PromptEditIntent(
      operation: 'background',
      label: 'Background edit',
      execution: PromptEditExecution.server,
    );
  }
  if (_containsAny(prompt, [
    'remove people',
    'remove person',
    'remove object',
    'remove objects',
    'remove chair',
    'remove the chair',
    'remove wire',
    'remove wires',
    'photobomber',
    'remove text',
    'remove shadow',
    'remove shadows',
    'watermark',
  ])) {
    return const PromptEditIntent(
      operation: 'object_removal',
      label: 'Object removal',
      execution: PromptEditExecution.server,
    );
  }

  if (_containsAny(prompt, [
    'black and white',
    'black & white',
    'grayscale',
    'grey scale',
    'monochrome',
  ])) {
    return const PromptEditIntent(
      operation: 'filter',
      label: 'Black and white',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(saturation: -1, contrast: 0.08),
    );
  }
  if (_containsAny(prompt, ['sepia', 'vintage 90s', 'vintage'])) {
    return const PromptEditIntent(
      operation: 'filter',
      label: 'Vintage',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(
        saturation: -0.28,
        contrast: 0.12,
        temperature: 0.55,
        highlights: -0.08,
      ),
    );
  }
  if (_containsAny(prompt, ['warm', 'golden hour', 'sunset'])) {
    return const PromptEditIntent(
      operation: 'filter',
      label: 'Warm tone',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(
        temperature: 0.42,
        vibrance: 0.18,
        contrast: 0.08,
      ),
    );
  }
  if (_containsAny(prompt, ['cool', 'winter'])) {
    return const PromptEditIntent(
      operation: 'filter',
      label: 'Cool tone',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(
        temperature: -0.38,
        contrast: 0.05,
        saturation: -0.05,
      ),
    );
  }
  if (_containsAny(prompt, [
    'vibrant',
    'hdr',
    'increase contrast',
    'increase saturation',
  ])) {
    return const PromptEditIntent(
      operation: 'enhance',
      label: 'Vibrant HDR',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(
        contrast: 0.18,
        saturation: 0.18,
        vibrance: 0.26,
        highlights: -0.1,
        shadows: 0.12,
      ),
    );
  }
  if (_containsAny(prompt, ['increase brightness', 'brighter', 'brighten'])) {
    return const PromptEditIntent(
      operation: 'enhance',
      label: 'Brighten',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(brightness: 0.16, exposure: 0.12),
    );
  }
  if (_containsAny(prompt, ['matte', 'film', 'soft'])) {
    return const PromptEditIntent(
      operation: 'filter',
      label: 'Matte film',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(
        contrast: -0.08,
        saturation: -0.08,
        highlights: -0.12,
        shadows: 0.18,
      ),
    );
  }
  if (_containsAny(prompt, ['dramatic', 'cinematic'])) {
    return const PromptEditIntent(
      operation: 'filter',
      label: 'Cinematic',
      execution: PromptEditExecution.localAdjustment,
      localAdjustments: EditorAdjustments(
        contrast: 0.22,
        saturation: 0.04,
        temperature: -0.08,
        highlights: -0.16,
        shadows: -0.1,
      ),
    );
  }
  if (_containsAny(prompt, ['rotate'])) {
    return const PromptEditIntent(
      operation: 'rotate',
      label: 'Rotate',
      execution: PromptEditExecution.localTransform,
    );
  }
  if (_containsAny(prompt, ['flip'])) {
    return const PromptEditIntent(
      operation: 'flip',
      label: 'Flip',
      execution: PromptEditExecution.localTransform,
    );
  }
  if (_containsAny(prompt, [
    'upscale',
    '4k',
    'super resolution',
    'increase quality',
    'sharpen',
    'deblur',
    'denoise',
    'noise removal',
  ])) {
    return const PromptEditIntent(
      operation: 'upscale',
      label: 'Print upscale',
      execution: PromptEditExecution.server,
    );
  }
  if (_containsAny(prompt, ['colorize', 'colourize'])) {
    return const PromptEditIntent(
      operation: 'colorize',
      label: 'Colorize',
      execution: PromptEditExecution.server,
    );
  }
  if (_containsAny(prompt, [
    'restore',
    'scratch',
    'scratches',
    'faded',
    'torn',
    'old photo',
    'repair',
  ])) {
    return const PromptEditIntent(
      operation: 'restore',
      label: 'Restore photo',
      execution: PromptEditExecution.server,
    );
  }
  if (_containsAny(prompt, [
    'face',
    'smile',
    'acne',
    'wrinkle',
    'teeth',
    'eye',
    'hair',
    'professional portrait',
    'portrait mode',
  ])) {
    return const PromptEditIntent(
      operation: 'portrait',
      label: 'Portrait edit',
      execution: PromptEditExecution.server,
    );
  }
  if (_containsAny(prompt, [
    'anime',
    'pixar',
    'disney',
    'ghibli',
    'cartoon',
    'pencil',
    'sketch',
    'watercolor',
    'oil painting',
    'pop art',
    'comic',
    'clay',
    'lego',
    'minecraft',
    'cyberpunk',
    'vaporwave',
    'christmas',
    'rain',
    'snow',
    'summer',
    'fireworks',
  ])) {
    return const PromptEditIntent(
      operation: 'filter',
      label: 'AI style',
      execution: PromptEditExecution.server,
    );
  }

  return const PromptEditIntent(
    operation: 'prompt',
    label: 'Custom AI edit',
    execution: PromptEditExecution.server,
  );
}

String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

bool _containsAny(String prompt, List<String> needles) {
  for (final needle in needles) {
    final escaped = RegExp.escape(needle);
    if (RegExp('(?:^|[^a-z0-9])$escaped(?:\$|[^a-z0-9])').hasMatch(prompt)) {
      return true;
    }
  }
  return false;
}
