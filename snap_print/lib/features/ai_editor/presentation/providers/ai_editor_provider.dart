import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/ai_editor_repository.dart';
import '../../domain/ai_editor_models.dart';
import '../../domain/editor_document.dart';
import '../../domain/editor_operation.dart';
import '../../domain/local_image_metrics.dart';
import '../../domain/prompt_edit_intent.dart';

class AiPhotoEditorArgs {
  const AiPhotoEditorArgs({
    required this.imageUrl,
    required this.productName,
    required this.selectedSize,
  });

  final String imageUrl;
  final String productName;
  final String selectedSize;

  @override
  bool operator ==(Object other) =>
      other is AiPhotoEditorArgs &&
      other.imageUrl == imageUrl &&
      other.productName == productName &&
      other.selectedSize == selectedSize;

  @override
  int get hashCode => Object.hash(imageUrl, productName, selectedSize);
}

enum EditorStatus {
  idle,
  removingBackground,
  serverProcessing,
  uploadingBackground,
  exporting,
  analyzing,
  error,
}

class AiEditorState {
  const AiEditorState({
    required this.history,
    this.cursor = 0,
    this.activeTool = EditorTool.none,
    this.status = EditorStatus.idle,
    this.compareMode = false,
    this.comparePosition = 0.5,
    this.capabilities,
    this.serverAnalysis,
    this.analyzing = false,
    this.localMetrics,
    this.adjustDraft = const EditorAdjustments(),
    this.cropDraft,
    this.straightenDraft = 0,
    this.errorMessage,
    this.loadingStatus = true,
    this.warnings = const [],
    this.lastExport,
    this.recentPrompts = const [],
    this.lastInteractionId,
  });

  final List<EditorDocument> history;
  final int cursor;
  final EditorTool activeTool;
  final EditorStatus status;
  final bool compareMode;
  final double comparePosition;
  final AiEditorCapabilities? capabilities;
  final AiPrintAnalysis? serverAnalysis;
  final bool analyzing;
  final LocalImageMetrics? localMetrics;
  final EditorAdjustments adjustDraft;
  final NormalizedRect? cropDraft;
  final double straightenDraft;
  final String? errorMessage;
  final bool loadingStatus;
  final List<String> warnings;
  final AiExportResult? lastExport;
  final List<String> recentPrompts;
  final String? lastInteractionId;

  EditorDocument get document => history[cursor];
  String get currentUrl => document.workingImageUrl;
  String get originalUrl => history.first.sourceUrl;
  bool get canUndo => cursor > 0;
  bool get canRedo => cursor < history.length - 1;
  bool get enabled => capabilities?.enabled ?? false;
  bool get backgroundRemovalAvailable =>
      capabilities?.backgroundRemoval ?? false;
  bool get isBusy =>
      status != EditorStatus.idle && status != EditorStatus.error;
  LocalImageMetrics? get outputMetrics {
    final metrics = localMetrics;
    if (metrics == null) return null;
    final crop = document.transform.crop;
    var width = crop == null
        ? metrics.width
        : (metrics.width * crop.width).round();
    var height = crop == null
        ? metrics.height
        : (metrics.height * crop.height).round();
    if (document.transform.rotationQuarterTurns.isOdd) {
      final swap = width;
      width = height;
      height = swap;
    }
    return LocalImageMetrics(
      width: width,
      height: height,
      fileSizeBytes: metrics.fileSizeBytes,
    );
  }

