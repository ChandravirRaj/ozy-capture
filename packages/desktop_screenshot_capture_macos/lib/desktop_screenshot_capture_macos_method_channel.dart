import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_screenshot_capture_macos_platform_interface.dart';

/// An implementation of [DesktopScreenshotCaptureMacosPlatform] that uses method channels.
class MethodChannelDesktopScreenshotCaptureMacos extends DesktopScreenshotCaptureMacosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('desktop_screenshot_capture_macos');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
