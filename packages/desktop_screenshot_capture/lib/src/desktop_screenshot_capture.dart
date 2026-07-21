import 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface.dart';

import 'mock_screenshot_capture.dart';

abstract interface class DesktopScreenshotCapture {
  Future<PermissionStatus> getPermissionStatus();

  Future<List<CaptureSource>> listMonitors();

  Future<CaptureSource?> selectMonitor();

  Future<CaptureSession> prepareCapture({
    required CaptureSource source,
    required String sessionId,
  });

  Future<ScreenshotResult> takeScreenshot({
    required String sessionId,
    required String outputPath,
    required ScreenshotFormat format,
    required int quality,
  });

  Future<void> stopCapture(String sessionId);

  Stream<CaptureEvent> watchEvents();

  Future<void> dispose();
}

class PlatformDesktopScreenshotCapture implements DesktopScreenshotCapture {
  PlatformDesktopScreenshotCapture({
    DesktopScreenshotCapturePlatform? platform,
  }) : _platform = platform ?? DesktopScreenshotCapturePlatform.instance;

  final DesktopScreenshotCapturePlatform _platform;

  @override
  Future<void> dispose() => _platform.dispose();

  @override
  Future<PermissionStatus> getPermissionStatus() =>
      _platform.getPermissionStatus();

  @override
  Future<List<CaptureSource>> listMonitors() => _platform.listMonitors();

  @override
  Future<CaptureSession> prepareCapture({
    required CaptureSource source,
    required String sessionId,
  }) =>
      _platform.prepareCapture(source: source, sessionId: sessionId);

  @override
  Future<CaptureSource?> selectMonitor() => _platform.selectMonitor();

  @override
  Future<void> stopCapture(String sessionId) =>
      _platform.stopCapture(sessionId);

  @override
  Future<ScreenshotResult> takeScreenshot({
    required String sessionId,
    required String outputPath,
    required ScreenshotFormat format,
    required int quality,
  }) =>
      _platform.takeScreenshot(
        sessionId: sessionId,
        outputPath: outputPath,
        format: format,
        quality: quality,
      );

  @override
  Stream<CaptureEvent> watchEvents() => _platform.watchEvents();
}

DesktopScreenshotCapture createDesktopScreenshotCapture({
  bool useMock = false,
}) {
  const mockFlag = bool.fromEnvironment('USE_MOCK_CAPTURE');
  if (useMock || mockFlag) {
    return MockScreenshotCapture();
  }
  return PlatformDesktopScreenshotCapture();
}
