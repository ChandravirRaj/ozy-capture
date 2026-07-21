import Foundation
import ScreenCaptureKit
import VideoToolbox

actor CaptureSessionManager {
  static let shared = CaptureSessionManager()

  private var onEvent: (([String: Any]) -> Void)?

  func setEventHandler(_ handler: @escaping ([String: Any]) -> Void) {
    onEvent = handler
  }

  private struct ActiveSession {
    let sessionId: String
    let displayInfo: DisplayInfo
    let filter: SCContentFilter
    let configuration: SCStreamConfiguration
    var stream: SCStream?
    var streamOutput: StreamOutput?
    var latestImage: CGImage?
  }

  private var sessions: [String: ActiveSession] = [:]

  func prepareCapture(sessionId: String, displayId: String) async throws -> [String: Any] {
    let permission = await ScreenCapturePermissionChecker.evaluate()
    switch permission.result {
    case .granted:
      break
    case .restartRequired:
      throw CapturePluginError.captureFailed(
        "Screen Recording is enabled but requires restarting Oxy Capture."
      )
    case .reauthorizeInSettings:
      throw CapturePluginError.captureFailed(
        "Screen Recording must be re-enabled for this build of Oxy Capture in System Settings."
      )
    case .denied:
      throw CapturePluginError.permissionDenied
    }

    let displayInfo = try await DisplayEnumerator.display(forId: displayId)
    let filter = SCContentFilter(display: displayInfo.display, excludingWindows: [])
    let configuration = SCStreamConfiguration()
    configuration.width = displayInfo.width
    configuration.height = displayInfo.height
    configuration.minimumFrameInterval = CMTime(value: 1, timescale: 2)
    configuration.queueDepth = 3
    configuration.showsCursor = true

    var session = ActiveSession(
      sessionId: sessionId,
      displayInfo: displayInfo,
      filter: filter,
      configuration: configuration,
      stream: nil,
      streamOutput: nil,
      latestImage: nil
    )

    if #available(macOS 14.0, *) {
      // SCScreenshotManager path — no persistent stream required.
    } else {
      let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
      let output = StreamOutput { [weak self] image in
        Task { await self?.updateLatestImage(sessionId: sessionId, image: image) }
      }
      try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: DispatchQueue(label: "screen.capture.output"))
      try await stream.startCapture()
      session.stream = stream
      session.streamOutput = output
    }

    sessions[sessionId] = session
    emit(type: "phaseChanged", sessionId: sessionId, extra: ["phase": "ready"])

    return [
      "sessionId": sessionId,
      "source": displayInfo.toMap(),
      "phase": "ready",
    ]
  }

  func updateLatestImage(sessionId: String, image: CGImage) {
    guard var session = sessions[sessionId] else { return }
    session.latestImage = image
    sessions[sessionId] = session
  }

  func takeScreenshot(sessionId: String, outputPath: String, format: String, quality: Int) async throws -> [String: Any] {
    guard let session = sessions[sessionId] else {
      throw CapturePluginError.sessionClosed
    }

    let image: CGImage
    if #available(macOS 14.0, *) {
      image = try await SCScreenshotManager.captureImage(contentFilter: session.filter, configuration: session.configuration)
    } else if let latest = session.latestImage {
      image = latest
    } else {
      throw CapturePluginError.captureFailed("No frame available from capture stream")
    }

    let bytesWritten: Int
    do {
      bytesWritten = try FrameEncoder.encode(
        image: image,
        format: format,
        quality: quality,
        outputPath: outputPath
      )
    } catch let error as CapturePluginError {
      throw error
    } catch {
      throw CapturePluginError.diskWriteFailed
    }

    let capturedAt = ISO8601DateFormatter().string(from: Date())
    return [
      "filePath": outputPath,
      "width": session.displayInfo.width,
      "height": session.displayInfo.height,
      "bytesWritten": bytesWritten,
      "capturedAt": capturedAt,
    ]
  }

  func stopCapture(sessionId: String) async {
    guard let session = sessions[sessionId] else { return }
    if let stream = session.stream {
      try? await stream.stopCapture()
    }
    sessions.removeValue(forKey: sessionId)
    emit(type: "phaseChanged", sessionId: sessionId, extra: ["phase": "completed"])
    emit(type: "sessionClosed", sessionId: sessionId, extra: [:])
  }

  func disposeAll() async {
    let ids = Array(sessions.keys)
    for id in ids {
      await stopCapture(sessionId: id)
    }
  }

  private func emit(type: String, sessionId: String, extra: [String: Any]) {
    var payload: [String: Any] = ["type": type, "sessionId": sessionId]
    for (key, value) in extra {
      payload[key] = value
    }
    onEvent?(payload)
  }
}

private final class StreamOutput: NSObject, SCStreamOutput {
  private let handler: (CGImage) -> Void

  init(handler: @escaping (CGImage) -> Void) {
    self.handler = handler
  }

  func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
    guard outputType == .screen,
          let imageBuffer = sampleBuffer.imageBuffer else { return }
    var cgImage: CGImage?
    VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImage)
    if let cgImage {
      handler(cgImage)
    }
  }
}
