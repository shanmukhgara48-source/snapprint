import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/editor_document.dart';
import '../../domain/editor_operation.dart';
import '../providers/ai_editor_provider.dart';

class EditorAdjustPanel extends ConsumerStatefulWidget {
  const EditorAdjustPanel({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  ConsumerState<EditorAdjustPanel> createState() => _EditorAdjustPanelState();
}

class _EditorAdjustPanelState extends ConsumerState<EditorAdjustPanel> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiEditorProvider(widget.args));
    final notifier = ref.read(aiEditorProvider(widget.args).notifier);
    final values = state.adjustDraft;
    final controls = _controls(values);
    final selected = controls[_selected];

    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final item = controls[index];
                  final active = index == _selected;
                  return Tooltip(
                    message: item.label,
                    child: InkWell(
                      onTap: () => setState(() => _selected = index),
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: active
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Reset ${selected.label}',
                  onPressed: selected.value == 0
                      ? null
                      : () => notifier.setAdjustDraft(selected.setValue(0)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                Expanded(
                  child: Slider(
                    value: selected.value,
                    min: selected.min,
                    max: selected.max,
                    divisions: 100,
                    label: _label(selected.value),
                    activeColor: AppColors.accent,
                    onChanged: (value) =>
                        notifier.setAdjustDraft(selected.setValue(value)),
                  ),
                ),
                SizedBox(
                  width: 46,
                  child: Text(
                    _label(selected.value),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: values.isIdentity
                      ? null
                      : () =>
                            notifier.setAdjustDraft(const EditorAdjustments()),
                  child: const Text('Reset all'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => notifier.setActiveTool(EditorTool.none),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: state.isBusy ? null : notifier.applyAdjustments,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_AdjustmentControl> _controls(EditorAdjustments values) => [
    _AdjustmentControl(
      'Brightness',
      Icons.brightness_6_rounded,
      values.brightness,
      (v) => values.copyWith(brightness: v),
    ),
    _AdjustmentControl(
      'Contrast',
      Icons.contrast_rounded,
      values.contrast,
      (v) => values.copyWith(contrast: v),
    ),
    _AdjustmentControl(
      'Saturation',
      Icons.color_lens_outlined,
      values.saturation,
      (v) => values.copyWith(saturation: v),
    ),
    _AdjustmentControl(
      'Temperature',
      Icons.thermostat_rounded,
      values.temperature,
      (v) => values.copyWith(temperature: v),
    ),
    _AdjustmentControl(
      'Tint',
      Icons.tonality_rounded,
      values.tint,
      (v) => values.copyWith(tint: v),
    ),
    _AdjustmentControl(
      'Vibrance',
      Icons.auto_awesome_rounded,
      values.vibrance,
      (v) => values.copyWith(vibrance: v),
    ),
    _AdjustmentControl(
      'Exposure',
      Icons.exposure_rounded,
      values.exposure,
      (v) => values.copyWith(exposure: v),
      min: -2,
      max: 2,
    ),
    _AdjustmentControl(
      'Highlights',
      Icons.light_mode_outlined,
      values.highlights,
      (v) => values.copyWith(highlights: v),
    ),
    _AdjustmentControl(
      'Shadows',
      Icons.dark_mode_outlined,
      values.shadows,
      (v) => values.copyWith(shadows: v),
    ),
    _AdjustmentControl(
      'Sharpness',
      Icons.details_rounded,
      values.sharpness,
      (v) => values.copyWith(sharpness: v),
      min: 0,
    ),
  ];
}

class _AdjustmentControl {
  const _AdjustmentControl(
    this.label,
    this.icon,
    this.value,
    this.setValue, {
    this.min = -1,
    this.max = 1,
  });
  final String label;
  final IconData icon;
  final double value;
  final EditorAdjustments Function(double) setValue;
  final double min;
  final double max;
}

String _label(double value) => value == 0 ? '0' : value.toStringAsFixed(2);
