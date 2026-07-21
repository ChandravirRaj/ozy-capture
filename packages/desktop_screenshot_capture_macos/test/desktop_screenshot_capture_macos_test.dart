import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_screenshot_capture_macos/desktop_screenshot_capture_macos.dart';
import 'package:desktop_screenshot_capture_macos/desktop_screenshot_capture_macos_platform_interface.dart';
import 'package:desktop_screenshot_capture_macos/desktop_screenshot_capture_macos_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopScreenshotCaptureMacosPlatform
    with MockPlatformInterfaceMixin
    implements DesktopScreenshotCaptureMacosPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DesktopScreenshotCaptureMacosPlatform initialPlatform = DesktopScreenshotCaptureMacosPlatform.instance;

  test('$MethodChannelDesktopScreenshotCaptureMacos is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopScreenshotCaptureMacos>());
  });

  test('getPlatformVersion', () async {
    DesktopScreenshotCaptureMacos desktopScreenshotCaptureMacosPlugin = DesktopScreenshotCaptureMacos();
    MockDesktopScreenshotCaptureMacosPlatform fakePlatform = MockDesktopScreenshotCaptureMacosPlatform();
    DesktopScreenshotCaptureMacosPlatform.instance = fakePlatform;

    expect(await desktopScreenshotCaptureMacosPlugin.getPlatformVersion(), '42');
  });
}
