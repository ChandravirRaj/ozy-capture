import FlutterMacOS
import Foundation
import ScreenCaptureKit

struct CaptureErrorCodes {
  static func permissionStatusMap() async -> [String: Any] {
    await ScreenCapturePermissionChecker.permissionStatusMap()
  }

  static func flutterError(from error: Error) -> FlutterError {
    if let pluginError = error as? CapturePluginError {
      return flutterError(code: pluginError.code, message: pluginError.errorDescription ?? "Capture error", debug: pluginError.errorDescription)
    }
    return flutterError(code: "capture_failed", message: error.localizedDescription, debug: error.localizedDescription)
  }

  static func flutterError(code: CapturePluginError, message: String) -> FlutterError {
    return flutterError(code: code.code, message: message, debug: message)
  }

  static func flutterError(code: String, message: String, debug: String? = nil) -> FlutterError {
    return FlutterError(code: code, message: message, details: debug)
  }
}

enum CapturePluginError: LocalizedError {
  case permissionDenied
  case selectionCancelled
  case captureApiUnavailable
  case sourceDisconnected
  case captureFailed(String)
  case encodingFailed(String)
  case directoryCreationFailed
  case diskWriteFailed
  case diskFull
  case sessionClosed

  var errorDescription: String? {
    switch self {
    case .permissionDenied:
      return "Screen Recording permission was denied."
    case .selectionCancelled:
      return "Monitor selection was cancelled."
    case .captureApiUnavailable:
      return "Screen capture is unavailable on this system."
    case .sourceDisconnected:
      return "The selected display was disconnected."
    case .captureFailed(let detail):
      return "Failed to capture screenshot: \(detail)"
    case .encodingFailed(let detail):
      return "Failed to encode screenshot: \(detail)"
    case .directoryCreationFailed:
      return "Could not create the output directory."
    case .diskWriteFailed:
      return "Could not write the screenshot file."
    case .diskFull:
      return "Disk is full."
    case .sessionClosed:
      return "Capture session is closed."
    }
  }

  var code: String {
    switch self {
    case .permissionDenied: return "permission_denied"
    case .selectionCancelled: return "selection_cancelled"
    case .captureApiUnavailable: return "capture_api_unavailable"
    case .sourceDisconnected: return "source_disconnected"
    case .captureFailed: return "capture_failed"
    case .encodingFailed: return "encoding_failed"
    case .directoryCreationFailed: return "directory_creation_failed"
    case .diskWriteFailed: return "disk_write_failed"
    case .diskFull: return "disk_full"
    case .sessionClosed: return "session_closed"
    }
  }
}
