import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/error_snackbar.dart';
import 'doodle_canvas.dart';
import 'gemini_image_service.dart';

class _QuickAction {
  const _QuickAction(this.label, this.prompt);
  final String label;
  final String prompt;
}

const _quickActions = <_QuickAction>[
  _QuickAction('Black & White', 'Convert this image to black and white'),
  _QuickAction('Blur background', 'Blur background'),
  _QuickAction('Change background', 'Change background'),
  _QuickAction('Cartoon / animated style', 'Cartoon / animated style'),
  _QuickAction('Enhance / sharpen', 'Enhance / sharpen'),
];

const _maxHistory = 3;
const _generateCooldown = Duration(milliseconds: 800);

/// Self-contained AI photo editor. Give it a picked photo, it returns the
/// edited version via Navigator.pop(context, XFile) — same pattern the
/// existing image picker flow already uses. Doesn't touch any other
/// screen's state.
class AiPhotoEditScreen extends ConsumerStatefulWidget {
  const AiPhotoEditScreen({super.key, required this.imageFile});
  final XFile imageFile;

  @override
  ConsumerState<AiPhotoEditScreen> createState() => _AiPhotoEditScreenState();
}

class _AiPhotoEditScreenState extends ConsumerState<AiPhotoEditScreen> {
  GeminiImageService get _service => ref.read(geminiImageServiceProvider);
  final _promptController = TextEditingController();
  final _doodleKey = GlobalKey<DoodleCanvasState>();

  Uint8List? _originalBytes;
  String _mimeType = 'image/jpeg';

  Uint8List? _resultBytes;
  final List<Uint8List> _history = [];

  bool _loadingOriginal = true;
  bool _isGenerating = false;
  bool _doodleMode = false;
  bool _continueEditing = false;
  bool _saving = false;
  bool _saved = false;
  String? _error;
  DateTime? _lastGenerateAt;

  @override
  void initState() {
    super.initState();
    _loadOriginal();
  }

