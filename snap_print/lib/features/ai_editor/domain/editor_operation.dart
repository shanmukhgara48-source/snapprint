/// Every action the AI editor toolbar can trigger, tagged with whether it
/// runs purely on-device or needs the Gemini-backed server pipeline.
///
/// Adding a future AI provider (Phase 3: object removal, upscaling, etc.)
/// only means branching on [serverOperationKey] inside
/// `AiEditorRepository` — nothing here, in the notifier, or in the toolbar
/// needs to change.
enum EditorTool {
  none,
  crop,
  transform,
  adjust,
  background,
  magicEraser,
  enhance,
}

extension EditorToolServer on EditorTool {
  /// True when this tool always results in a call to the server `/ai/photo/edit`
  /// endpoint (as opposed to crop/rotate/adjust, which are local until "Apply").
  bool get isServerDriven => switch (this) {
    EditorTool.magicEraser || EditorTool.enhance => true,
    EditorTool.crop ||
    EditorTool.transform ||
    EditorTool.adjust ||
    EditorTool.background => false,
    EditorTool.none => false,
  };
}
