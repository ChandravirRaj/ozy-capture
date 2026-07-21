#ifndef FLUTTER_PLUGIN_DESKTOP_SCREENSHOT_CAPTURE_PLATFORM_INTERFACE_PLUGIN_H_
#define FLUTTER_PLUGIN_DESKTOP_SCREENSHOT_CAPTURE_PLATFORM_INTERFACE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace desktop_screenshot_capture_platform_interface {

class DesktopScreenshotCapturePlatformInterfacePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DesktopScreenshotCapturePlatformInterfacePlugin();

  virtual ~DesktopScreenshotCapturePlatformInterfacePlugin();

  // Disallow copy and assign.
  DesktopScreenshotCapturePlatformInterfacePlugin(const DesktopScreenshotCapturePlatformInterfacePlugin&) = delete;
  DesktopScreenshotCapturePlatformInterfacePlugin& operator=(const DesktopScreenshotCapturePlatformInterfacePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace desktop_screenshot_capture_platform_interface

#endif  // FLUTTER_PLUGIN_DESKTOP_SCREENSHOT_CAPTURE_PLATFORM_INTERFACE_PLUGIN_H_
