#ifndef SCREEN_CAPTURE_PERMISSION_CHECKER_H_
#define SCREEN_CAPTURE_PERMISSION_CHECKER_H_

#include <flutter/encodable_value.h>

#include <string>

namespace desktop_screenshot_capture_windows {

enum class PermissionResult {
  kGranted,
  kDenied,
};

struct PermissionEvaluation {
  PermissionResult result = PermissionResult::kDenied;
  std::string guidance;
  flutter::EncodableMap diagnostics;
};

class ScreenCapturePermissionChecker {
 public:
  static PermissionEvaluation Evaluate();
  static flutter::EncodableMap PermissionStatusMap();
  static bool IsCaptureSupported();
};

}  // namespace desktop_screenshot_capture_windows

#endif  // SCREEN_CAPTURE_PERMISSION_CHECKER_H_
