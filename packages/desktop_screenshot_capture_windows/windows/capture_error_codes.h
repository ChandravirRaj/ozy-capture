#ifndef CAPTURE_ERROR_CODES_H_
#define CAPTURE_ERROR_CODES_H_

#include <flutter/encodable_value.h>
#include <flutter/method_result.h>
#include <string>

namespace desktop_screenshot_capture_windows {

enum class CapturePluginError {
  kPermissionDenied,
  kSelectionCancelled,
  kCaptureApiUnavailable,
  kSourceDisconnected,
  kCaptureFailed,
  kEncodingFailed,
  kDirectoryCreationFailed,
  kDiskWriteFailed,
  kDiskFull,
  kSessionClosed,
};

std::string CapturePluginErrorCode(CapturePluginError error);
std::string CapturePluginErrorMessage(CapturePluginError error,
                                      const std::string& detail = "");

void ResultError(
    flutter::MethodResult<flutter::EncodableValue>* result,
    CapturePluginError error,
    const std::string& detail = "");

void ResultError(
    flutter::MethodResult<flutter::EncodableValue>* result,
    const std::string& code,
    const std::string& message);

}  // namespace desktop_screenshot_capture_windows

#endif  // CAPTURE_ERROR_CODES_H_