  Future<void> _loadOriginal() async {
    final bytes = await widget.imageFile.readAsBytes();
    final name = widget.imageFile.name.toLowerCase();
    final mime = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    if (!mounted) return;
    setState(() {
      _originalBytes = bytes;
      _mimeType = mime;
      _loadingOriginal = false;
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Uint8List get _displayedBytes => _resultBytes ?? _originalBytes!;

  Future<void> _generate({String? presetPrompt}) async {
    final prompt = (presetPrompt ?? _promptController.text).trim();
    if (prompt.isEmpty) {
      setState(
        () => _error =
            'Describe how you want to change this photo, or tap a quick action.',
      );
      return;
    }
    final now = DateTime.now();
    if (_isGenerating ||
        (_lastGenerateAt != null &&
            now.difference(_lastGenerateAt!) < _generateCooldown)) {
      return; // debounce rapid double-taps
    }
    _lastGenerateAt = now;

    if (presetPrompt != null) {
      _promptController.text = presetPrompt;
    }

    Uint8List? doodleBytes;
    if (_doodleMode) {
      // TODO(ai-photo-edit): doodle mask is exported at the on-screen preview
      // size while the base image sent below is full original resolution —
      // the two don't spatially align, so the "constrained region" isn't
      // actually constrained. Needs a single composited export instead.
      doodleBytes = await _doodleKey.currentState?.exportPng();
    }

    final baseBytes = (_continueEditing && _resultBytes != null)
        ? _resultBytes!
        : _originalBytes!;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final edited = await _service.editImage(
        imageBytes: baseBytes,
        imageMimeType: _mimeType,
        prompt: prompt,
        doodleBytes: doodleBytes,
      );
      if (!mounted) return;
      setState(() {
        if (_resultBytes != null) {
          _history.insert(0, _resultBytes!);
          if (_history.length > _maxHistory) _history.removeLast();
        }
        _resultBytes = edited;
        _mimeType = 'image/png';
        _doodleMode = false;
        _doodleKey.currentState?.clear();
        _saved = false;
      });
    } on GeminiImageException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        showErrorSnackbar(context, e.message);
      }
    } catch (_) {
      const message = "Couldn't generate that edit, try again.";
      if (mounted) {
        setState(() => _error = message);
        showErrorSnackbar(context, message);
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _tryAgain() {
    setState(() {
      _resultBytes = null;
      _continueEditing = false;
      _error = null;
    });
  }

  void _selectHistoryVersion(Uint8List bytes) {
    setState(() {
      if (_resultBytes != null && _resultBytes != bytes) {
        _history.remove(bytes);
        _history.insert(0, _resultBytes!);
        if (_history.length > _maxHistory) _history.removeLast();
      }
      _resultBytes = bytes;
      _saved = false;
    });
  }

  void _accept() {
    final bytes = _resultBytes;
    if (bytes == null) return;
    final file = XFile.fromData(
      bytes,
      name: 'ai_edited.png',
      mimeType: 'image/png',
    );
    Navigator.pop(context, file);
  }

  // TODO(ai-photo-edit): Storage upload and Firestore write below aren't
  // atomic — if the app dies between them, an orphaned file can be left in
  // Storage with no matching ai_edited_photos doc.
  Future<void> _saveToAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    final bytes = _resultBytes;
    if (user == null || bytes == null || _saving) return;
    setState(() => _saving = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'ai_edited_photos/${user.uid}/${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('ai_edited_photos').add({
        'userId': user.uid,
        'imageUrl': url,
        'prompt': _promptController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't save that photo, try again.");
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFF9B72CB),
                  Color(0xFFD96570),
                ],
              ).createShader(bounds),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('Edit with Gemini AI'),
          ],
        ),
      ),
      body: _loadingOriginal
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageArea(),
                          if (_history.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildHistoryStrip(),
                          ],
                          const SizedBox(height: 16),
                          if (_resultBytes == null) ...[
                            _buildPromptArea(),
                          ] else ...[
                            _buildResultActions(),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _resultBytes == null
                          ? CustomButton(
                              label: 'Generate',
                              icon: Icons.auto_awesome,
                              isLoading: _isGenerating,
                              onPressed: () => _generate(),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    label: 'Try again',
                                    isOutlined: true,
                                    onPressed: _isGenerating ? null : _tryAgain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomButton(
                                    label: 'Accept',
                                    icon: Icons.check,
                                    onPressed: _accept,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 320.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.memory(
                _displayedBytes,
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
              if (_doodleMode && _resultBytes == null)
                DoodleCanvas(key: _doodleKey, width: width, height: height),
              if (_isGenerating)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryStrip() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _history.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final bytes = _history[i];
          return GestureDetector(
            onTap: () => _selectHistoryVersion(bytes),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromptArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe how you want to change this photo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _promptController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g. add a snowy background',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickActions
              .map(
                (action) => ActionChip(
                  label: Text(action.label),
                  onPressed: _isGenerating
                      ? null
                      : () => _generate(presetPrompt: action.prompt),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        FilterChip(
          label: const Text('Doodle: mark an area to edit'),
          avatar: const Icon(Icons.brush, size: 18),
          selected: _doodleMode,
          onSelected: (v) => setState(() => _doodleMode = v),
        ),
        if (_doodleMode) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _doodleKey.currentState?.clear(),
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear doodle'),
          ),
        ],
      ],
    );
  }

  Widget _buildResultActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _continueEditing,
          onChanged: (v) => setState(() => _continueEditing = v ?? false),
          title: const Text(
            'Continue editing this result',
            style: TextStyle(fontSize: 14),
          ),
        ),
        TextField(
          controller: _promptController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Describe the next change…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isGenerating ? null : () => _generate(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Regenerate with this prompt'),
          ),
        ),
        if (FirebaseAuth.instance.currentUser != null) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _saving || _saved ? null : _saveToAccount,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_saved ? Icons.check : Icons.save_outlined, size: 18),
            label: Text(_saved ? 'Saved to your account' : 'Save to my photos'),
          ),
        ],
      ],
    );
  }
}
