import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'desktop_screenshot_capture_windows_method_channel.dart';

abstract class DesktopScreenshotCaptureWindowsPlatform extends PlatformInterface {
  /// Constructs a DesktopScreenshotCaptureWindowsPlatform.
  DesktopScreenshotCaptureWindowsPlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopScreenshotCaptureWindowsPlatform _instance = MethodChannelDesktopScreenshotCaptureWindows();

  /// The default instance of [DesktopScreenshotCaptureWindowsPlatform] to use.
  ///
  /// Defaults to [MethodChannelDesktopScreenshotCaptureWindows].
  static DesktopScreenshotCaptureWindowsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DesktopScreenshotCaptureWindowsPlatform] when
  /// they register themselves.
  static set instance(DesktopScreenshotCaptureWindowsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
