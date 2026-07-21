import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface.dart';

import 'desktop_screenshot_capture.dart';

class MockScreenshotCapture implements DesktopScreenshotCapture {
  MockScreenshotCapture({
    this.permissionGranted = true,
    this.captureDelay = const Duration(milliseconds: 300),
  });

  final bool permissionGranted;
  final Duration captureDelay;

  final _eventController = StreamController<CaptureEvent>.broadcast();
  final _sessions = <String, _MockSession>{};
  final _random = Random();

  @override
  Stream<CaptureEvent> watchEvents() => _eventController.stream;

  @override
  Future<void> dispose() async {
    await _eventController.close();
  }

  @override
  Future<PermissionStatus> getPermissionStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return PermissionStatus(
      state: permissionGranted ? PermissionState.granted : PermissionState.denied,
      platform: Platform.operatingSystem,
      guidanceMessage: permissionGranted
          ? null
          : 'Grant screen recording permission in system settings.',
    );
  }

  @override
  Future<List<CaptureSource>> listMonitors() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [
      CaptureSource(
        id: 'mock-display-1',
        label: 'Mock Display 1 (1920x1080)',
        width: 1920,
        height: 1080,
        isPrimary: true,
      ),
      CaptureSource(
        id: 'mock-display-2',
        label: 'Mock Display 2 (2560x1440)',
        width: 2560,
        height: 1440,
        isPrimary: false,
      ),
    ];
  }

  @override
  Future<CaptureSource?> selectMonitor() async {
    final monitors = await listMonitors();
    return monitors.firstWhere((m) => m.isPrimary, orElse: () => monitors.first);
  }

  @override
  Future<CaptureSession> prepareCapture({
    required CaptureSource source,
    required String sessionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _sessions[sessionId] = _MockSession(source: source);
    final session = CaptureSession(
      sessionId: sessionId,
      source: source,
      phase: CapturePhase.ready,
    );
    _eventController.add(
      CapturePhaseChanged(sessionId: sessionId, phase: CapturePhase.ready),
    );
    return session;
  }

  @override
  Future<ScreenshotResult> takeScreenshot({
    required String sessionId,
    required String outputPath,
    required ScreenshotFormat format,
    required int quality,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw const CaptureError(
        code: CaptureErrorCode.sessionClosed,
        message: 'Capture session is not active.',
      );
    }

    await Future<void>.delayed(captureDelay);

    final file = File(outputPath);
    await file.parent.create(recursive: true);

    final bytes = _generatePlaceholderImage(
      width: session.source.width,
      height: session.source.height,
      format: format,
    );
    await file.writeAsBytes(bytes, flush: true);

    return ScreenshotResult(
      filePath: outputPath,
      width: session.source.width,
      height: session.source.height,
      bytesWritten: bytes.length,
      capturedAt: DateTime.now(),
    );
  }

  @override
  Future<void> stopCapture(String sessionId) async {
    _sessions.remove(sessionId);
    _eventController.add(
      CapturePhaseChanged(sessionId: sessionId, phase: CapturePhase.completed),
    );
    _eventController.add(SessionClosed(sessionId: sessionId));
  }

  Uint8List _generatePlaceholderImage({
    required int width,
    required int height,
    required ScreenshotFormat format,
  }) {
    if (format == ScreenshotFormat.png) {
      return _minimalPng(width: width, height: height);
    }
    return Uint8List.fromList(List<int>.generate(512, (i) => (i + _random.nextInt(255)) % 256));
  }

  Uint8List _minimalPng({required int width, required int height}) {
    // Tiny valid 1x1 PNG header placeholder; mock only.
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
      0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
  }
}

class _MockSession {
  _MockSession({required this.source});

  final CaptureSource source;
}
