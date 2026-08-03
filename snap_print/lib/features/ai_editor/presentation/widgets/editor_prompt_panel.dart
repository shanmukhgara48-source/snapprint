import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/prompt_edit_intent.dart';
import '../providers/ai_editor_provider.dart';

class EditorPromptPanel extends ConsumerStatefulWidget {
  const EditorPromptPanel({super.key, required this.args});

  final AiPhotoEditorArgs args;

  @override
  ConsumerState<EditorPromptPanel> createState() => _EditorPromptPanelState();
}

class _EditorPromptPanelState extends ConsumerState<EditorPromptPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;
    final needsRightsConfirmation = trimmed.toLowerCase().contains('watermark');
    var rightsConfirmed = false;
    if (needsRightsConfirmation) {
      rightsConfirmed = await _confirmWatermarkRights();
      if (!rightsConfirmed || !mounted) return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(aiEditorProvider(widget.args).notifier)
        .applyPromptEdit(trimmed, rightsConfirmed: rightsConfirmed);
  }

  Future<bool> _confirmWatermarkRights() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm image rights'),
        content: const Text(
          'Only remove a watermark from an image you own or have permission to edit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I have rights'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiEditorProvider(widget.args));
    final notifier = ref.read(aiEditorProvider(widget.args).notifier);
    final recent = state.recentPrompts;
    final chips = recent.isEmpty ? promptEditSuggestions : recent;

    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !state.isBusy,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: state.isBusy ? null : _submit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe any edit...',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF262626),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: FilledButton(
                    onPressed: state.isBusy
                        ? null
                        : () => _submit(_controller.text),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: chips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final prompt = chips[index];
                        return _PromptChip(
                          label: prompt,
                          enabled: !state.isBusy,
                          onTap: () {
                            _controller.text = prompt;
                            _controller.selection = TextSelection.collapsed(
                              offset: prompt.length,
                            );
                            _submit(prompt);
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: state.compareMode ? 'Hide compare' : 'Compare',
                  onPressed: state.canUndo ? notifier.toggleCompare : null,
                  icon: Icon(
                    Icons.compare_rounded,
                    color: state.compareMode
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
                if (state.isBusy)
                  IconButton(
                    tooltip: 'Cancel',
                    onPressed: notifier.cancelGeneration,
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    onPressed: enabled ? onTap : null,
    avatar: const Icon(Icons.auto_fix_high_rounded, size: 15),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
    visualDensity: VisualDensity.compact,
    side: const BorderSide(color: AppColors.border),
    backgroundColor: const Color(0xFF262626),
    disabledColor: const Color(0xFF202020),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}
