import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../../../core/widgets/premium_network_image.dart';
import '../../data/ai_editor_service.dart';
import '../../domain/ai_editor_models.dart';

class AiPhotoEditorArgs {
  const AiPhotoEditorArgs({
    required this.imageUrl,
    required this.productName,
    required this.selectedSize,
  });

  final String imageUrl;
  final String productName;
  final String selectedSize;
}

class AiPhotoEditorScreen extends ConsumerStatefulWidget {
  const AiPhotoEditorScreen({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  ConsumerState<AiPhotoEditorScreen> createState() =>
      _AiPhotoEditorScreenState();
}

class _AiPhotoEditorScreenState extends ConsumerState<AiPhotoEditorScreen> {
  final _promptController = TextEditingController();
  final _maskKey = GlobalKey();
  final List<String> _history = [];
  final List<Offset?> _maskPoints = [];

  int _cursor = 0;
  bool _enabled = true;
  bool _loadingStatus = true;
  bool _editing = false;
  bool _analyzing = false;
  bool _drawMask = false;
  bool _rightsConfirmed = false;
  double _compare = 0.5;
  String _selectedOperation = 'enhance';
  String? _previousInteractionId;
  AiPrintAnalysis? _analysis;

  String get _currentUrl => _history[_cursor];
  String get _draftKey => 'ai_editor_${widget.args.imageUrl.hashCode}';

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      if (mounted) setState(() {});
    });
    _history.add(widget.args.imageUrl);
    _restoreDraft();
    _loadStatus();
    _analyze();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_draftKey);
    if (saved == null || saved.isEmpty || !mounted) return;
    setState(() {
      _history
        ..clear()
        ..addAll(saved);
      _cursor = _history.length - 1;
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_draftKey, _history);
  }

  Future<void> _loadStatus() async {
    try {
      final enabled = await ref.read(aiEditorServiceProvider).isEnabled();
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      if (mounted) setState(() => _enabled = false);
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    try {
      final analysis = await ref
          .read(aiEditorServiceProvider)
          .analyze(
            imageUrl: _currentUrl,
            productName: widget.args.productName,
            selectedSize: widget.args.selectedSize,
          );
      if (mounted) setState(() => _analysis = analysis);
    } catch (_) {
      // Analysis is helpful, not blocking.
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _runEdit() async {
    if (!_enabled || _editing) return;
    final preset = _presets.firstWhere(
      (item) => item.operation == _selectedOperation,
    );
    final prompt = _promptController.text.trim().isNotEmpty
        ? _promptController.text.trim()
        : preset.prompt;

    setState(() => _editing = true);
    try {
      final result = await ref
          .read(aiEditorServiceProvider)
          .edit(
            imageUrl: _currentUrl,
            operation: _selectedOperation,
            productName: widget.args.productName,
            selectedSize: widget.args.selectedSize,
            prompt: prompt,
            maskImageBase64: _selectedOperation == 'magic_eraser'
                ? await _captureMask()
                : null,
            previousInteractionId: _previousInteractionId,
            rightsConfirmed: _rightsConfirmed,
          );
      if (!mounted) return;
      setState(() {
        if (_cursor < _history.length - 1) {
          _history.removeRange(_cursor + 1, _history.length);
        }
        _history.add(result.editedImageUrl);
        _cursor = _history.length - 1;
        _previousInteractionId = result.interactionId;
        _drawMask = false;
        _maskPoints.clear();
      });
      await _saveDraft();
      await _analyze();
    } catch (e) {
      if (mounted) showErrorSnackbar(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<String?> _captureMask() async {
    if (_maskPoints.whereType<Offset>().isEmpty) return null;
    final boundary =
        _maskKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return base64Encode(byteData.buffer.asUint8List());
  }

  void _undo() {
    if (_cursor == 0) return;
    setState(() => _cursor--);
  }

  void _redo() {
    if (_cursor >= _history.length - 1) return;
    setState(() => _cursor++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Photo Studio'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _cursor > 0 ? _undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _cursor < _history.length - 1 ? _redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
        children: [
          _PreviewPanel(
            originalUrl: widget.args.imageUrl,
            editedUrl: _currentUrl,
            compare: _compare,
            drawMask: _drawMask,
            maskKey: _maskKey,
            maskPoints: _maskPoints,
            onCompareChanged: (value) => setState(() => _compare = value),
            onMaskChanged: () => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_loadingStatus)
            const LinearProgressIndicator(color: AppColors.accent)
          else if (!_enabled)
            const _EditorUnavailable(),
          const SizedBox(height: 14),
          _AnalysisPanel(analysis: _analysis, isLoading: _analyzing),
          const SizedBox(height: 18),
          _PresetStrip(
            selected: _selectedOperation,
            onSelected: (operation) {
              setState(() {
                _selectedOperation = operation;
                _drawMask = operation == 'magic_eraser';
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _promptController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe the edit, background, crop, or filter...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          if (_selectedOperation == 'magic_eraser') ...[
            const SizedBox(height: 10),
            _InfoPill(
              icon: Icons.brush_rounded,
              text: _maskPoints.whereType<Offset>().isEmpty
                  ? 'Draw over objects to remove, then apply Magic Eraser.'
                  : 'Mask ready. Apply AI to remove the marked area.',
            ),
          ],
          if (_promptController.text.toLowerCase().contains('watermark')) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _rightsConfirmed,
              onChanged: (value) =>
                  setState(() => _rightsConfirmed = value ?? false),
              title: const Text(
                'I own this image and have the right to edit it',
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Use Photo',
                  icon: Icons.check_rounded,
                  isOutlined: true,
                  onPressed: () => Navigator.pop(context, _currentUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  label: _editing ? 'Editing...' : 'Apply AI',
                  icon: Icons.auto_awesome_rounded,
                  isLoading: _editing,
                  onPressed: _enabled ? _runEdit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.originalUrl,
    required this.editedUrl,
    required this.compare,
    required this.drawMask,
    required this.maskKey,
    required this.maskPoints,
    required this.onCompareChanged,
    required this.onMaskChanged,
  });

  final String originalUrl;
  final String editedUrl;
  final double compare;
  final bool drawMask;
  final GlobalKey maskKey;
  final List<Offset?> maskPoints;
  final ValueChanged<double> onCompareChanged;
  final VoidCallback onMaskChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: drawMask
                      ? (details) {
                          maskPoints.add(details.localPosition);
                          onMaskChanged();
                        }
                      : null,
                  onPanUpdate: drawMask
                      ? (details) {
                          maskPoints.add(details.localPosition);
                          onMaskChanged();
                        }
                      : null,
                  onPanEnd: drawMask
                      ? (_) {
                          maskPoints.add(null);
                          onMaskChanged();
                        }
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PremiumNetworkImage(
                          imageUrl: originalUrl,
                          cacheWidth: 900,
                          cacheHeight: 900,
                        ),
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: compare,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: PremiumNetworkImage(
                                imageUrl: editedUrl,
                                cacheWidth: 900,
                                cacheHeight: 900,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: constraints.maxWidth * compare - 1,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: Colors.white),
                        ),
                        RepaintBoundary(
                          key: maskKey,
                          child: CustomPaint(
                            painter: _MaskPainter(maskPoints),
                            size: Size.infinite,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Slider(
            value: compare,
            onChanged: drawMask ? null : onCompareChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _PresetStrip extends StatelessWidget {
  const _PresetStrip({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final preset = _presets[index];
          final active = selected == preset.operation;
          return GestureDetector(
            onTap: () => onSelected(preset.operation),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 112,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? AppColors.accent : AppColors.divider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    preset.icon,
                    color: active ? AppColors.accent : AppColors.primary,
                  ),
                  const Spacer(),
                  Text(
                    preset.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  const _AnalysisPanel({required this.analysis, required this.isLoading});
  final AiPrintAnalysis? analysis;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final data = analysis;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: data == null
          ? Row(
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.insights_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                const Text('Analyzing print quality...'),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ScoreRing(score: data.score),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Print Quality',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${data.resolution} · ${data.dpiEstimate}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data.cropRecommendation,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...data.suggestions.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $item'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score.clamp(0, 100) / 100,
            strokeWidth: 5,
            color: score >= 75 ? AppColors.success : AppColors.warning,
            backgroundColor: AppColors.border,
          ),
          Center(
            child: Text(
              '$score',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EditorUnavailable extends StatelessWidget {
  const _EditorUnavailable();

  @override
  Widget build(BuildContext context) {
    return const _InfoPill(
      icon: Icons.lock_outline_rounded,
      text: 'AI Photo Studio is not configured on this backend yet.',
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

class _Preset {
  const _Preset(this.operation, this.label, this.icon, this.prompt);
  final String operation;
  final String label;
  final IconData icon;
  final String prompt;
}

const _presets = [
  _Preset('enhance', 'AI Enhance', Icons.auto_awesome_rounded, ''),
  _Preset('portrait', 'Portrait', Icons.face_retouching_natural, ''),
  _Preset(
    'background',
    'Background',
    Icons.wallpaper_rounded,
    'Use a clean luxury studio background.',
  ),
  _Preset('magic_eraser', 'Magic Eraser', Icons.cleaning_services, ''),
  _Preset('object_removal', 'Remove', Icons.content_cut_rounded, ''),
  _Preset('upscale', 'Upscale', Icons.high_quality_rounded, '2x'),
  _Preset('crop', 'AI Crop', Icons.crop_rounded, ''),
  _Preset('colorize', 'Colorize', Icons.palette_rounded, ''),
  _Preset('restore', 'Restore', Icons.healing_rounded, ''),
  _Preset('filter', 'Filters', Icons.filter_vintage_rounded, 'Luxury'),
  _Preset('prompt', 'Prompt', Icons.chat_bubble_outline_rounded, ''),
];

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('Gemini AI editor is not configured')) {
    return 'AI Photo Studio is not configured yet.';
  }
  if (text.contains('watermark')) return 'Please confirm image rights first.';
  return 'AI edit failed. Please try another edit or use the original photo.';
}
