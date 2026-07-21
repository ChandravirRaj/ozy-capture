import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_screenshot_capture_windows_platform_interface.dart';

/// An implementation of [DesktopScreenshotCaptureWindowsPlatform] that uses method channels.
class MethodChannelDesktopScreenshotCaptureWindows extends DesktopScreenshotCaptureWindowsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('desktop_screenshot_capture_windows');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
