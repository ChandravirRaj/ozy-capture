import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'desktop_screenshot_capture_linux_method_channel.dart';

abstract class DesktopScreenshotCaptureLinuxPlatform extends PlatformInterface {
  /// Constructs a DesktopScreenshotCaptureLinuxPlatform.
  DesktopScreenshotCaptureLinuxPlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopScreenshotCaptureLinuxPlatform _instance = MethodChannelDesktopScreenshotCaptureLinux();

  /// The default instance of [DesktopScreenshotCaptureLinuxPlatform] to use.
  ///
  /// Defaults to [MethodChannelDesktopScreenshotCaptureLinux].
  static DesktopScreenshotCaptureLinuxPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DesktopScreenshotCaptureLinuxPlatform] when
  /// they register themselves.
  static set instance(DesktopScreenshotCaptureLinuxPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
