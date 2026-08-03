import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_editor_provider.dart';

/// AppBar actions: undo, redo, compare and reset.
class EditorTopBarActions extends ConsumerWidget {
  const EditorTopBarActions({super.key, required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiEditorProvider(args));
    final notifier = ref.read(aiEditorProvider(args).notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Undo',
          onPressed: state.canUndo ? notifier.undo : null,
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton(
          tooltip: 'Redo',
          onPressed: state.canRedo ? notifier.redo : null,
          icon: const Icon(Icons.redo_rounded),
        ),
        IconButton(
          tooltip: 'Compare with original',
          onPressed: state.canUndo ? notifier.toggleCompare : null,
          isSelected: state.compareMode,
          icon: const Icon(Icons.compare_rounded),
        ),
        PopupMenuButton<String>(
          tooltip: 'More editor actions',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'reset') notifier.reset();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'reset',
              enabled: state.canUndo && !state.isBusy,
              child: const Row(
                children: [
                  Icon(Icons.restart_alt_rounded),
                  SizedBox(width: 10),
                  Text('Reset to original'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
