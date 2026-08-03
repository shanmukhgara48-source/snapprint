enum EditorBackgroundKind { transparent, solid, gradient, image }

class NormalizedRect {
  const NormalizedRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  static const full = NormalizedRect(left: 0, top: 0, width: 1, height: 1);

  final double left;
  final double top;
  final double width;
  final double height;

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };

  factory NormalizedRect.fromJson(Map<String, dynamic> json) => NormalizedRect(
    left: (json['left'] as num?)?.toDouble() ?? 0,
    top: (json['top'] as num?)?.toDouble() ?? 0,
    width: (json['width'] as num?)?.toDouble() ?? 1,
    height: (json['height'] as num?)?.toDouble() ?? 1,
  );
}

class EditorAdjustments {
  const EditorAdjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.temperature = 0,
    this.tint = 0,
    this.vibrance = 0,
    this.exposure = 0,
    this.highlights = 0,
    this.shadows = 0,
    this.sharpness = 0,
  });

  final double brightness;
  final double contrast;
  final double saturation;
  final double temperature;
  final double tint;
  final double vibrance;
  final double exposure;
  final double highlights;
  final double shadows;
  final double sharpness;

  bool get isIdentity =>
      brightness == 0 &&
      contrast == 0 &&
      saturation == 0 &&
      temperature == 0 &&
      tint == 0 &&
      vibrance == 0 &&
      exposure == 0 &&
      highlights == 0 &&
      shadows == 0 &&
      sharpness == 0;

  EditorAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? temperature,
    double? tint,
    double? vibrance,
    double? exposure,
    double? highlights,
    double? shadows,
    double? sharpness,
  }) => EditorAdjustments(
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    temperature: temperature ?? this.temperature,
    tint: tint ?? this.tint,
    vibrance: vibrance ?? this.vibrance,
    exposure: exposure ?? this.exposure,
    highlights: highlights ?? this.highlights,
    shadows: shadows ?? this.shadows,
    sharpness: sharpness ?? this.sharpness,
  );

  Map<String, dynamic> toJson() => {
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'temperature': temperature,
    'tint': tint,
    'vibrance': vibrance,
    'exposure': exposure,
    'highlights': highlights,
    'shadows': shadows,
    'sharpness': sharpness,
  };

  factory EditorAdjustments.fromJson(Map<String, dynamic> json) =>
      EditorAdjustments(
        brightness: (json['brightness'] as num?)?.toDouble() ?? 0,
        contrast: (json['contrast'] as num?)?.toDouble() ?? 0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 0,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
        tint: (json['tint'] as num?)?.toDouble() ?? 0,
        vibrance: (json['vibrance'] as num?)?.toDouble() ?? 0,
        exposure: (json['exposure'] as num?)?.toDouble() ?? 0,
        highlights: (json['highlights'] as num?)?.toDouble() ?? 0,
        shadows: (json['shadows'] as num?)?.toDouble() ?? 0,
        sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0,
      );
}

