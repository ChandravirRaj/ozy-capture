import Foundation
import ScreenCaptureKit

struct DisplayInfo {
  let id: String
  let label: String
  let width: Int
  let height: Int
  let isPrimary: Bool
  let display: SCDisplay

  func toMap() -> [String: Any] {
    return [
      "id": id,
      "label": label,
      "width": width,
      "height": height,
      "isPrimary": isPrimary,
    ]
  }
}

enum DisplayEnumerator {
  static func listDisplays() async throws -> [DisplayInfo] {
    let content: SCShareableContent
    do {
      content = try await ScreenCapturePermissionChecker.fetchShareableContent()
    } catch let error as CapturePluginError {
      throw error
    } catch {
      if ScreenCapturePermissionChecker.isPermissionError(error) {
        throw CapturePluginError.permissionDenied
      }
      throw CapturePluginError.captureApiUnavailable
    }

    let mainDisplayId = CGMainDisplayID()
    return content.displays.map { display in
      DisplayInfo(
        id: String(display.displayID),
        label: "Display \(display.displayID) (\(display.width)x\(display.height))",
        width: display.width,
        height: display.height,
        isPrimary: display.displayID == mainDisplayId,
        display: display
      )
    }
  }

  static func display(forId id: String) async throws -> DisplayInfo {
    let displays = try await listDisplays()
    guard let match = displays.first(where: { $0.id == id }) else {
      throw CapturePluginError.sourceDisconnected
    }
    return match
  }
}
