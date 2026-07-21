import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'desktop_screenshot_capture_macos_method_channel.dart';

abstract class DesktopScreenshotCaptureMacosPlatform extends PlatformInterface {
  /// Constructs a DesktopScreenshotCaptureMacosPlatform.
  DesktopScreenshotCaptureMacosPlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopScreenshotCaptureMacosPlatform _instance = MethodChannelDesktopScreenshotCaptureMacos();

  /// The default instance of [DesktopScreenshotCaptureMacosPlatform] to use.
  ///
  /// Defaults to [MethodChannelDesktopScreenshotCaptureMacos].
  static DesktopScreenshotCaptureMacosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DesktopScreenshotCaptureMacosPlatform] when
  /// they register themselves.
  static set instance(DesktopScreenshotCaptureMacosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
