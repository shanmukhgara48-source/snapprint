import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/ai_editor_provider.dart';

Future<void> showStyleSheet(
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
    builder: (sheetContext) => _StyleSheet(args: args),
  );
}

Future<void> showSceneSheet(
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
    builder: (sheetContext) => _SceneSheet(args: args),
  );
}

const _artisticStyles = <_StylePreset>[
  _StylePreset('Anime', Icons.animation_rounded, 'Transform into anime style, keeping all details'),
  _StylePreset('Oil Painting', Icons.brush_rounded, 'Transform into an oil painting with visible brushstrokes'),
  _StylePreset('Watercolor', Icons.water_drop_rounded, 'Transform into a soft watercolor painting'),
  _StylePreset('Pencil Sketch', Icons.edit_rounded, 'Transform into a detailed pencil sketch drawing'),
  _StylePreset('Pop Art', Icons.palette_rounded, 'Transform into bold pop art style like Andy Warhol'),
  _StylePreset('Comic Book', Icons.auto_stories_rounded, 'Transform into a comic book illustration'),
];

const _filmStyles = <_StylePreset>[
  _StylePreset('Cinematic', Icons.movie_rounded, 'Apply cinematic color grading with dramatic tones'),
  _StylePreset('Vintage Film', Icons.camera_rounded, 'Apply vintage film look with grain and warm tones'),
  _StylePreset('Film Noir', Icons.contrast_rounded, 'Apply black and white film noir style'),
  _StylePreset('Warm Tones', Icons.wb_sunny_rounded, 'Apply warm golden tones throughout'),
  _StylePreset('Cool Tones', Icons.ac_unit_rounded, 'Apply cool blue tones throughout'),
  _StylePreset('Matte', Icons.filter_vintage_rounded, 'Apply soft matte film look with lifted blacks'),
];

const _funStyles = <_StylePreset>[
  _StylePreset('Pixar/3D', Icons.view_in_ar_rounded, 'Transform into a Pixar-style 3D character render'),
  _StylePreset('Clay/Plasticine', Icons.toys_rounded, 'Transform into claymation style'),
  _StylePreset('Lego', Icons.grid_view_rounded, 'Transform into Lego brick style'),
  _StylePreset('Minecraft', Icons.square_rounded, 'Transform into Minecraft pixel block style'),
  _StylePreset('Ghibli', Icons.park_rounded, 'Transform into Studio Ghibli anime art style'),
  _StylePreset('Cyberpunk', Icons.bolt_rounded, 'Transform into cyberpunk neon style'),
];

const _scenePresets = <_StylePreset>[
  _StylePreset('Golden Hour', Icons.wb_twilight_rounded, 'Transform to golden hour sunset lighting'),
  _StylePreset('Night', Icons.nightlight_rounded, 'Transform the scene to nighttime'),
  _StylePreset('Rainy', Icons.water_rounded, 'Add rain effect to the scene'),
  _StylePreset('Snowy', Icons.ac_unit_rounded, 'Add snow effect to the scene'),
  _StylePreset('Foggy', Icons.cloud_rounded, 'Add atmospheric fog to the scene'),
  _StylePreset('Summer', Icons.wb_sunny_rounded, 'Transform to bright summer setting'),
  _StylePreset('Autumn', Icons.eco_rounded, 'Transform to autumn with fall colors'),
  _StylePreset('Starry Sky', Icons.star_rounded, 'Add a beautiful starry night sky'),
];

class _StylePreset {
  const _StylePreset(this.label, this.icon, this.prompt);
  final String label;
  final IconData icon;
  final String prompt;
}

class _StyleSheet extends ConsumerWidget {
  const _StyleSheet({required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  'Style Transfer',
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
            const SizedBox(height: 4),
            _SectionLabel('Artistic'),
            _PresetGrid(
              presets: _artisticStyles,
              onTap: (preset) {
                Navigator.pop(context);
                notifier.applyPromptEdit(preset.prompt);
              },
            ),
            const SizedBox(height: 14),
            _SectionLabel('Film & Color'),
            _PresetGrid(
              presets: _filmStyles,
              onTap: (preset) {
                Navigator.pop(context);
                notifier.applyPromptEdit(preset.prompt);
              },
            ),
            const SizedBox(height: 14),
            _SectionLabel('Fun & Creative'),
            _PresetGrid(
              presets: _funStyles,
              onTap: (preset) {
                Navigator.pop(context);
                notifier.applyPromptEdit(preset.prompt);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneSheet extends ConsumerWidget {
  const _SceneSheet({required this.args});
  final AiPhotoEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  'Scene Transform',
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
            const SizedBox(height: 4),
            _PresetGrid(
              presets: _scenePresets,
              onTap: (preset) {
                Navigator.pop(context);
                notifier.applyPromptEdit(preset.prompt);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({required this.presets, required this.onTap});
  final List<_StylePreset> presets;
  final void Function(_StylePreset preset) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets
          .map(
            (preset) => InkWell(
              onTap: () => onTap(preset),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 100,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(preset.icon, size: 24, color: AppColors.textPrimary),
                    const SizedBox(height: 5),
                    Text(
                      preset.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
