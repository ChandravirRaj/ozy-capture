import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'desktop_screenshot_capture_platform_interface_method_channel.dart';

abstract class DesktopScreenshotCapturePlatformInterfacePlatform extends PlatformInterface {
  /// Constructs a DesktopScreenshotCapturePlatformInterfacePlatform.
  DesktopScreenshotCapturePlatformInterfacePlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopScreenshotCapturePlatformInterfacePlatform _instance = MethodChannelDesktopScreenshotCapturePlatformInterface();

  /// The default instance of [DesktopScreenshotCapturePlatformInterfacePlatform] to use.
  ///
  /// Defaults to [MethodChannelDesktopScreenshotCapturePlatformInterface].
  static DesktopScreenshotCapturePlatformInterfacePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DesktopScreenshotCapturePlatformInterfacePlatform] when
  /// they register themselves.
  static set instance(DesktopScreenshotCapturePlatformInterfacePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
