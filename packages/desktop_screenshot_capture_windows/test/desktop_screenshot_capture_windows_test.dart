import 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface.dart';
import 'package:desktop_screenshot_capture_windows/desktop_screenshot_capture_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registerWith sets platform instance', () {
    DesktopScreenshotCaptureWindows.registerWith();
    expect(
      DesktopScreenshotCapturePlatform.instance,
      isA<DesktopScreenshotCaptureWindows>(),
    );
  });
}
