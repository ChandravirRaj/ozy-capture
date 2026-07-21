import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_screenshot_capture_linux/desktop_screenshot_capture_linux.dart';
import 'package:desktop_screenshot_capture_linux/desktop_screenshot_capture_linux_platform_interface.dart';
import 'package:desktop_screenshot_capture_linux/desktop_screenshot_capture_linux_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopScreenshotCaptureLinuxPlatform
    with MockPlatformInterfaceMixin
    implements DesktopScreenshotCaptureLinuxPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DesktopScreenshotCaptureLinuxPlatform initialPlatform = DesktopScreenshotCaptureLinuxPlatform.instance;

  test('$MethodChannelDesktopScreenshotCaptureLinux is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopScreenshotCaptureLinux>());
  });

  test('getPlatformVersion', () async {
    DesktopScreenshotCaptureLinux desktopScreenshotCaptureLinuxPlugin = DesktopScreenshotCaptureLinux();
    MockDesktopScreenshotCaptureLinuxPlatform fakePlatform = MockDesktopScreenshotCaptureLinuxPlatform();
    DesktopScreenshotCaptureLinuxPlatform.instance = fakePlatform;

    expect(await desktopScreenshotCaptureLinuxPlugin.getPlatformVersion(), '42');
  });
}
