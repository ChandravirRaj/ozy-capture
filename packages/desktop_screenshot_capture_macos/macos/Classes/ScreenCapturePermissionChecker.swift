import Foundation
import ScreenCaptureKit
import Security

enum ScreenCapturePermissionResult {
  case granted
  case denied
  case restartRequired
  case reauthorizeInSettings
}

enum ScreenCapturePermissionChecker {
  static func evaluate() async -> (
    result: ScreenCapturePermissionResult,
    guidance: String?,
    diagnostics: [String: Any]
  ) {
    var diagnostics = baseDiagnostics()

    if CGPreflightScreenCaptureAccess() {
      diagnostics["preflight"] = true
      return (.granted, nil, diagnostics)
    }
    diagnostics["preflight"] = false

    if let content = await probeShareableContent(diagnostics: &diagnostics) {
      diagnostics["displayCount"] = content.displays.count
      return (.granted, nil, diagnostics)
    }

    let requestGranted = CGRequestScreenCaptureAccess()
    diagnostics["requestGranted"] = requestGranted
    let preflightAfterRequest = CGPreflightScreenCaptureAccess()
    diagnostics["preflightAfterRequest"] = preflightAfterRequest

    if preflightAfterRequest {
      return (.granted, nil, diagnostics)
    }

    if let content = await probeShareableContent(diagnostics: &diagnostics) {
      diagnostics["displayCount"] = content.displays.count
      return (.granted, nil, diagnostics)
    }

    if requestGranted {
      return (.restartRequired, restartGuidance, diagnostics)
    }

    return (.denied, deniedGuidance, diagnostics)
  }

  static func permissionStatusMap() async -> [String: Any] {
    let evaluation = await evaluate()
    let bundleId = Bundle.main.bundleIdentifier ?? "dev.oxy.oxyCapture"
    var map: [String: Any] = [
      "platform": "macos",
      "bundleId": bundleId,
      "diagnostics": evaluation.diagnostics,
    ]

    switch evaluation.result {
    case .granted:
      map["state"] = "granted"
    case .denied:
      map["state"] = "denied"
      map["guidanceMessage"] = evaluation.guidance ?? deniedGuidance
    case .restartRequired:
      map["state"] = "restartRequired"
      map["guidanceMessage"] = evaluation.guidance ?? restartGuidance
    case .reauthorizeInSettings:
      map["state"] = "reauthorizeInSettings"
      map["guidanceMessage"] = evaluation.guidance ?? reauthorizeGuidance
    }

    return map
  }

  static func isPermissionError(_ error: Error) -> Bool {
    let nsError = error as NSError
    if nsError.domain == "com.apple.ScreenCaptureKit.SCStreamErrorDomain" {
      return true
    }
    if nsError.domain == NSCocoaErrorDomain && nsError.code == 4097 {
      return true
    }
    let message = nsError.localizedDescription.lowercased()
    return message.contains("permission")
      || message.contains("not authorized")
      || message.contains("denied")
      || message.contains("declined")
  }

  static func fetchShareableContent() async throws -> SCShareableContent {
    if CGPreflightScreenCaptureAccess() {
      return try await loadShareableContent()
    }

    if let content = await probeShareableContentWithoutDiagnostics() {
      return content
    }

    if CGRequestScreenCaptureAccess() {
      if CGPreflightScreenCaptureAccess() {
        return try await loadShareableContent()
      }
      if let content = await probeShareableContentWithoutDiagnostics() {
        return content
      }
      throw CapturePluginError.captureFailed(restartGuidance)
    }

    throw CapturePluginError.permissionDenied
  }

  private static func probeShareableContentWithoutDiagnostics() async -> SCShareableContent? {
    var diagnostics: [String: Any] = [:]
    return await probeShareableContent(diagnostics: &diagnostics)
  }

  private static func probeShareableContent(
    diagnostics: inout [String: Any]
  ) async -> SCShareableContent? {
    do {
      return try await loadShareableContent(diagnostics: &diagnostics)
    } catch {
      diagnostics["shareableContentError"] = error.localizedDescription
      return nil
    }
  }

