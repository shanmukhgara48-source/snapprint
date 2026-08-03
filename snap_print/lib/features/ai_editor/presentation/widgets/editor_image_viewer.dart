import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/editor_operation.dart';
import '../providers/ai_editor_provider.dart';
import 'editor_canvas.dart';

class EditorImageViewer extends ConsumerStatefulWidget {
  const EditorImageViewer({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  ConsumerState<EditorImageViewer> createState() => _EditorImageViewerState();
}

class _EditorImageViewerState extends ConsumerState<EditorImageViewer>
    with SingleTickerProviderStateMixin {
  final _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final details = _doubleTapDetails;
    if (details == null) return;
    if (_transformController.value.getMaxScaleOnAxis() > 1.05) {
      _transformController.value = Matrix4.identity();
      return;
    }
    final point = details.localPosition;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(-point.dx * 1.5, -point.dy * 1.5, 0, 1)
      ..scaleByDouble(2.5, 2.5, 2.5, 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiEditorProvider(widget.args));
    final notifier = ref.read(aiEditorProvider(widget.args).notifier);
    return ClipRect(
      child: state.compareMode && state.canUndo
          ? _CompareSlider(state: state, onChanged: notifier.setComparePosition)
          : GestureDetector(
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: _onDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1,
                maxScale: 6,
                child: SizedBox.expand(
                  child: EditorCanvas(
                    document: state.document,
                    previewAdjustments: state.activeTool == EditorTool.adjust
                        ? state.adjustDraft
                        : null,
                    previewStraighten: state.activeTool == EditorTool.transform
                        ? state.straightenDraft
                        : null,
                  ),
                ),
              ),
            ),
    );
  }
}

class _CompareSlider extends StatelessWidget {
  const _CompareSlider({required this.state, required this.onChanged});
  final AiEditorState state;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onHorizontalDragUpdate: (details) => onChanged(
          (details.localPosition.dx / constraints.maxWidth).clamp(0, 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            EditorCanvas(document: state.document, showOriginal: true),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: state.comparePosition,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: EditorCanvas(document: state.document),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * state.comparePosition - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: Colors.white),
            ),
            const Positioned(left: 10, bottom: 10, child: _Label('Before')),
            const Positioned(right: 10, bottom: 10, child: _Label('After')),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
