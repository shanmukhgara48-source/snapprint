import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/premium_network_image.dart';
import '../../domain/editor_document.dart';

class EditorCanvas extends StatelessWidget {
  const EditorCanvas({
    super.key,
    required this.document,
    this.previewAdjustments,
    this.previewStraighten,
    this.showOriginal = false,
  });

  final EditorDocument document;
  final EditorAdjustments? previewAdjustments;
  final double? previewStraighten;
  final bool showOriginal;

  @override
  Widget build(BuildContext context) {
    final effective = showOriginal
        ? EditorDocument(
            sourceUrl: document.sourceUrl,
            sourceWidth: document.sourceWidth,
            sourceHeight: document.sourceHeight,
            transform: document.transform,
          )
        : document;
    final adjustments = previewAdjustments ?? effective.adjustments;
    final transform = effective.transform.copyWith(
      straightenDegrees: previewStraighten,
    );
    final sourceAspect =
        (effective.sourceWidth ?? 1) / math.max(1, effective.sourceHeight ?? 1);
    final crop = transform.crop;
    var outputAspect = crop == null
        ? sourceAspect
        : sourceAspect * crop.width / crop.height;
    if (transform.rotationQuarterTurns.isOdd) outputAspect = 1 / outputAspect;

    return ColoredBox(
      color: const Color(0xFF191919),
      child: Center(
        child: AspectRatio(
          aspectRatio: outputAspect.isFinite ? outputAspect : 1,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BackgroundLayer(background: effective.background),
                _TransformedImage(
                  imageUrl: effective.workingImageUrl,
                  adjustments: adjustments,
                  transform: transform,
                  sourceAspect: sourceAspect,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.background});
  final EditorBackground background;

  @override
  Widget build(BuildContext context) {
    return switch (background.kind) {
      EditorBackgroundKind.transparent => const CustomPaint(
        painter: _CheckerboardPainter(),
      ),
      EditorBackgroundKind.solid => ColoredBox(
        color: _colorFromHex(background.color),
      ),
      EditorBackgroundKind.gradient => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _colorFromHex(background.gradientStart),
              _colorFromHex(background.gradientEnd),
            ],
          ),
        ),
      ),
      EditorBackgroundKind.image =>
        background.imageUrl == null
            ? const ColoredBox(color: Colors.white)
            : PremiumNetworkImage(
                imageUrl: background.imageUrl!,
                fit: BoxFit.cover,
                cacheWidth: 1400,
              ),
    };
  }
}

class _TransformedImage extends StatelessWidget {
  const _TransformedImage({
    required this.imageUrl,
    required this.adjustments,
    required this.transform,
    required this.sourceAspect,
  });

  final String imageUrl;
  final EditorAdjustments adjustments;
  final EditorTransform transform;
  final double sourceAspect;

  @override
  Widget build(BuildContext context) {
    Widget image = PremiumNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      cacheWidth: 1600,
      cacheHeight: 1600,
    );
    image = EditorAdjustmentPreview(adjustments: adjustments, child: image);
    if (transform.offsetX != 0 || transform.offsetY != 0) {
      image = FractionalTranslation(
        translation: Offset(transform.offsetX, transform.offsetY),
        child: image,
      );
    }
    image = _CropPreview(
      crop: transform.crop,
      sourceAspect: sourceAspect,
      child: image,
    );
    final radians =
        (transform.rotationQuarterTurns * 90 + transform.straightenDegrees) *
        math.pi /
        180;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateZ(radians)
        ..scaleByDouble(
          transform.flipHorizontal ? -1 : 1,
          transform.flipVertical ? -1 : 1,
          1,
          1,
        ),
      child: image,
    );
  }
}

class _CropPreview extends StatelessWidget {
  const _CropPreview({
    required this.crop,
    required this.sourceAspect,
    required this.child,
  });

  final NormalizedRect? crop;
  final double sourceAspect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rect = crop;
    if (rect == null) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Size(constraints.maxWidth, constraints.maxHeight);
        var imageWidth = canvas.width;
        var imageHeight = imageWidth / sourceAspect;
        if (imageHeight > canvas.height) {
          imageHeight = canvas.height;
          imageWidth = imageHeight * sourceAspect;
        }
        final imageLeft = (canvas.width - imageWidth) / 2;
        final imageTop = (canvas.height - imageHeight) / 2;
        final cropWidth = imageWidth * rect.width;
        final cropHeight = imageHeight * rect.height;
        final scale = math.min(
          canvas.width / math.max(1, cropWidth),
          canvas.height / math.max(1, cropHeight),
        );
        final cropCenterX =
            imageLeft + (rect.left + rect.width / 2) * imageWidth;
        final cropCenterY =
            imageTop + (rect.top + rect.height / 2) * imageHeight;
        final dx = canvas.width / 2 - cropCenterX * scale;
        final dy = canvas.height / 2 - cropCenterY * scale;
        return ClipRect(
          child: Transform(
            alignment: Alignment.topLeft,
            transform: Matrix4.identity()
              ..translateByDouble(dx, dy, 0, 1)
              ..scaleByDouble(scale, scale, 1, 1),
            child: SizedBox.fromSize(size: canvas, child: child),
          ),
        );
      },
    );
  }
}

class EditorAdjustmentPreview extends StatelessWidget {
  const EditorAdjustmentPreview({
    super.key,
    required this.adjustments,
    required this.child,
  });

  final EditorAdjustments adjustments;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (adjustments.isIdentity) return child;
    final saturation = 1 + adjustments.saturation + adjustments.vibrance * 0.65;
    final contrast = 1 + adjustments.contrast;
    final exposure = math.pow(2, adjustments.exposure).toDouble();
    final brightness = adjustments.brightness * 255;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final sr = (1 - saturation) * lr;
    final sg = (1 - saturation) * lg;
    final sb = (1 - saturation) * lb;
    final offset = 128 * (1 - contrast) + brightness;
    final warmth = adjustments.temperature * 0.16;
    final tint = adjustments.tint * 0.10;
    final redGain = (1 + warmth + tint * 0.45) * exposure;
    final greenGain = (1 - tint) * exposure;
    final blueGain = (1 - warmth + tint * 0.45) * exposure;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        (sr + saturation) * contrast * redGain,
        sg * contrast * redGain,
        sb * contrast * redGain,
        0,
        offset,
        sr * contrast * greenGain,
        (sg + saturation) * contrast * greenGain,
        sb * contrast * greenGain,
        0,
        offset,
        sr * contrast * blueGain,
        sg * contrast * blueGain,
        (sb + saturation) * contrast * blueGain,
        0,
        offset,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: child,
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 18.0;
    final light = Paint()..color = const Color(0xFFF4F4F4);
    final dark = Paint()..color = const Color(0xFFD8D8D8);
    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        final alternate = ((x / tile).floor() + (y / tile).floor()).isEven;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tile, tile),
          alternate ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _colorFromHex(String value) {
  final raw = value.replaceAll('#', '');
  final parsed = int.tryParse(raw, radix: 16) ?? 0xFFFFFF;
  return Color(0xFF000000 | parsed);
}
