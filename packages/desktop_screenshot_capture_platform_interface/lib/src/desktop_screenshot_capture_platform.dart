import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/capture_event.dart';
import 'models/capture_session.dart';
import 'models/capture_source.dart';
import 'models/capture_phase.dart';
import 'models/permission_status.dart';
import 'models/screenshot_result.dart';

abstract class DesktopScreenshotCapturePlatform extends PlatformInterface {
  DesktopScreenshotCapturePlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopScreenshotCapturePlatform _instance =
      _MissingImplementationPlatform();

  static DesktopScreenshotCapturePlatform get instance => _instance;

  static set instance(DesktopScreenshotCapturePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<PermissionStatus> getPermissionStatus();

  Future<List<CaptureSource>> listMonitors();

  Future<CaptureSource?> selectMonitor({CaptureSource? source});

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

class _MissingImplementationPlatform extends DesktopScreenshotCapturePlatform {
  Never _unsupported() => throw UnsupportedError(
        'DesktopScreenshotCapturePlatform has not been configured.',
      );

  @override
  Future<void> dispose() => _unsupported();

  @override
  Future<PermissionStatus> getPermissionStatus() => _unsupported();

  @override
  Future<List<CaptureSource>> listMonitors() => _unsupported();

  @override
  Future<CaptureSession> prepareCapture({
    required CaptureSource source,
    required String sessionId,
  }) =>
      _unsupported();

  @override
  Future<CaptureSource?> selectMonitor({CaptureSource? source}) =>
      _unsupported();

  @override
  Future<void> stopCapture(String sessionId) => _unsupported();

  @override
  Future<ScreenshotResult> takeScreenshot({
    required String sessionId,
    required String outputPath,
    required ScreenshotFormat format,
    required int quality,
  }) =>
      _unsupported();

  @override
  Stream<CaptureEvent> watchEvents() => _unsupported();
}
