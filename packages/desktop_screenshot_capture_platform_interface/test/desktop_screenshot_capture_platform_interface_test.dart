import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface.dart';
import 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface_platform_interface.dart';
import 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopScreenshotCapturePlatformInterfacePlatform
    with MockPlatformInterfaceMixin
    implements DesktopScreenshotCapturePlatformInterfacePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DesktopScreenshotCapturePlatformInterfacePlatform initialPlatform = DesktopScreenshotCapturePlatformInterfacePlatform.instance;

  test('$MethodChannelDesktopScreenshotCapturePlatformInterface is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopScreenshotCapturePlatformInterface>());
  });

  test('getPlatformVersion', () async {
    DesktopScreenshotCapturePlatformInterface desktopScreenshotCapturePlatformInterfacePlugin = DesktopScreenshotCapturePlatformInterface();
    MockDesktopScreenshotCapturePlatformInterfacePlatform fakePlatform = MockDesktopScreenshotCapturePlatformInterfacePlatform();
    DesktopScreenshotCapturePlatformInterfacePlatform.instance = fakePlatform;

    expect(await desktopScreenshotCapturePlatformInterfacePlugin.getPlatformVersion(), '42');
  });
}
