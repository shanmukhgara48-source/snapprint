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
  // Style Transfer
  'Make it anime style',
  'Oil painting effect',
  'Pencil sketch look',
  'Turn into 3D render',
  // Enhancement
  'Enhance photo quality',
  'Sharpen details',
  'Make it HDR',
  // Background
  'Remove background',
  'Studio background',
  'Beach background',
  // Portrait
  'Improve portrait',
  'Smooth skin naturally',
  // Scene
  'Golden hour lighting',
  'Make it sunset',
  'Add rain effect',
  // Object
  'Remove people in back',
  // Color & Lighting
  'Warm vintage tones',
  'Dramatic lighting',
  'Cinematic color grade',
  // Restore
  'Restore old photo',
  'Colorize this photo',
  // Fashion
  'Change to formal outfit',
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
  if (_containsAny(prompt, ['warm', 'warm tone', 'warmer'])) {
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
  if (_containsAny(prompt, ['cool', 'cool tone', 'cooler'])) {
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
  // --- Style transfer (artistic) ---
  if (_containsAny(prompt, [
    'anime',
    'pixar',
    'disney',
    'ghibli',
    'cartoon',
    'pencil sketch',
    'watercolor',
    'oil painting',
    'pop art',
    'comic book',
    'comic',
    'clay',
    'plasticine',
    'lego',
    'minecraft',
    'cyberpunk',
    'vaporwave',
    'steampunk',
    'art deco',
    'impressionist',
    'baroque',
    'surreal',
    '3d render',
    'low poly',
    'pixel art',
    'ukiyo-e',
    'art nouveau',
    'turn into',
    'in the style of',
    'style of',
  ])) {
    return const PromptEditIntent(
      operation: 'style_transfer',
      label: 'Style transfer',
      execution: PromptEditExecution.server,
    );
  }

  // --- Scene transformation ---
  if (_containsAny(prompt, [
    'day to night',
    'night to day',
    'make it night',
    'make it day',
    'change season',
    'change time',
    'sunset',
    'sunrise',
    'golden hour',
    'rainy',
    'rain effect',
    'snowy',
    'snow effect',
    'foggy',
    'fog',
    'underwater',
    'apocalyptic',
    'starry sky',
    'northern lights',
    'aurora',
    'christmas',
    'fireworks',
  ])) {
    return const PromptEditIntent(
      operation: 'scene_transform',
      label: 'Scene transform',
      execution: PromptEditExecution.server,
    );
  }

  // --- Fashion editing ---
  if (_containsAny(prompt, [
    'change outfit',
    'change clothes',
    'change clothing',
    'wearing',
    'formal outfit',
    'casual outfit',
    'suit',
    'dress',
    'hoodie',
    'jacket',
    'uniform',
    'costume',
    'swap outfit',
    'wedding dress',
    'traditional',
    'saree',
    'kurta',
  ])) {
    return const PromptEditIntent(
      operation: 'fashion_edit',
      label: 'Fashion edit',
      execution: PromptEditExecution.server,
    );
  }

  // --- Interior design ---
  if (_containsAny(prompt, [
    'redesign room',
    'redecorate',
    'change furniture',
    'living room',
    'bedroom',
    'kitchen',
    'bathroom',
    'minimalist room',
    'change wallpaper',
    'room makeover',
    'home design',
    'interior',
    'scandinavian',
    'industrial style',
    'bohemian',
  ])) {
    return const PromptEditIntent(
      operation: 'interior_design',
      label: 'Interior design',
      execution: PromptEditExecution.server,
    );
  }

  // --- Text & graphic overlay ---
  if (_containsAny(prompt, [
    'add text',
    'write text',
    'put text',
    'overlay text',
    'add logo',
    'caption',
    'title',
    'label',
    'add watermark',
    'add stamp',
    'typography',
    'lettering',
  ])) {
    return const PromptEditIntent(
      operation: 'text_graphic',
      label: 'Text overlay',
      execution: PromptEditExecution.server,
    );
  }

  // --- Color & lighting (server-side advanced) ---
  if (_containsAny(prompt, [
    'color grade',
    'color grading',
    'warm tone',
    'cool tone',
    'dramatic lighting',
    'neon',
    'moody',
    'film grain',
    'desaturate',
    'cross process',
    'split toning',
    'teal and orange',
    'cinematic color',
    'noir',
    'bleach bypass',
  ])) {
    return const PromptEditIntent(
      operation: 'color_lighting',
      label: 'Color & lighting',
      execution: PromptEditExecution.server,
    );
  }

  // --- Multi-image ---
  if (_containsAny(prompt, [
    'combine',
    'merge',
    'collage',
    'side by side',
    'blend images',
    'composite',
    'double exposure',
  ])) {
    return const PromptEditIntent(
      operation: 'multi_image',
      label: 'Multi-image',
      execution: PromptEditExecution.server,
    );
  }

  // --- Photo enhancement (server) ---
  if (_containsAny(prompt, [
    'upscale',
    '4k',
    'super resolution',
    'increase quality',
    'sharpen',
    'deblur',
    'denoise',
    'noise removal',
    'noise reduction',
    'clarity',
    'detail enhancement',
  ])) {
    return const PromptEditIntent(
      operation: 'photo_enhance',
      label: 'Photo enhancement',
      execution: PromptEditExecution.server,
    );
  }

  // --- Colorize ---
  if (_containsAny(prompt, ['colorize', 'colourize'])) {
    return const PromptEditIntent(
      operation: 'colorize',
      label: 'Colorize',
      execution: PromptEditExecution.server,
    );
  }

  // --- Restore ---
  if (_containsAny(prompt, [
    'restore',
    'scratch',
    'scratches',
    'faded',
    'torn',
    'old photo',
    'repair',
    'damaged',
    'cracked',
  ])) {
    return const PromptEditIntent(
      operation: 'restore',
      label: 'Restore photo',
      execution: PromptEditExecution.server,
    );
  }

  // --- Portrait editing ---
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
    'skin',
    'complexion',
    'makeup',
    'younger',
    'older',
    'beard',
    'glasses',
    'freckles',
  ])) {
    return const PromptEditIntent(
      operation: 'portrait',
      label: 'Portrait edit',
      execution: PromptEditExecution.server,
    );
  }

  // --- Legacy local filter catch ---
  if (_containsAny(prompt, ['summer', 'rain', 'snow'])) {
    return const PromptEditIntent(
      operation: 'scene_transform',
      label: 'Scene transform',
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
