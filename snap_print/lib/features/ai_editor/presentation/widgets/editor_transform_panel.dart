import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/editor_operation.dart';
import '../providers/ai_editor_provider.dart';

class EditorTransformPanel extends ConsumerWidget {
  const EditorTransformPanel({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiEditorProvider(args));
    final notifier = ref.read(aiEditorProvider(args).notifier);
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Action(
                  tooltip: 'Rotate 90 degrees',
                  icon: Icons.rotate_90_degrees_cw_rounded,
                  onPressed: notifier.rotateClockwise,
                ),
                _Action(
                  tooltip: 'Flip horizontally',
                  icon: Icons.flip_rounded,
                  onPressed: notifier.flipHorizontal,
                ),
                _Action(
                  tooltip: 'Flip vertically',
                  icon: Icons.flip_rounded,
                  quarterTurns: 1,
                  onPressed: notifier.flipVertical,
                ),
                _Action(
                  tooltip: 'Crop',
                  icon: Icons.crop_rounded,
                  onPressed: () => notifier.setActiveTool(EditorTool.crop),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 6),
                const Text(
                  'Straighten',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Expanded(
                  child: Slider(
                    min: -15,
                    max: 15,
                    divisions: 60,
                    value: state.straightenDraft,
                    label: '${state.straightenDraft.toStringAsFixed(1)}°',
                    activeColor: AppColors.accent,
                    onChanged: notifier.setStraightenDraft,
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${state.straightenDraft.toStringAsFixed(1)}°',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => notifier.setActiveTool(EditorTool.none),
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: state.isBusy ? null : notifier.applyStraighten,
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
}

class _Action extends StatelessWidget {
  const _Action({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.quarterTurns = 0,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: RotatedBox(quarterTurns: quarterTurns, child: Icon(icon)),
  );
}
