import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/upload_repository.dart';
import '../../domain/editor_document.dart';
import '../providers/ai_editor_provider.dart';

const _solidColors = <String>[
  '#FFFFFF',
  '#000000',
  '#E8EEF5',
  '#F0D8DC',
  '#D9E5D1',
  '#F4E5C8',
  '#C9DDF2',
  '#E4D9F0',
];

const _gradients = <(String, String)>[
  ('#FFFFFF', '#DDE7F2'),
  ('#FFF4E8', '#F2CCD4'),
  ('#E8F1E4', '#C7DCEC'),
  ('#F3EAFE', '#D8D5F3'),
];

Future<void> showBackgroundOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  AiPhotoEditorArgs args,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (sheetContext) => _BackgroundSheet(args: args),
  );
}

class _BackgroundSheet extends ConsumerWidget {
  const _BackgroundSheet({required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiEditorProvider(args));
    final notifier = ref.read(aiEditorProvider(args).notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Background',
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
            if (!state.document.hasCutout)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.backgroundRemovalAvailable && !state.isBusy
                      ? () {
                          Navigator.pop(context);
                          notifier.removeBackground();
                        }
                      : null,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Remove background'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _BackgroundChoice(
                    icon: Icons.grid_on_rounded,
                    label: 'Transparent',
                    selected:
                        state.document.background.kind ==
                        EditorBackgroundKind.transparent,
                    onTap: () =>
                        _select(context, notifier, const EditorBackground()),
                  ),
                  _BackgroundChoice(
                    icon: Icons.crop_square_rounded,
                    label: 'White',
                    selected:
                        state.document.background.kind ==
                            EditorBackgroundKind.solid &&
                        state.document.background.color == '#FFFFFF',
                    color: Colors.white,
                    onTap: () => _select(
                      context,
                      notifier,
                      const EditorBackground(kind: EditorBackgroundKind.solid),
                    ),
                  ),
                  _BackgroundChoice(
                    icon: Icons.square_rounded,
                    label: 'Black',
                    selected:
                        state.document.background.kind ==
                            EditorBackgroundKind.solid &&
                        state.document.background.color == '#000000',
                    color: Colors.black,
                    onTap: () => _select(
                      context,
                      notifier,
                      const EditorBackground(
                        kind: EditorBackgroundKind.solid,
                        color: '#000000',
                      ),
                    ),
                  ),
                  _BackgroundChoice(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Image',
                    selected:
                        state.document.background.kind ==
                        EditorBackgroundKind.image,
                    onTap: state.isBusy
                        ? null
                        : () => _pickCustomBackground(context, notifier),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Colors', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _solidColors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final hex = _solidColors[index];
                    final selected =
                        state.document.background.kind ==
                            EditorBackgroundKind.solid &&
                        state.document.background.color == hex;
                    return Tooltip(
                      message: hex,
                      child: InkWell(
                        onTap: () => _select(
                          context,
                          notifier,
                          EditorBackground(
                            kind: EditorBackgroundKind.solid,
                            color: hex,
                          ),
                        ),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _color(hex),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: _color(hex).computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text('Gradients', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gradients.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final gradient = _gradients[index];
                    return InkWell(
                      onTap: () => _select(
                        context,
                        notifier,
                        EditorBackground(
                          kind: EditorBackgroundKind.gradient,
                          gradientStart: gradient.$1,
                          gradientEnd: gradient.$2,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 82,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                          gradient: LinearGradient(
                            colors: [_color(gradient.$1), _color(gradient.$2)],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _select(
    BuildContext context,
    AiEditorNotifier notifier,
    EditorBackground background,
  ) {
    notifier.setBackground(background);
    Navigator.pop(context);
  }

  Future<void> _pickCustomBackground(
    BuildContext context,
    AiEditorNotifier notifier,
  ) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (file == null) return;
    if (context.mounted) Navigator.pop(context);
    await notifier.uploadCustomBackground(
      bytes: await file.readAsBytes(),
      filename: file.name,
      contentType: imageContentTypeForFilename(file.name),
    );
  }
}

class _BackgroundChoice extends StatelessWidget {
  const _BackgroundChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      width: 86,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? AppColors.textPrimary),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

Color _color(String value) => Color(
  0xFF000000 | (int.tryParse(value.replaceAll('#', ''), radix: 16) ?? 0),
);
