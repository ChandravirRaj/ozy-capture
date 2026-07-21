#include "include/desktop_screenshot_capture_windows/desktop_screenshot_capture_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "desktop_screenshot_capture_windows_plugin.h"

void DesktopScreenshotCaptureWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  desktop_screenshot_capture_windows::DesktopScreenshotCaptureWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
