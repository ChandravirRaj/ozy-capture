#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>

#include "display_enumerator.h"
#include "screen_capture_permission_checker.h"

namespace desktop_screenshot_capture_windows {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(DesktopScreenshotCaptureWindowsPlugin, ListMonitorsReturnsArray) {
  const auto monitors = DisplayEnumerator::ListMonitors();
  EXPECT_FALSE(monitors.empty());
  EXPECT_FALSE(monitors.front().id.empty());
}

TEST(DesktopScreenshotCaptureWindowsPlugin, PermissionStatusHasPlatform) {
  const EncodableMap status = ScreenCapturePermissionChecker::PermissionStatusMap();
  const auto platform_it = status.find(EncodableValue("platform"));
  ASSERT_NE(platform_it, status.end());
  EXPECT_EQ(std::get<std::string>(platform_it->second), "windows");
}

}  // namespace test
}  // namespace desktop_screenshot_capture_windows
