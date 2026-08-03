import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/premium_network_image.dart';
import '../../domain/editor_document.dart';
import '../../domain/editor_operation.dart';
import '../providers/ai_editor_provider.dart';

class _RatioOption {
  const _RatioOption(this.label, this.ratio);
  final String label;
  // null = free-form, otherwise width/height.
  final double? ratio;
}

const _ratioOptions = <_RatioOption>[
  _RatioOption('Free', null),
  _RatioOption('1:1', 1),
  _RatioOption('4x6', 4 / 6),
  _RatioOption('5x7', 5 / 7),
  _RatioOption('8x10', 8 / 10),
  _RatioOption('Passport', 1),
];

/// Crop tool panel: aspect-ratio chips + a draggable/resizable crop rect
/// over the current image, normalized to a [NormalizedRect] on every change.
class EditorCropOverlay extends ConsumerStatefulWidget {
  const EditorCropOverlay({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  ConsumerState<EditorCropOverlay> createState() => _EditorCropOverlayState();
}

class _EditorCropOverlayState extends ConsumerState<EditorCropOverlay> {
  int _selectedRatioIndex = 0;
  Rect _rect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  Size _boxSize = Size.zero;

  double? get _lockedRatio => _ratioOptions[_selectedRatioIndex].ratio;

  void _publish() {
    final rect = NormalizedRect(
      left: _rect.left,
      top: _rect.top,
      width: _rect.width,
      height: _rect.height,
    );
    ref.read(aiEditorProvider(widget.args).notifier).setCropDraft(rect);
  }

  void _applyRatio(double? ratio, Size box) {
    if (ratio == null || box.isEmpty) return;
    final centerX = _rect.left + _rect.width / 2;
    final centerY = _rect.top + _rect.height / 2;
    // Ratio is width/height in real units; box normalizes 0..1 over the
    // displayed square, so convert through the box's actual aspect ratio.
    final boxRatio = box.width / box.height;
    var w = _rect.width;
    var h = w * boxRatio / ratio;
    if (h > 1) {
      h = 1;
      w = h * ratio / boxRatio;
    }
    var left = (centerX - w / 2).clamp(0.0, 1.0 - w);
    var top = (centerY - h / 2).clamp(0.0, 1.0 - h);
    setState(() => _rect = Rect.fromLTWH(left, top, w, h));
    _publish();
  }

  void _onPanMove(Offset delta) {
    if (_boxSize.isEmpty) return;
    final dx = delta.dx / _boxSize.width;
    final dy = delta.dy / _boxSize.height;
    final left = (_rect.left + dx).clamp(0.0, 1.0 - _rect.width);
    final top = (_rect.top + dy).clamp(0.0, 1.0 - _rect.height);
    setState(() => _rect = Rect.fromLTWH(left, top, _rect.width, _rect.height));
  }

  void _onResize(Offset delta) {
    if (_boxSize.isEmpty) return;
    final dx = delta.dx / _boxSize.width;
    final dy = delta.dy / _boxSize.height;
    final ratio = _lockedRatio;
    var width = (_rect.width + dx).clamp(0.08, 1.0 - _rect.left);
    var height = ratio == null
        ? (_rect.height + dy).clamp(0.08, 1.0 - _rect.top)
        : width * (_boxSize.width / _boxSize.height) / ratio;
    if (_rect.top + height > 1) height = 1 - _rect.top;
    if (ratio != null) {
      width = height * ratio / (_boxSize.width / _boxSize.height);
      if (_rect.left + width > 1) width = 1 - _rect.left;
    }
    setState(() => _rect = Rect.fromLTWH(_rect.left, _rect.top, width, height));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiEditorProvider(widget.args));
    final notifier = ref.read(aiEditorProvider(widget.args).notifier);
    final metrics = state.localMetrics;
    final imageRatio = metrics != null && metrics.height > 0
        ? metrics.width / metrics.height
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ratioOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedRatioIndex;
                return ChoiceChip(
                  label: Text(_ratioOptions[index].label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedRatioIndex = index);
                    _applyRatio(_ratioOptions[index].ratio, _boxSize);
                  },
                  selectedColor: AppColors.accentLight,
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: imageRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _boxSize = Size(constraints.maxWidth, constraints.maxHeight);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PremiumNetworkImage(
                        imageUrl: state.currentUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 900,
                      ),
                      _CropMask(rect: _rect, boxSize: _boxSize),
                      Positioned(
                        left: _rect.left * _boxSize.width,
                        top: _rect.top * _boxSize.height,
                        width: _rect.width * _boxSize.width,
                        height: _rect.height * _boxSize.height,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            _onPanMove(d.delta);
                            _publish();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: GestureDetector(
                                onPanUpdate: (d) {
                                  _onResize(d.delta);
                                  _publish();
                                },
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_full_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Cancel',
                  isOutlined: true,
                  onPressed: () => notifier.setActiveTool(EditorTool.none),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Apply Crop',
                  isLoading: state.isBusy,
                  onPressed: state.isBusy
                      ? null
                      : () {
                          _publish();
                          notifier.applyCrop();
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropMask extends StatelessWidget {
  const _CropMask({required this.rect, required this.boxSize});
  final Rect rect;
  final Size boxSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: boxSize, painter: _CropMaskPainter(rect)),
    );
  }
}

class _CropMaskPainter extends CustomPainter {
  _CropMaskPainter(this.rect);
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final cropPx = Rect.fromLTWH(
      rect.left * size.width,
      rect.top * size.height,
      rect.width * size.width,
      rect.height * size.height,
    );
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRect(cropPx);
    canvas.drawPath(Path.combine(PathOperation.difference, full, hole), paint);
  }

  @override
  bool shouldRepaint(covariant _CropMaskPainter oldDelegate) =>
      oldDelegate.rect != rect;
}