  private static func loadShareableContent(
    timeoutSeconds: Double = 30,
    diagnostics: inout [String: Any]
  ) async throws -> SCShareableContent {
    var probeDiagnostics: [String: Any] = [:]
    defer {
      diagnostics.merge(probeDiagnostics) { _, new in new }
    }
    return try await loadShareableContent(timeoutSeconds: timeoutSeconds, probeDiagnostics: &probeDiagnostics)
  }

  private static func loadShareableContent(timeoutSeconds: Double = 30) async throws -> SCShareableContent {
    var probeDiagnostics: [String: Any] = [:]
    return try await loadShareableContent(timeoutSeconds: timeoutSeconds, probeDiagnostics: &probeDiagnostics)
  }

  private static func loadShareableContent(
    timeoutSeconds: Double,
    probeDiagnostics: inout [String: Any]
  ) async throws -> SCShareableContent {
    var localDiagnostics: [String: Any] = [:]
    defer {
      probeDiagnostics.merge(localDiagnostics) { _, new in new }
    }

    return try await withCheckedThrowingContinuation { continuation in
      var finished = false
      let finish: (Result<SCShareableContent, Error>) -> Void = { result in
        guard !finished else { return }
        finished = true
        switch result {
        case .success(let content):
          continuation.resume(returning: content)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }

      Task { @MainActor in
        do {
          let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
          )
          let displayCount = content.displays.count
          localDiagnostics["shareableContentDisplayCount"] = displayCount
          if displayCount == 0 {
            finish(.failure(CapturePluginError.captureApiUnavailable))
            return
          }
          finish(.success(content))
        } catch {
          let nsError = error as NSError
          localDiagnostics["shareableContentDomain"] = nsError.domain
          localDiagnostics["shareableContentCode"] = nsError.code
          finish(.failure(error))
        }
      }

      DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + timeoutSeconds) {
        localDiagnostics["shareableContentTimedOut"] = true
        finish(.failure(CapturePluginError.captureFailed("Timed out waiting for ScreenCaptureKit")))
      }
    }
  }

  private static func baseDiagnostics() -> [String: Any] {
    var diagnostics: [String: Any] = [
      "executablePath": Bundle.main.executablePath ?? "unknown",
      "appPath": Bundle.main.bundlePath,
    ]

    if let executable = Bundle.main.executableURL {
      var staticCode: SecStaticCode?
      if SecStaticCodeCreateWithPath(executable as CFURL, [], &staticCode) == errSecSuccess,
         let staticCode {
        var infoCF: CFDictionary?
        if SecCodeCopySigningInformation(staticCode, [], &infoCF) == errSecSuccess,
           let info = infoCF as? [String: Any] {
          diagnostics["teamIdentifier"] = info[kSecCodeInfoTeamIdentifier as String] as? String ?? "none"
          if let cdHashes = info[kSecCodeInfoCdHashes as String] as? [Data],
             let hash = cdHashes.first {
            diagnostics["cdHash"] = hash.map { String(format: "%02x", $0) }.joined()
          }
        }
      }
    }

    return diagnostics
  }

  private static var appName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? "Oxy Capture"
  }

  private static var deniedGuidance: String {
    """
    Screen Recording access is required. Open System Settings → Privacy & Security → Screen Recording, enable \(appName), then click Refresh permission status. After reinstalling the app, turn \(appName) OFF then ON in that list (each build has a new signature).
    """
  }

  private static var restartGuidance: String {
    """
    \(appName) is enabled in Screen Recording, but macOS has not applied it yet. Quit Oxy Capture completely (Cmd+Q), then open it again from Applications. If needed, toggle \(appName) OFF then ON in Screen Recording settings first.
    """
  }

  private static var reauthorizeGuidance: String {
    """
    macOS does not recognize screen capture for this build of \(appName). In Screen Recording settings, turn \(appName) OFF, then ON again. If that fails, remove it from the list, launch Oxy Capture from Applications, and approve the prompt.
    """
  }
}