  AiEditorState copyWith({
    List<EditorDocument>? history,
    int? cursor,
    EditorTool? activeTool,
    EditorStatus? status,
    bool? compareMode,
    double? comparePosition,
    AiEditorCapabilities? capabilities,
    AiPrintAnalysis? serverAnalysis,
    bool? analyzing,
    LocalImageMetrics? localMetrics,
    EditorAdjustments? adjustDraft,
    NormalizedRect? Function()? cropDraft,
    double? straightenDraft,
    String? Function()? errorMessage,
    bool? loadingStatus,
    List<String>? warnings,
    AiExportResult? lastExport,
    List<String>? recentPrompts,
    String? Function()? lastInteractionId,
  }) => AiEditorState(
    history: history ?? this.history,
    cursor: cursor ?? this.cursor,
    activeTool: activeTool ?? this.activeTool,
    status: status ?? this.status,
    compareMode: compareMode ?? this.compareMode,
    comparePosition: comparePosition ?? this.comparePosition,
    capabilities: capabilities ?? this.capabilities,
    serverAnalysis: serverAnalysis ?? this.serverAnalysis,
    analyzing: analyzing ?? this.analyzing,
    localMetrics: localMetrics ?? this.localMetrics,
    adjustDraft: adjustDraft ?? this.adjustDraft,
    cropDraft: cropDraft != null ? cropDraft() : this.cropDraft,
    straightenDraft: straightenDraft ?? this.straightenDraft,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    loadingStatus: loadingStatus ?? this.loadingStatus,
    warnings: warnings ?? this.warnings,
    lastExport: lastExport ?? this.lastExport,
    recentPrompts: recentPrompts ?? this.recentPrompts,
    lastInteractionId: lastInteractionId != null
        ? lastInteractionId()
        : this.lastInteractionId,
  );
}

