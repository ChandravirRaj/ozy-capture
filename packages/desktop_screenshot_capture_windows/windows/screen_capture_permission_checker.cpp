#include "screen_capture_permission_checker.h"

#include "d3d_capture_helpers.h"
#include "display_enumerator.h"

#include <windows.h>
#include <winrt/base.h>
#include <winrt/Windows.Graphics.Capture.h>

namespace desktop_screenshot_capture_windows {

namespace {

constexpr const char* kDeniedGuidance =
    "Screen capture is unavailable. Ensure you are running Windows 10 version "
    "2004 or later with a supported GPU, and check Windows privacy settings for "
    "screenshots and screen recording.";

flutter::EncodableMap BaseDiagnostics() {
  flutter::EncodableMap diagnostics;
  diagnostics[flutter::EncodableValue("isSupported")] =
      flutter::EncodableValue(IsCaptureSupported());

  OSVERSIONINFOEXW version_info = {};
  version_info.dwOSVersionInfoSize = sizeof(version_info);
#pragma warning(push)
#pragma warning(disable : 4996)
  if (GetVersionExW(reinterpret_cast<OSVERSIONINFOW*>(&version_info))) {
#pragma warning(pop)
    diagnostics[flutter::EncodableValue("buildNumber")] =
        flutter::EncodableValue(static_cast<int>(version_info.dwBuildNumber));
  }
  return diagnostics;
}

}  // namespace

bool ScreenCapturePermissionChecker::IsCaptureSupported() {
  try {
    return winrt::Windows::Graphics::Capture::GraphicsCaptureSession::IsSupported();
  } catch (...) {
    return false;
  }
}

PermissionEvaluation ScreenCapturePermissionChecker::Evaluate() {
  PermissionEvaluation evaluation;
  evaluation.diagnostics = BaseDiagnostics();

  if (!IsCaptureSupported()) {
    evaluation.result = PermissionResult::kDenied;
    evaluation.guidance = kDeniedGuidance;
    evaluation.diagnostics[flutter::EncodableValue("probeError")] =
        flutter::EncodableValue("GraphicsCaptureSession::IsSupported returned false");
    return evaluation;
  }

  try {
    const MonitorInfo primary = DisplayEnumerator::PrimaryMonitor();
    evaluation.diagnostics[flutter::EncodableValue("primaryMonitorId")] =
        flutter::EncodableValue(primary.id);

    std::string probe_error;
    if (ProbeMonitorCapture(primary.handle, &probe_error)) {
      evaluation.result = PermissionResult::kGranted;
      return evaluation;
    }

    evaluation.result = PermissionResult::kDenied;
    evaluation.guidance = kDeniedGuidance;
    if (!probe_error.empty()) {
      evaluation.diagnostics[flutter::EncodableValue("probeError")] =
          flutter::EncodableValue(probe_error);
    }
    return evaluation;
  } catch (const std::exception& error) {
    evaluation.result = PermissionResult::kDenied;
    evaluation.guidance = kDeniedGuidance;
    evaluation.diagnostics[flutter::EncodableValue("probeError")] =
        flutter::EncodableValue(error.what());
    return evaluation;
  }
}

flutter::EncodableMap ScreenCapturePermissionChecker::PermissionStatusMap() {
  const PermissionEvaluation evaluation = Evaluate();

  flutter::EncodableMap map;
  map[flutter::EncodableValue("platform")] = flutter::EncodableValue("windows");
  map[flutter::EncodableValue("bundleId")] = flutter::EncodableValue("dev.oxy.oxyCapture");
  map[flutter::EncodableValue("diagnostics")] =
      flutter::EncodableValue(evaluation.diagnostics);

  if (evaluation.result == PermissionResult::kGranted) {
    map[flutter::EncodableValue("state")] = flutter::EncodableValue("granted");
  } else {
    map[flutter::EncodableValue("state")] = flutter::EncodableValue("denied");
    map[flutter::EncodableValue("guidanceMessage")] =
        flutter::EncodableValue(evaluation.guidance);
  }
  return map;
}

}  // namespace desktop_screenshot_capture_windows