class EditorTransform {
  const EditorTransform({
    this.crop,
    this.rotationQuarterTurns = 0,
    this.straightenDegrees = 0,
    this.offsetX = 0,
    this.offsetY = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  final NormalizedRect? crop;
  final int rotationQuarterTurns;
  final double straightenDegrees;
  final double offsetX;
  final double offsetY;
  final bool flipHorizontal;
  final bool flipVertical;

  bool get isIdentity =>
      crop == null &&
      rotationQuarterTurns == 0 &&
      straightenDegrees == 0 &&
      offsetX == 0 &&
      offsetY == 0 &&
      !flipHorizontal &&
      !flipVertical;

  EditorTransform copyWith({
    NormalizedRect? Function()? crop,
    int? rotationQuarterTurns,
    double? straightenDegrees,
    double? offsetX,
    double? offsetY,
    bool? flipHorizontal,
    bool? flipVertical,
  }) => EditorTransform(
    crop: crop != null ? crop() : this.crop,
    rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
    straightenDegrees: straightenDegrees ?? this.straightenDegrees,
    offsetX: offsetX ?? this.offsetX,
    offsetY: offsetY ?? this.offsetY,
    flipHorizontal: flipHorizontal ?? this.flipHorizontal,
    flipVertical: flipVertical ?? this.flipVertical,
  );

  Map<String, dynamic> toJson() => {
    'crop': crop?.toJson(),
    'rotation_quarter_turns': rotationQuarterTurns,
    'straighten_degrees': straightenDegrees,
    'offset_x': offsetX,
    'offset_y': offsetY,
    'flip_horizontal': flipHorizontal,
    'flip_vertical': flipVertical,
  };

  factory EditorTransform.fromJson(Map<String, dynamic> json) =>
      EditorTransform(
        crop: json['crop'] is Map<String, dynamic>
            ? NormalizedRect.fromJson(json['crop'] as Map<String, dynamic>)
            : null,
        rotationQuarterTurns:
            (json['rotation_quarter_turns'] as num?)?.toInt() ?? 0,
        straightenDegrees:
            (json['straighten_degrees'] as num?)?.toDouble() ?? 0,
        offsetX: (json['offset_x'] as num?)?.toDouble() ?? 0,
        offsetY: (json['offset_y'] as num?)?.toDouble() ?? 0,
        flipHorizontal: json['flip_horizontal'] == true,
        flipVertical: json['flip_vertical'] == true,
      );
}

class EditorBackground {
  const EditorBackground({
    this.kind = EditorBackgroundKind.transparent,
    this.color = '#FFFFFF',
    this.gradientStart = '#FFFFFF',
    this.gradientEnd = '#DDE7F2',
    this.imageUrl,
  });

  final EditorBackgroundKind kind;
  final String color;
  final String gradientStart;
  final String gradientEnd;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'color': color,
    'gradient_start': gradientStart,
    'gradient_end': gradientEnd,
    'image_url': imageUrl,
  };

  factory EditorBackground.fromJson(Map<String, dynamic> json) =>
      EditorBackground(
        kind: EditorBackgroundKind.values.firstWhere(
          (value) => value.name == json['kind'],
          orElse: () => EditorBackgroundKind.transparent,
        ),
        color: json['color'] as String? ?? '#FFFFFF',
        gradientStart: json['gradient_start'] as String? ?? '#FFFFFF',
        gradientEnd: json['gradient_end'] as String? ?? '#DDE7F2',
        imageUrl: json['image_url'] as String?,
      );
}

class EditorDocument {
  const EditorDocument({
    required this.sourceUrl,
    this.foregroundUrl,
    this.sourceWidth,
    this.sourceHeight,
    this.subjectBounds,
    this.background = const EditorBackground(),
    this.adjustments = const EditorAdjustments(),
    this.transform = const EditorTransform(),
  });

  final String sourceUrl;
  final String? foregroundUrl;
  final int? sourceWidth;
  final int? sourceHeight;
  final NormalizedRect? subjectBounds;
  final EditorBackground background;
  final EditorAdjustments adjustments;
  final EditorTransform transform;

  String get workingImageUrl => foregroundUrl ?? sourceUrl;
  bool get hasCutout => foregroundUrl != null;
  bool get isOriginal =>
      !hasCutout &&
      background.kind == EditorBackgroundKind.transparent &&
      adjustments.isIdentity &&
      transform.isIdentity;

  EditorDocument copyWith({
    String? foregroundUrl,
    int? sourceWidth,
    int? sourceHeight,
    NormalizedRect? subjectBounds,
    EditorBackground? background,
    EditorAdjustments? adjustments,
    EditorTransform? transform,
  }) => EditorDocument(
    sourceUrl: sourceUrl,
    foregroundUrl: foregroundUrl ?? this.foregroundUrl,
    sourceWidth: sourceWidth ?? this.sourceWidth,
    sourceHeight: sourceHeight ?? this.sourceHeight,
    subjectBounds: subjectBounds ?? this.subjectBounds,
    background: background ?? this.background,
    adjustments: adjustments ?? this.adjustments,
    transform: transform ?? this.transform,
  );

  Map<String, dynamic> toJson() => {
    'source_url': sourceUrl,
    'foreground_url': foregroundUrl,
    'source_width': sourceWidth,
    'source_height': sourceHeight,
    'subject_bounds': subjectBounds?.toJson(),
    'background': background.toJson(),
    'adjustments': adjustments.toJson(),
    'transform': transform.toJson(),
  };

  factory EditorDocument.fromJson(Map<String, dynamic> json) => EditorDocument(
    sourceUrl: json['source_url'] as String,
    foregroundUrl: json['foreground_url'] as String?,
    sourceWidth: (json['source_width'] as num?)?.toInt(),
    sourceHeight: (json['source_height'] as num?)?.toInt(),
    subjectBounds: json['subject_bounds'] is Map<String, dynamic>
        ? NormalizedRect.fromJson(
            json['subject_bounds'] as Map<String, dynamic>,
          )
        : null,
    background: EditorBackground.fromJson(
      json['background'] as Map<String, dynamic>? ?? const {},
    ),
    adjustments: EditorAdjustments.fromJson(
      json['adjustments'] as Map<String, dynamic>? ?? const {},
    ),
    transform: EditorTransform.fromJson(
      json['transform'] as Map<String, dynamic>? ?? const {},
    ),
  );
}
