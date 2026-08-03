import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Draw-to-mask layer for the Magic Eraser tool, stacked over the preview
/// image. Owns its own point-list state locally (not through Riverpod) so
/// high-frequency drag events don't trigger notifier rebuilds. Attach a
/// [GlobalKey<MagicEraserMaskLayerState>] to call [captureMask]/[clear]
/// from the parent when the user taps "Apply".
class MagicEraserMaskLayer extends StatefulWidget {
  const MagicEraserMaskLayer({super.key, required this.active});
  final bool active;

  @override
  State<MagicEraserMaskLayer> createState() => MagicEraserMaskLayerState();
}

class MagicEraserMaskLayerState extends State<MagicEraserMaskLayer> {
  final _boundaryKey = GlobalKey();
  final List<Offset?> _points = [];

  bool get hasMask => _points.whereType<Offset>().isNotEmpty;

  void clear() => setState(_points.clear);

  /// Renders the drawn strokes to a transparent PNG and returns it as
  /// base64, or null if nothing has been drawn.
  Future<String?> captureMask() async {
    if (!hasMask) return null;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return base64Encode(byteData.buffer.asUint8List());
  }

  @override
  void didUpdateWidget(covariant MagicEraserMaskLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.active
          ? (details) => setState(() => _points.add(details.localPosition))
          : null,
      onPanUpdate: widget.active
          ? (details) => setState(() => _points.add(details.localPosition))
          : null,
      onPanEnd: widget.active ? (_) => setState(() => _points.add(null)) : null,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: CustomPaint(painter: _MaskPainter(_points), size: Size.infinite),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  const _MaskPainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.72)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) => true;
}
