import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/editor_operation.dart';
import '../providers/ai_editor_provider.dart';
import 'editor_preset_sheet.dart';
import 'editor_style_sheet.dart';

class EditorBottomToolbar extends ConsumerWidget {
  const EditorBottomToolbar({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiEditorProvider(args));
    final notifier = ref.read(aiEditorProvider(args).notifier);
    final items = <_ToolbarItemData>[
      _ToolbarItemData(
        icon: Icons.auto_fix_high_rounded,
        label: state.document.hasCutout ? 'Cutout' : 'Remove BG',
        active: state.document.hasCutout,
        onTap: !state.backgroundRemovalAvailable || state.isBusy
            ? null
            : notifier.removeBackground,
      ),
      _ToolbarItemData(
        icon: Icons.center_focus_strong_rounded,
        label: 'Auto crop',
        onTap: state.isBusy ? null : notifier.autoCrop,
      ),
      _ToolbarItemData(
        icon: Icons.align_horizontal_center_rounded,
        label: 'Center',
        onTap: state.isBusy || !state.document.hasCutout
            ? null
            : notifier.smartCenter,
      ),
      _ToolbarItemData(
        icon: Icons.wallpaper_rounded,
        label: 'Background',
        active: state.activeTool == EditorTool.background,
        onTap: state.isBusy
            ? null
            : () => showBackgroundOptionsSheet(context, ref, args),
      ),
      _ToolbarItemData(
        icon: Icons.tune_rounded,
        label: 'Adjust',
        active: state.activeTool == EditorTool.adjust,
        onTap: state.isBusy
            ? null
            : () => notifier.setActiveTool(EditorTool.adjust),
      ),
      _ToolbarItemData(
        icon: Icons.transform_rounded,
        label: 'Transform',
        active: state.activeTool == EditorTool.transform,
        onTap: state.isBusy
            ? null
            : () => notifier.setActiveTool(EditorTool.transform),
      ),
      _ToolbarItemData(
        icon: Icons.crop_rounded,
        label: 'Crop',
        active: state.activeTool == EditorTool.crop,
        onTap: state.isBusy
            ? null
            : () => notifier.setActiveTool(EditorTool.crop),
      ),
      _ToolbarItemData(
        icon: Icons.brush_rounded,
        label: 'Style',
        active: state.activeTool == EditorTool.style,
        onTap: state.isBusy
            ? null
            : () => showStyleSheet(context, ref, args),
      ),
      _ToolbarItemData(
        icon: Icons.landscape_rounded,
        label: 'Scene',
        onTap: state.isBusy
            ? null
            : () => showSceneSheet(context, ref, args),
      ),
      _ToolbarItemData(
        icon: Icons.auto_awesome_rounded,
        label: 'Enhance',
        onTap: state.isBusy
            ? null
            : () => notifier.applyPromptEdit('Enhance photo quality'),
      ),
    ];

    return Material(
      color: AppColors.surface,
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: items.length,
          itemBuilder: (context, index) => _ToolbarItem(items[index]),
        ),
      ),
    );
  }
}

class _ToolbarItemData {
  const _ToolbarItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
}

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem(this.item);
  final _ToolbarItemData item;

  @override
  Widget build(BuildContext context) {
    final color = item.onTap == null
        ? AppColors.textHint
        : item.active
        ? AppColors.accent
        : AppColors.textPrimary;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