class AiEditorNotifier
    extends AutoDisposeFamilyNotifier<AiEditorState, AiPhotoEditorArgs> {
  late AiPhotoEditorArgs _args;
  bool _disposed = false;
  int _generation = 0;

  AiEditorRepository get _repo => ref.read(aiEditorRepositoryProvider);
  String get _draftKey => 'ai_editor_v2_${_args.imageUrl.hashCode}';
  String get _recentPromptsKey => 'ai_editor_recent_prompts';

  @override
  AiEditorState build(AiPhotoEditorArgs arg) {
    _args = arg;
    ref.onDispose(() => _disposed = true);
    final initial = AiEditorState(
      history: [EditorDocument(sourceUrl: arg.imageUrl)],
    );
    Future.microtask(() {
      unawaited(_restoreDraft());
      unawaited(_loadRecentPrompts());
      unawaited(_loadCapabilities());
      unawaited(_analyze());
      unawaited(_loadLocalMetrics());
    });
    return initial;
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (_disposed || raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final history = (json['history'] as List<dynamic>)
          .map(
            (entry) => EditorDocument.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
      if (history.isEmpty ||
          history.first.sourceUrl != _args.imageUrl ||
          _disposed) {
        return;
      }
      final cursor = ((json['cursor'] as num?)?.toInt() ?? history.length - 1)
          .clamp(0, history.length - 1)
          .toInt();
      state = state.copyWith(history: history, cursor: cursor);
      unawaited(_loadLocalMetrics());
    } catch (_) {
      await prefs.remove(_draftKey);
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey,
      jsonEncode({
        'version': 2,
        'cursor': state.cursor,
        'history': state.history.map((entry) => entry.toJson()).toList(),
      }),
    );
  }

  Future<void> _loadRecentPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final prompts = prefs.getStringList(_recentPromptsKey) ?? const [];
    if (_disposed) return;
    state = state.copyWith(recentPrompts: prompts);
  }

  Future<void> _rememberPrompt(String prompt) async {
    final normalized = prompt.trim();
    if (normalized.isEmpty) return;
    final prompts = <String>[
      normalized,
      ...state.recentPrompts.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(8).toList();
    state = state.copyWith(recentPrompts: prompts);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentPromptsKey, prompts);
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities = await _repo.capabilities();
      if (_disposed) return;
      state = state.copyWith(capabilities: capabilities, loadingStatus: false);
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(loadingStatus: false);
    }
  }

  Future<void> _analyze() async {
    if (_disposed) return;
    state = state.copyWith(analyzing: true);
    try {
      final analysis = await _repo.analyze(
        imageUrl: state.document.sourceUrl,
        productName: _args.productName,
        selectedSize: _args.selectedSize,
      );
      if (_disposed) return;
      state = state.copyWith(serverAnalysis: analysis, analyzing: false);
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(analyzing: false);
    }
  }

  Future<void> _loadLocalMetrics() async {
    try {
      final metrics = await _repo.computeLocalMetrics(state.currentUrl);
      if (_disposed) return;
      final current = state.document;
      if (current.sourceWidth == null || current.sourceHeight == null) {
        final history = [...state.history];
        history[state.cursor] = current.copyWith(
          sourceWidth: metrics.width,
          sourceHeight: metrics.height,
        );
        state = state.copyWith(history: history, localMetrics: metrics);
      } else {
        state = state.copyWith(localMetrics: metrics);
      }
    } catch (_) {
      // Print analysis remains available from the backend when local decode fails.
    }
  }

  void _push(EditorDocument document) {
    var history = state.history.sublist(0, state.cursor + 1);
    history = [...history, document];
    if (history.length > 20) history = history.sublist(history.length - 20);
    state = state.copyWith(
      history: history,
      cursor: history.length - 1,
      activeTool: EditorTool.none,
      compareMode: false,
      adjustDraft: document.adjustments,
      cropDraft: () => document.transform.crop,
      straightenDraft: document.transform.straightenDegrees,
    );
    unawaited(_saveDraft());
  }

  void undo() {
    if (!state.canUndo || state.isBusy) return;
    final cursor = state.cursor - 1;
    final document = state.history[cursor];
    state = state.copyWith(
      cursor: cursor,
      adjustDraft: document.adjustments,
      cropDraft: () => document.transform.crop,
      straightenDraft: document.transform.straightenDegrees,
    );
    unawaited(_saveDraft());
  }

  void redo() {
    if (!state.canRedo || state.isBusy) return;
    final cursor = state.cursor + 1;
    final document = state.history[cursor];
    state = state.copyWith(
      cursor: cursor,
      adjustDraft: document.adjustments,
      cropDraft: () => document.transform.crop,
      straightenDraft: document.transform.straightenDegrees,
    );
    unawaited(_saveDraft());
  }

  void reset() {
    if (state.isBusy || state.history.length == 1) return;
    final metrics = state.localMetrics;
    state = state.copyWith(
      history: [
        EditorDocument(
          sourceUrl: _args.imageUrl,
          sourceWidth: metrics?.width,
          sourceHeight: metrics?.height,
        ),
      ],
      cursor: 0,
      activeTool: EditorTool.none,
      compareMode: false,
      adjustDraft: const EditorAdjustments(),
      cropDraft: () => null,
      straightenDraft: 0,
      warnings: const [],
      lastInteractionId: () => null,
    );
    unawaited(_saveDraft());
  }

  void setActiveTool(EditorTool tool) {
    if (state.isBusy) return;
    state = state.copyWith(
      activeTool: state.activeTool == tool ? EditorTool.none : tool,
      adjustDraft: state.document.adjustments,
      cropDraft: () => state.document.transform.crop,
      straightenDraft: state.document.transform.straightenDegrees,
    );
  }

  void toggleCompare() =>
      state = state.copyWith(compareMode: !state.compareMode);

  void setComparePosition(double value) =>
      state = state.copyWith(comparePosition: value.clamp(0, 1));

  void dismissError() => state = state.copyWith(
    status: EditorStatus.idle,
    errorMessage: () => null,
  );

  void cancelGeneration() {
    if (!state.isBusy) return;
    _generation++;
    state = state.copyWith(status: EditorStatus.idle);
  }

  Future<void> applyPromptEdit(
    String prompt, {
    bool rightsConfirmed = false,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || state.isBusy) return;
    final intent = classifyPromptEdit(trimmed);
    await _rememberPrompt(trimmed);

    switch (intent.execution) {
      case PromptEditExecution.localAdjustment:
        final adjustments = intent.localAdjustments;
        if (adjustments == null) return;
        _push(state.document.copyWith(adjustments: adjustments));
        return;
      case PromptEditExecution.localTransform:
        if (intent.operation == 'rotate') {
          rotateClockwise();
        } else {
          flipHorizontal();
        }
        return;
      case PromptEditExecution.backgroundRemoval:
        await removeBackground();
        return;
      case PromptEditExecution.server:
        await _runPromptOnServer(
          prompt: trimmed,
          intent: intent,
          rightsConfirmed: rightsConfirmed,
        );
        return;
    }
  }

  Future<void> removeBackground() async {
    if (!state.backgroundRemovalAvailable || state.isBusy) return;
    final generation = ++_generation;
    state = state.copyWith(
      status: EditorStatus.removingBackground,
      errorMessage: () => null,
    );
    try {
      final result = await _repo.removeBackground(state.document.sourceUrl);
      if (_disposed || generation != _generation) return;
      final next = state.document.copyWith(
        foregroundUrl: result.foregroundUrl,
        sourceWidth: result.width,
        sourceHeight: result.height,
        subjectBounds: result.subjectBounds,
      );
      state = state.copyWith(
        status: EditorStatus.idle,
        warnings: result.warnings,
      );
      _push(next);
      unawaited(_loadLocalMetrics());
    } catch (error) {
      _fail(error, generation);
    }
  }

  Future<void> _runPromptOnServer({
    required String prompt,
    required PromptEditIntent intent,
    required bool rightsConfirmed,
  }) async {
    if (state.capabilities?.generativeEditing != true) {
      state = state.copyWith(
        status: EditorStatus.error,
        errorMessage: () => 'AI prompt editing is not configured yet.',
      );
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(
      status: EditorStatus.serverProcessing,
      errorMessage: () => null,
    );
    try {
      final result = await _repo.editOnServer(
        imageUrl: state.document.workingImageUrl,
        operation: intent.operation,
        productName: _args.productName,
        selectedSize: _args.selectedSize,
        prompt: prompt,
        previousInteractionId: state.lastInteractionId,
        rightsConfirmed: rightsConfirmed,
      );
      if (_disposed || generation != _generation) return;
      state = state.copyWith(
        status: EditorStatus.idle,
        lastInteractionId: () => result.interactionId,
        warnings: result.summary.isEmpty ? const [] : [result.summary],
      );
      _push(
        EditorDocument(
          sourceUrl: result.editedImageUrl,
          sourceWidth: state.document.sourceWidth,
          sourceHeight: state.document.sourceHeight,
        ),
      );
      unawaited(_loadLocalMetrics());
    } catch (error) {
      _fail(error, generation);
    }
  }

  void setBackground(EditorBackground background) {
    if (!state.document.hasCutout) {
      state = state.copyWith(
        status: EditorStatus.error,
        errorMessage: () => 'Remove the background before choosing a new one.',
      );
      return;
    }
    _push(state.document.copyWith(background: background));
  }

  Future<void> uploadCustomBackground({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    if (state.isBusy) return;
    final generation = ++_generation;
    state = state.copyWith(status: EditorStatus.uploadingBackground);
    try {
      final url = await _repo.uploadCustomBackground(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
      if (_disposed || generation != _generation) return;
      state = state.copyWith(status: EditorStatus.idle);
      setBackground(
        EditorBackground(kind: EditorBackgroundKind.image, imageUrl: url),
      );
    } catch (error) {
      _fail(error, generation);
    }
  }

  void setAdjustDraft(EditorAdjustments values) =>
      state = state.copyWith(adjustDraft: values);

  void applyAdjustments() {
    if (state.isBusy) return;
    _push(state.document.copyWith(adjustments: state.adjustDraft));
  }

  void setCropDraft(NormalizedRect rect) =>
      state = state.copyWith(cropDraft: () => rect);

  void applyCrop() {
    final crop = state.cropDraft;
    if (crop == null || state.isBusy) return;
    _push(
      state.document.copyWith(
        transform: state.document.transform.copyWith(crop: () => crop),
      ),
    );
  }

  void rotateClockwise() {
    final transform = state.document.transform;
    _push(
      state.document.copyWith(
        transform: transform.copyWith(
          rotationQuarterTurns: (transform.rotationQuarterTurns + 1) % 4,
        ),
      ),
    );
  }

  void flipHorizontal() => _push(
    state.document.copyWith(
      transform: state.document.transform.copyWith(
        flipHorizontal: !state.document.transform.flipHorizontal,
      ),
    ),
  );

  void flipVertical() => _push(
    state.document.copyWith(
      transform: state.document.transform.copyWith(
        flipVertical: !state.document.transform.flipVertical,
      ),
    ),
  );

  void setStraightenDraft(double value) =>
      state = state.copyWith(straightenDraft: value.clamp(-15, 15));

  void applyStraighten() => _push(
    state.document.copyWith(
      transform: state.document.transform.copyWith(
        straightenDegrees: state.straightenDraft,
      ),
    ),
  );

  void autoCrop() {
    final bounds = state.document.subjectBounds;
    if (bounds == null) {
      state = state.copyWith(
        status: EditorStatus.error,
        errorMessage: () =>
            'Remove the background to detect and frame the subject first.',
      );
      return;
    }
    final ratio = _sizeRatio(_args.selectedSize);
    final sourceAspect =
        (state.document.sourceWidth ?? 1) /
        (state.document.sourceHeight ?? 1).clamp(1, 1 << 30);
    _push(
      state.document.copyWith(
        transform: state.document.transform.copyWith(
          crop: () => _cropAroundSubject(bounds, ratio, sourceAspect),
        ),
      ),
    );
  }

  void smartCenter() {
    final bounds = state.document.subjectBounds;
    if (bounds == null) {
      state = state.copyWith(
        status: EditorStatus.error,
        errorMessage: () =>
            'Remove the background to detect and center the subject first.',
      );
      return;
    }
    final right = bounds.left + bounds.width;
    final bottom = bounds.top + bounds.height;
    final offsetX = (0.5 - (bounds.left + bounds.width / 2)).clamp(
      -bounds.left,
      1 - right,
    );
    final offsetY = (0.5 - (bounds.top + bounds.height / 2)).clamp(
      -bounds.top,
      1 - bottom,
    );
    _push(
      state.document.copyWith(
        transform: state.document.transform.copyWith(
          crop: () => null,
          offsetX: offsetX,
          offsetY: offsetY,
        ),
      ),
    );
  }

  Future<AiExportResult?> exportCurrent() async {
    if (state.isBusy) return null;
    final generation = ++_generation;
    state = state.copyWith(
      status: EditorStatus.exporting,
      errorMessage: () => null,
    );
    try {
      final result = await _repo.export(
        document: state.document,
        selectedSize: _args.selectedSize,
      );
      if (_disposed || generation != _generation) return null;
      state = state.copyWith(
        status: EditorStatus.idle,
        lastExport: result,
        warnings: result.warnings,
      );
      return result;
    } catch (error) {
      _fail(error, generation);
      return null;
    }
  }

  void _fail(Object error, int generation) {
    if (_disposed || generation != _generation) return;
    state = state.copyWith(
      status: EditorStatus.error,
      errorMessage: () => _repo.friendlyError(error),
    );
  }
}

double? _sizeRatio(String selectedSize) {
  final match = RegExp(
    r'(\d+(?:\.\d+)?)\s*[x×]\s*(\d+(?:\.\d+)?)',
    caseSensitive: false,
  ).firstMatch(selectedSize);
  if (match == null) return null;
  final width = double.tryParse(match.group(1)!);
  final height = double.tryParse(match.group(2)!);
  if (width == null || height == null || width <= 0 || height <= 0) return null;
  return width / height;
}

NormalizedRect _cropAroundSubject(
  NormalizedRect subject,
  double? targetRatio,
  double sourceAspect,
) {
  const padding = 0.08;
  var left = (subject.left - padding).clamp(0.0, 1.0);
  var top = (subject.top - padding).clamp(0.0, 1.0);
  var width = (subject.width + padding * 2).clamp(0.05, 1.0 - left);
  var height = (subject.height + padding * 2).clamp(0.05, 1.0 - top);
  if (targetRatio != null) {
    final normalizedTarget = targetRatio / sourceAspect;
    final current = width / height;
    if (current < normalizedTarget) {
      final desired = (height * normalizedTarget).clamp(width, 1.0);
      left = (left - (desired - width) / 2).clamp(0.0, 1.0 - desired);
      width = desired;
    } else {
      final desired = (width / normalizedTarget).clamp(height, 1.0);
      top = (top - (desired - height) / 2).clamp(0.0, 1.0 - desired);
      height = desired;
    }
  }
  return NormalizedRect(left: left, top: top, width: width, height: height);
}

final aiEditorProvider = NotifierProvider.autoDispose
    .family<AiEditorNotifier, AiEditorState, AiPhotoEditorArgs>(
      AiEditorNotifier.new,
    );
