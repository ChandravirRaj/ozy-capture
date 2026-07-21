part of 'capture_bloc.dart';

class CaptureState extends Equatable {
  const CaptureState({
    this.phase = CapturePhase.idle,
    this.consentAccepted = false,
    this.permissionStatus,
    this.availableMonitors = const [],
    this.selectedSource,
    this.sessionId,
    this.intervalSeconds = 15,
    this.format = ScreenshotFormat.jpeg,
    this.outputFolder,
    this.elapsed = Duration.zero,
    this.screenshotCount = 0,
    this.lastScreenshotAt,
    this.lastSavedFile,
    this.captureInProgress = false,
    this.error,
    this.platformLabel = AppStrings.unknown,
    this.isBusy = false,
    this.backgroundModeEnabled = false,
    this.windowVisible = true,
    this.windowDisplayMode = WindowDisplayMode.full,
    this.trayActive = false,
  });

  final CapturePhase phase;
  final bool consentAccepted;
  final PermissionStatus? permissionStatus;
  final List<CaptureSource> availableMonitors;
  final CaptureSource? selectedSource;
  final String? sessionId;
  final int intervalSeconds;
  final ScreenshotFormat format;
  final String? outputFolder;
  final Duration elapsed;
  final int screenshotCount;
  final DateTime? lastScreenshotAt;
  final String? lastSavedFile;
  final bool captureInProgress;
  final CaptureError? error;
  final String platformLabel;
  final bool isBusy;
  final bool backgroundModeEnabled;
  final bool windowVisible;
  final WindowDisplayMode windowDisplayMode;
  final bool trayActive;

  bool get canSelectMonitor =>
      consentAccepted &&
      phase != CapturePhase.capturing &&
      phase != CapturePhase.stopping &&
      permissionStatus?.isUsable == true;

  bool get canStartCapture =>
      consentAccepted &&
      selectedSource != null &&
      sessionId != null &&
      outputFolder != null &&
      (phase == CapturePhase.ready || phase == CapturePhase.completed);

  bool get isCapturing =>
      phase == CapturePhase.capturing || phase == CapturePhase.stopping;

  CaptureState copyWith({
    CapturePhase? phase,
    bool? consentAccepted,
    PermissionStatus? permissionStatus,
    List<CaptureSource>? availableMonitors,
    CaptureSource? selectedSource,
    String? sessionId,
    int? intervalSeconds,
    ScreenshotFormat? format,
    String? outputFolder,
    Duration? elapsed,
    int? screenshotCount,
    DateTime? lastScreenshotAt,
    String? lastSavedFile,
    bool? captureInProgress,
    CaptureError? error,
    bool clearError = false,
    String? platformLabel,
    bool? isBusy,
    bool? backgroundModeEnabled,
    bool? windowVisible,
    WindowDisplayMode? windowDisplayMode,
    bool? trayActive,
    bool clearSelectedSource = false,
    bool clearSession = false,
  }) {
    return CaptureState(
      phase: phase ?? this.phase,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      availableMonitors: availableMonitors ?? this.availableMonitors,
      selectedSource:
          clearSelectedSource ? null : (selectedSource ?? this.selectedSource),
      sessionId: clearSession ? null : (sessionId ?? this.sessionId),
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      format: format ?? this.format,
      outputFolder:
          clearSession ? null : (outputFolder ?? this.outputFolder),
      elapsed: elapsed ?? this.elapsed,
      screenshotCount: screenshotCount ?? this.screenshotCount,
      lastScreenshotAt: lastScreenshotAt ?? this.lastScreenshotAt,
      lastSavedFile: lastSavedFile ?? this.lastSavedFile,
      captureInProgress: captureInProgress ?? this.captureInProgress,
      error: clearError ? null : (error ?? this.error),
      platformLabel: platformLabel ?? this.platformLabel,
      isBusy: isBusy ?? this.isBusy,
      backgroundModeEnabled:
          backgroundModeEnabled ?? this.backgroundModeEnabled,
      windowVisible: windowVisible ?? this.windowVisible,
      windowDisplayMode: windowDisplayMode ?? this.windowDisplayMode,
      trayActive: trayActive ?? this.trayActive,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        consentAccepted,
        permissionStatus,
        availableMonitors,
        selectedSource,
        sessionId,
        intervalSeconds,
        format,
        outputFolder,
        elapsed,
        screenshotCount,
        lastScreenshotAt,
        lastSavedFile,
        captureInProgress,
        error,
        platformLabel,
        isBusy,
        backgroundModeEnabled,
        windowVisible,
        windowDisplayMode,
        trayActive,
      ];
}
