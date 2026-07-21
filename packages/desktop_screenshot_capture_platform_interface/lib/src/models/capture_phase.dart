enum CapturePhase {
  idle,
  requestingPermission,
  selectingSource,
  ready,
  capturing,
  stopping,
  completed,
  failed,
  permissionRevoked,
  sourceDisconnected,
}

enum ScreenshotFormat {
  jpeg,
  png;

  String get fileExtension => this == ScreenshotFormat.jpeg ? 'jpg' : 'png';

  String get channelName => name;

  static ScreenshotFormat fromChannelName(String value) {
    return ScreenshotFormat.values.byName(value);
  }
}
