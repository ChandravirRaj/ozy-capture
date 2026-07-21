import Cocoa
import FlutterMacOS
import ScreenCaptureKit

public class DesktopScreenshotCaptureMacosPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private let sessionManager = CaptureSessionManager.shared

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = DesktopScreenshotCaptureMacosPlugin()
    let channel = FlutterMethodChannel(
      name: "dev.oxy.screen_capture/desktop_screenshot_capture",
      binaryMessenger: registrar.messenger
    )
    let eventChannel = FlutterEventChannel(
      name: "dev.oxy.screen_capture/events",
      binaryMessenger: registrar.messenger
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
    Task {
      await CaptureSessionManager.shared.setEventHandler { event in
        DispatchQueue.main.async {
          instance.eventSink?(event)
        }
      }
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPermissionStatus":
      Task { @MainActor in
        result(await CaptureErrorCodes.permissionStatusMap())
      }
    case "listMonitors":
      Task { @MainActor in
        do {
          let monitors = try await DisplayEnumerator.listDisplays()
          result(monitors.map { $0.toMap() })
        } catch {
          result(CaptureErrorCodes.flutterError(from: error))
        }
      }
    case "selectMonitor":
      if let map = call.arguments as? [String: Any], let id = map["id"] as? String {
        Task {
          do {
            let displays = try await DisplayEnumerator.listDisplays()
            if let display = displays.first(where: { $0.id == id }) {
              result(display.toMap())
            } else {
              result(CaptureErrorCodes.flutterError(
                code: CapturePluginError.captureFailed("Display not found"),
                message: "Display not found"
              ))
            }
          } catch {
            result(CaptureErrorCodes.flutterError(from: error))
          }
        }
      } else {
        result(nil)
      }
    case "prepareCapture":
      guard let args = call.arguments as? [String: Any],
            let sessionId = args["sessionId"] as? String,
            let sourceMap = args["source"] as? [String: Any] ?? args as [String: Any]? else {
        result(CaptureErrorCodes.flutterError(
          code: CapturePluginError.captureFailed("Invalid prepareCapture arguments"),
          message: "Invalid prepareCapture arguments"
        ))
        return
      }
      let sourceId = (args["sourceId"] as? String) ?? (sourceMap["id"] as? String ?? "")
      Task {
        do {
          let session = try await sessionManager.prepareCapture(
            sessionId: sessionId,
            displayId: sourceId
          )
          result(session)
        } catch {
          result(CaptureErrorCodes.flutterError(from: error))
        }
      }
    case "takeScreenshot":
      guard let args = call.arguments as? [String: Any],
            let sessionId = args["sessionId"] as? String,
            let outputPath = args["outputPath"] as? String,
            let format = args["format"] as? String else {
        result(CaptureErrorCodes.flutterError(
          code: CapturePluginError.captureFailed("Invalid takeScreenshot arguments"),
          message: "Invalid takeScreenshot arguments"
        ))
        return
      }
      let quality = args["quality"] as? Int ?? 80
      Task {
        do {
          let screenshot = try await sessionManager.takeScreenshot(
            sessionId: sessionId,
            outputPath: outputPath,
            format: format,
            quality: quality
          )
          result(screenshot)
        } catch {
          result(CaptureErrorCodes.flutterError(from: error))
        }
      }
    case "stopCapture":
      guard let args = call.arguments as? [String: Any],
            let sessionId = args["sessionId"] as? String else {
        result(CaptureErrorCodes.flutterError(
          code: CapturePluginError.captureFailed("Invalid stopCapture arguments"),
          message: "Invalid stopCapture arguments"
        ))
        return
      }
      Task {
        await sessionManager.stopCapture(sessionId: sessionId)
        result(nil)
      }
    case "dispose":
      Task {
        await sessionManager.disposeAll()
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
