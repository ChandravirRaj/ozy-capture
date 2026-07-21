import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_screenshot_capture_platform_interface_platform_interface.dart';

/// An implementation of [DesktopScreenshotCapturePlatformInterfacePlatform] that uses method channels.
class MethodChannelDesktopScreenshotCapturePlatformInterface extends DesktopScreenshotCapturePlatformInterfacePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('desktop_screenshot_capture_platform_interface');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
