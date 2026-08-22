/// Every action the AI editor toolbar can trigger, tagged with whether it
/// runs purely on-device or needs the server pipeline.
enum EditorTool {
  none,
  crop,
  transform,
  adjust,
  background,
  magicEraser,
  enhance,
  // Extended 12-category tools
  style,
  scene,
  colorGrading,
}

extension EditorToolServer on EditorTool {
  /// True when this tool always results in a call to the server `/ai/photo/edit`
  /// endpoint (as opposed to crop/rotate/adjust, which are local until "Apply").
  bool get isServerDriven => switch (this) {
    EditorTool.magicEraser ||
    EditorTool.enhance ||
    EditorTool.style ||
    EditorTool.scene => true,
    EditorTool.crop ||
    EditorTool.transform ||
    EditorTool.adjust ||
    EditorTool.background ||
    EditorTool.colorGrading => false,
    EditorTool.none => false,
  };
}
