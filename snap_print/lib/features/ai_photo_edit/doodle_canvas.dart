import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Freehand drawing overlay so the user can mark a region of the photo for
/// Gemini to focus an edit on. Plain CustomPainter — no drawing package
/// dependency needed, keeps this simple to integrate.
class DoodleCanvas extends StatefulWidget {
  const DoodleCanvas({super.key, required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<DoodleCanvas> createState() => DoodleCanvasState();
}

class DoodleCanvasState extends State<DoodleCanvas> {
  final List<List<Offset>> _strokes = [];
  final GlobalKey _boundaryKey = GlobalKey();

  bool get hasDoodle => _strokes.any((s) => s.length > 1);

  void clear() => setState(_strokes.clear);

  void _onPanStart(DragStartDetails d) => setState(() => _strokes.add([d.localPosition]));

  void _onPanUpdate(DragUpdateDetails d) => setState(() => _strokes.last.add(d.localPosition));

  /// Renders just the strokes (transparent background), same pixel size as
  /// this widget, so it lines up with the base image when sent to Gemini.
  Future<Uint8List?> exportPng() async {
    if (!hasDoodle) return null;
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _DoodlePainter(_strokes),
            size: Size(widget.width, widget.height),
          ),
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}
