#include "capture_error_codes.h"

namespace desktop_screenshot_capture_windows {

std::string CapturePluginErrorCode(CapturePluginError error) {
  switch (error) {
    case CapturePluginError::kPermissionDenied:
      return "permission_denied";
    case CapturePluginError::kSelectionCancelled:
      return "selection_cancelled";
    case CapturePluginError::kCaptureApiUnavailable:
      return "capture_api_unavailable";
    case CapturePluginError::kSourceDisconnected:
      return "source_disconnected";
    case CapturePluginError::kCaptureFailed:
      return "capture_failed";
    case CapturePluginError::kEncodingFailed:
      return "encoding_failed";
    case CapturePluginError::kDirectoryCreationFailed:
      return "directory_creation_failed";
    case CapturePluginError::kDiskWriteFailed:
      return "disk_write_failed";
    case CapturePluginError::kDiskFull:
      return "disk_full";
    case CapturePluginError::kSessionClosed:
      return "session_closed";
  }
  return "capture_failed";
}

std::string CapturePluginErrorMessage(CapturePluginError error,
                                      const std::string& detail) {
  switch (error) {
    case CapturePluginError::kPermissionDenied:
      return "Screen capture permission was denied.";
    case CapturePluginError::kSelectionCancelled:
      return "Monitor selection was cancelled.";
    case CapturePluginError::kCaptureApiUnavailable:
      return "Screen capture is unavailable on this system.";
    case CapturePluginError::kSourceDisconnected:
      return "The selected display was disconnected.";
    case CapturePluginError::kCaptureFailed:
      return detail.empty() ? "Failed to capture screenshot."
                            : "Failed to capture screenshot: " + detail;
    case CapturePluginError::kEncodingFailed:
      return detail.empty() ? "Failed to encode screenshot."
                            : "Failed to encode screenshot: " + detail;
    case CapturePluginError::kDirectoryCreationFailed:
      return "Could not create the output directory.";
    case CapturePluginError::kDiskWriteFailed:
      return "Could not write the screenshot file.";
    case CapturePluginError::kDiskFull:
      return "Disk is full.";
    case CapturePluginError::kSessionClosed:
      return "Capture session is closed.";
  }
  return "Capture error.";
}

void ResultError(flutter::MethodResult<flutter::EncodableValue>* result,
                 CapturePluginError error,
                 const std::string& detail) {
  ResultError(result, CapturePluginErrorCode(error),
              CapturePluginErrorMessage(error, detail));
}

void ResultError(flutter::MethodResult<flutter::EncodableValue>* result,
                 const std::string& code,
                 const std::string& message) {
  result->Error(code, message, flutter::EncodableValue(message));
}

}  // namespace desktop_screenshot_capture_windows
