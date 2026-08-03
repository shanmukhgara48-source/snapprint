import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/ai_editor_provider.dart';

const _messagesByStatus = <EditorStatus, List<String>>{
  EditorStatus.removingBackground: [
    'Finding the subject...',
    'Refining hair and edges...',
    'Estimating clean foreground colors...',
    'Building the full-resolution PNG...',
  ],
  EditorStatus.serverProcessing: [
    'Analyzing image...',
    'Talking to the AI model...',
    'Generating your edit...',
    'Almost done...',
  ],
  EditorStatus.uploadingBackground: [
    'Uploading background...',
    'Preparing the preview...',
  ],
  EditorStatus.exporting: [
    'Rendering at full resolution...',
    'Applying print adjustments...',
    'Embedding color and DPI metadata...',
    'Saving the print file...',
  ],
  EditorStatus.analyzing: ['Analyzing image...', 'Checking print quality...'],
};

/// Full-screen progress scrim for GPU processing, uploads, and final export.
class EditorProcessingOverlay extends StatefulWidget {
  const EditorProcessingOverlay({
    super.key,
    required this.child,
    required this.status,
  });

  final Widget child;
  final EditorStatus status;

  @override
  State<EditorProcessingOverlay> createState() =>
      _EditorProcessingOverlayState();
}

class _EditorProcessingOverlayState extends State<EditorProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  Timer? _messageTimer;
  int _messageIndex = 0;

  bool get _visible => _messagesByStatus.containsKey(widget.status);

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (_visible) _start();
  }

  @override
  void didUpdateWidget(covariant EditorProcessingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (_visible) {
        _messageIndex = 0;
        _start();
      } else {
        _stop();
      }
    }
  }

  void _start() {
    _spinController.repeat();
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      final messages = _messagesByStatus[widget.status];
      if (messages == null) return;
      setState(() => _messageIndex = (_messageIndex + 1) % messages.length);
    });
  }

  void _stop() {
    _spinController.stop();
    _messageTimer?.cancel();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messagesByStatus[widget.status];
    return Stack(
      children: [
        widget.child,
        if (messages != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: _spinController,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.accent,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        messages[_messageIndex],
                        key: ValueKey(_messageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
