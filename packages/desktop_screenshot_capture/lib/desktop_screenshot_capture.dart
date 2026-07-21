library desktop_screenshot_capture;

export 'package:desktop_screenshot_capture_platform_interface/desktop_screenshot_capture_platform_interface.dart'
    show
        CaptureError,
        CaptureErrorCode,
        CaptureEvent,
        CapturePhase,
        CapturePhaseChanged,
        CaptureSession,
        CaptureSource,
        PermissionRevoked,
        PermissionState,
        PermissionStatus,
        ScreenshotFormat,
        ScreenshotResult,
        SessionClosed,
        SourceDisconnected;

export 'src/desktop_screenshot_capture.dart';
export 'src/mock_screenshot_capture.dart';
