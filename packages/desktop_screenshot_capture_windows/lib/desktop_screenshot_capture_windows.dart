import 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface.dart';

import 'package:desktop_screenshot_capture_platform_interface/src/method_channel_capture.dart';

class DesktopScreenshotCaptureWindows extends MethodChannelDesktopScreenshotCapture {
  static void registerWith() {
    DesktopScreenshotCapturePlatform.instance = DesktopScreenshotCaptureWindows();
  }
}
