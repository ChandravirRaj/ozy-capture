#include "include/desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "desktop_screenshot_capture_platform_interface_plugin.h"

void DesktopScreenshotCapturePlatformInterfacePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  desktop_screenshot_capture_platform_interface::DesktopScreenshotCapturePlatformInterfacePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
