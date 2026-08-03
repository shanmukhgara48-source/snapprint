import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../domain/editor_operation.dart';
import '../providers/ai_editor_provider.dart';
import '../widgets/editor_adjust_panel.dart';
import '../widgets/editor_analysis_panel.dart';
import '../widgets/editor_bottom_toolbar.dart';
import '../widgets/editor_canvas.dart';
import '../widgets/editor_crop_overlay.dart';
import '../widgets/editor_image_viewer.dart';
import '../widgets/editor_prompt_panel.dart';
import '../widgets/editor_processing_overlay.dart';
import '../widgets/editor_top_bar.dart';
import '../widgets/editor_transform_panel.dart';

export '../providers/ai_editor_provider.dart' show AiPhotoEditorArgs;

class AiPhotoEditorScreen extends ConsumerStatefulWidget {
  const AiPhotoEditorScreen({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  ConsumerState<AiPhotoEditorScreen> createState() =>
      _AiPhotoEditorScreenState();
}

class _AiPhotoEditorScreenState extends ConsumerState<AiPhotoEditorScreen> {
  String? _lastShownError;

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final state = ref.watch(aiEditorProvider(args));
    final notifier = ref.read(aiEditorProvider(args).notifier);
    ref.listen(aiEditorProvider(args), (previous, next) {
      final message = next.errorMessage;
      if (message != null && message != _lastShownError) {
        _lastShownError = message;
        showErrorSnackbar(context, message);
        notifier.dismissError();
      }
      if (message == null) _lastShownError = null;
    });

    return Scaffold(
      backgroundColor: const Color(0xFF191919),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 4,
        title: const Text(
          'Photo Editor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [EditorTopBarActions(args: args)],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (state.loadingStatus)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.accent,
              )
            else if (!state.backgroundRemovalAvailable)
              const _CapabilityBanner(),
            Expanded(
              child: EditorProcessingOverlay(
                status: state.status,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: state.activeTool == EditorTool.crop
                      ? SingleChildScrollView(
                          key: const ValueKey('crop'),
                          padding: const EdgeInsets.all(12),
                          child: EditorCropOverlay(args: args),
                        )
                      : EditorImageViewer(
                          key: const ValueKey('viewer'),
                          args: args,
                        ),
                ),
              ),
            ),
            _QualityStrip(args: args),
            EditorPromptPanel(args: args),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.bottomCenter,
              child: switch (state.activeTool) {
                EditorTool.adjust => EditorAdjustPanel(args: args),
                EditorTool.transform => EditorTransformPanel(args: args),
                _ => const SizedBox.shrink(),
              },
            ),
            EditorBottomToolbar(args: args),
            Material(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => _showExportPreview(context, args),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Use Photo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportPreview(
    BuildContext context,
    AiPhotoEditorArgs args,
  ) async {
    final shouldExport = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => _ExportPreview(args: args),
    );
    if (shouldExport != true || !context.mounted) return;
    final result = await ref
        .read(aiEditorProvider(args).notifier)
        .exportCurrent();
    if (result != null && context.mounted) {
      Navigator.pop(context, result.imageUrl);
    }
  }
}

class _QualityStrip extends ConsumerWidget {
  const _QualityStrip({required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiEditorProvider(args));
    final metrics = state.outputMetrics;
    final dpi = metrics?.dpiFor(args.selectedSize);
    final low = dpi != null && dpi < 300;
    return Material(
      color: const Color(0xFF262626),
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          builder: (context) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EditorAnalysisPanel(
                analysis: state.serverAnalysis,
                isAnalyzing: state.analyzing,
                localMetrics: metrics,
                selectedSize: args.selectedSize,
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(
                low ? Icons.warning_amber_rounded : Icons.verified_rounded,
                size: 18,
                color: low ? AppColors.warning : const Color(0xFF76C893),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metrics == null
                      ? 'Checking print quality...'
                      : '${metrics.resolutionLabel}  •  ${metrics.dpiLabelFor(args.selectedSize)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportPreview extends ConsumerWidget {
  const _ExportPreview({required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiEditorProvider(args));
    final metrics = state.outputMetrics;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Export Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              width: double.infinity,
              child: EditorCanvas(document: state.document),
            ),
            const SizedBox(height: 14),
            _ExportFact(
              icon: Icons.photo_size_select_large_rounded,
              label: metrics?.resolutionLabel ?? 'Reading resolution...',
            ),
            _ExportFact(
              icon: Icons.print_rounded,
              label:
                  metrics?.dpiLabelFor(args.selectedSize) ??
                  'Calculating print DPI...',
            ),
            _ExportFact(
              icon: state.document.background.kind.name == 'transparent'
                  ? Icons.grid_on_rounded
                  : Icons.image_rounded,
              label:
                  state.document.background.kind.name == 'transparent' &&
                      state.document.hasCutout
                  ? 'Full-resolution PNG with transparency'
                  : 'Full-resolution print image',
            ),
            for (final warning in state.warnings)
              _ExportFact(
                icon: Icons.warning_amber_rounded,
                label: warning,
                warning: true,
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Export and use'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportFact extends StatelessWidget {
  const _ExportFact({
    required this.icon,
    required this.label,
    this.warning = false,
  });
  final IconData icon;
  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: warning ? AppColors.warning : AppColors.textSecondary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: warning ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CapabilityBanner extends StatelessWidget {
  const _CapabilityBanner();

  @override
  Widget build(BuildContext context) => const Material(
    color: Color(0xFFFFF3E0),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 17, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI cutout is offline. Crop, transform, and adjustments remain available.',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
