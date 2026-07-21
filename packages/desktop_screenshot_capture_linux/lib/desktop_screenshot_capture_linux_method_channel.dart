import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_screenshot_capture_linux_platform_interface.dart';

/// An implementation of [DesktopScreenshotCaptureLinuxPlatform] that uses method channels.
class MethodChannelDesktopScreenshotCaptureLinux extends DesktopScreenshotCaptureLinuxPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('desktop_screenshot_capture_linux');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
