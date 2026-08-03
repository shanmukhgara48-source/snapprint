import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/ai_editor_models.dart';
import '../../domain/local_image_metrics.dart';

/// Print-quality panel combining the server's AI analysis (composition,
/// blur, exposure, faces) with instant on-device metrics (resolution, file
/// size, DPI for the selected print size) — the local half never waits on
/// the network.
class EditorAnalysisPanel extends StatelessWidget {
  const EditorAnalysisPanel({
    super.key,
    required this.analysis,
    required this.isAnalyzing,
    required this.localMetrics,
    required this.selectedSize,
  });

  final AiPrintAnalysis? analysis;
  final bool isAnalyzing;
  final LocalImageMetrics? localMetrics;
  final String selectedSize;

  @override
  Widget build(BuildContext context) {
    final metrics = localMetrics;
    final isLowRes = metrics?.isLowResolutionFor(selectedSize) ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServerSection(),
          if (metrics != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.photo_size_select_large_rounded,
                  label: metrics.resolutionLabel,
                ),
                _MetricChip(
                  icon: Icons.sd_storage_rounded,
                  label: metrics.fileSizeLabel,
                ),
                _MetricChip(
                  icon: Icons.grid_on_rounded,
                  label: '${metrics.megapixels.toStringAsFixed(1)} MP',
                ),
                _MetricChip(
                  icon: Icons.print_rounded,
                  label: metrics.dpiLabelFor(selectedSize),
                  warning: isLowRes,
                ),
              ],
            ),
            if (isLowRes) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Below 300 DPI for $selectedSize — print quality may look soft. '
                        'Best size at 300 DPI: ${metrics.estimatedPrintSizeAt300Dpi}.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildServerSection() {
    final data = analysis;
    if (data == null) {
      return Row(
        children: [
          if (isAnalyzing)
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
      );
    }
    return Column(
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
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    this.warning = false,
  });
  final IconData icon;
  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningLight : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: warning ? AppColors.warning : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
