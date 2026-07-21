import 'dart:async';
import 'dart:io';

import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_config.dart';
import '../../constants/app_strings.dart';
import '../../services/capture_scheduler.dart';
import '../../services/session_storage.dart';
import '../../services/tray_service.dart';
import '../../services/window_lifecycle_service.dart';

part 'capture_event.dart';
part 'capture_state.dart';

class CaptureBloc extends Bloc<CaptureBlocEvent, CaptureState> {
  CaptureBloc({
    required DesktopScreenshotCapture capture,
    required SessionStorage storage,
    CaptureScheduler? scheduler,
    TrayServiceBase? trayService,
    WindowLifecycleServiceBase? windowLifecycleService,
  })  : _capture = capture,
        _storage = storage,
        _scheduler = scheduler ?? CaptureScheduler(),
        _trayService = trayService ?? createTrayService(),
        _windowService = windowLifecycleService ?? createWindowLifecycleService(),
        super(CaptureState(platformLabel: platformLabel())) {
    on<ConsentToggled>(_onConsentToggled);
    on<CheckPermissionRequested>(_onCheckPermission);
    on<SelectMonitorRequested>(_onSelectMonitor);
    on<MonitorSelected>(_onMonitorSelected);
    on<IntervalChanged>(_onIntervalChanged);
    on<FormatChanged>(_onFormatChanged);
    on<StartCaptureRequested>(_onStartCapture);
    on<StopCaptureRequested>(_onStopCapture);
    on<TickElapsed>(_onTickElapsed);
    on<ScreenshotSucceeded>(_onScreenshotSucceeded);
    on<ScreenshotFailed>(_onScreenshotFailed);
    on<NativeCaptureEventReceived>(_onNativeEvent);
    on<OpenFolderRequested>(_onOpenFolder);
    on<StartNewSessionRequested>(_onStartNewSession);
    on<PermissionGrantedBackgroundMode>(_onPermissionGrantedBackgroundMode);
    on<WindowCloseRequested>(_onWindowCloseRequested);
    on<TrayShowWindowRequested>(_onTrayShowWindowRequested);
    on<TrayHideWindowRequested>(_onTrayHideWindowRequested);
    on<TrayStopCaptureRequested>(_onTrayStopCaptureRequested);
    on<AutoStartCaptureRequested>(_onAutoStartCapture);
    on<OpenScreenRecordingSettingsRequested>(_onOpenScreenRecordingSettings);
    on<QuitApplicationRequested>(_onQuitApplicationRequested);

    _nativeSubscription = _capture.watchEvents().listen((event) {
      add(NativeCaptureEventReceived(event));
    });

    unawaited(_bootstrapWindowService());
  }

  final DesktopScreenshotCapture _capture;
  final SessionStorage _storage;
  final CaptureScheduler _scheduler;
  final TrayServiceBase _trayService;
  final WindowLifecycleServiceBase _windowService;

  StreamSubscription<CaptureEvent>? _nativeSubscription;
  Timer? _elapsedTimer;
  DateTime? _captureStartedAt;
  String? _activeSessionId;
  String? _activeOutputFolder;
  ScreenshotFormat _activeFormat = ScreenshotFormat.jpeg;
  bool _backgroundModeInitialized = false;
  bool _quitting = false;
  bool _autoStartAttempted = false;

  Future<void> _bootstrapWindowService() async {
    await _windowService.initialize(
      onWindowClose: () => add(const WindowCloseRequested()),
    );
  }

  Future<void> _onConsentToggled(
    ConsentToggled event,
    Emitter<CaptureState> emit,
  ) async {
    emit(state.copyWith(consentAccepted: event.accepted, clearError: true));
    if (event.accepted) {
      add(const CheckPermissionRequested());
    }
  }

  Future<void> _onCheckPermission(
    CheckPermissionRequested event,
    Emitter<CaptureState> emit,
  ) async {
    try {
      final status = await _capture.getPermissionStatus();
      final nextState = state.copyWith(permissionStatus: status, clearError: true);
      emit(nextState);
      if (status.isUsable &&
          nextState.consentAccepted &&
          !nextState.backgroundModeEnabled) {
        add(const PermissionGrantedBackgroundMode());
      }
      _scheduleAutoStartIfNeeded(nextState);
      await _syncTray(nextState);
    } on CaptureError catch (error) {
      emit(state.copyWith(error: error, phase: CapturePhase.failed));
    }
  }

  void _scheduleAutoStartIfNeeded(CaptureState current) {
    if (!current.consentAccepted) {
      return;
    }
    if (current.permissionStatus?.isUsable != true) {
      _autoStartAttempted = false;
      return;
    }
    if (current.isCapturing ||
        current.isBusy ||
        current.phase == CapturePhase.stopping) {
      return;
    }
    if (current.canStartCapture) {
      add(const StartCaptureRequested());
      return;
    }
    if (_autoStartAttempted || current.sessionId != null) {
      return;
    }
    _autoStartAttempted = true;
    add(const AutoStartCaptureRequested());
  }

  Future<void> _onAutoStartCapture(
    AutoStartCaptureRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (!state.consentAccepted || state.permissionStatus?.isUsable != true) {
      return;
    }
    if (state.isCapturing || state.isBusy) {
      return;
    }

    emit(state.copyWith(phase: CapturePhase.selectingSource, isBusy: true));
    try {
      final monitors = await _capture.listMonitors();
      if (monitors.isEmpty) {
        emit(
          state.copyWith(
            phase: CapturePhase.failed,
            isBusy: false,
            error: const CaptureError(
              code: CaptureErrorCode.captureFailed,
              message: AppStrings.errorNoMonitorsAutoCapture,
            ),
          ),
        );
        return;
      }

      final source = _defaultMonitor(monitors);
      final outputFolder = await _storage.createSessionDirectory();
      final sessionId = outputFolder.split(Platform.pathSeparator).last;
      final session = await _capture.prepareCapture(
        source: source,
        sessionId: sessionId,
      );

      emit(
        state.copyWith(
          availableMonitors: monitors,
          selectedSource: source,
          sessionId: session.sessionId,
          outputFolder: outputFolder,
          phase: CapturePhase.ready,
          isBusy: false,
          elapsed: Duration.zero,
          screenshotCount: 0,
          clearError: true,
        ),
      );
      add(const StartCaptureRequested());
    } on CaptureError catch (error) {
      _autoStartAttempted = false;
      emit(
        state.copyWith(
          error: error,
          phase: CapturePhase.failed,
          isBusy: false,
        ),
      );
    }
  }

  CaptureSource _defaultMonitor(List<CaptureSource> monitors) {
    return monitors.firstWhere(
      (monitor) => monitor.isPrimary,
      orElse: () => monitors.first,
    );
  }

  Future<void> _onOpenScreenRecordingSettings(
    OpenScreenRecordingSettingsRequested event,
    Emitter<CaptureState> emit,
  ) async {
    final Uri settingsUri;
    if (Platform.isMacOS) {
      settingsUri = Uri.parse(AppConfig.macScreenRecordingSettingsUri);
    } else if (Platform.isWindows) {
      settingsUri = Uri.parse(AppConfig.windowsPrivacySettingsUri);
    } else {
      return;
    }

    if (await canLaunchUrl(settingsUri)) {
      await launchUrl(settingsUri);
    }
  }

  Future<void> _onPermissionGrantedBackgroundMode(
    PermissionGrantedBackgroundMode event,
    Emitter<CaptureState> emit,
  ) async {
    if (_backgroundModeInitialized) {
      return;
    }

    await _trayService.initialize(
      onShowWindow: () => add(const TrayShowWindowRequested()),
      onStopCapture: () => add(const TrayStopCaptureRequested()),
      onQuit: () => add(const QuitApplicationRequested()),
    );
    await _windowService.setBackgroundModeEnabled(true);
    _backgroundModeInitialized = true;
    emit(
      state.copyWith(
        backgroundModeEnabled: true,
        trayActive: true,
      ),
    );
    await _syncTray(state);
  }

  Future<void> _onWindowCloseRequested(
    WindowCloseRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (state.isCapturing && state.backgroundModeEnabled) {
      await _enterFloatingMode(emit);
      return;
    }
    if (state.backgroundModeEnabled) {
      await _windowService.hide();
      emit(
        state.copyWith(
          windowVisible: false,
          windowDisplayMode: WindowDisplayMode.hidden,
        ),
      );
      return;
    }
    add(const QuitApplicationRequested());
  }

  Future<void> _onTrayShowWindowRequested(
    TrayShowWindowRequested event,
    Emitter<CaptureState> emit,
  ) async {
    await _exitFloatingMode(emit);
  }

  Future<void> _onTrayHideWindowRequested(
    TrayHideWindowRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (!state.backgroundModeEnabled) {
      return;
    }
    if (state.isCapturing) {
      await _enterFloatingMode(emit);
      return;
    }
    await _windowService.hide();
    emit(
      state.copyWith(
        windowVisible: false,
        windowDisplayMode: WindowDisplayMode.hidden,
      ),
    );
  }

  Future<void> _enterFloatingMode(Emitter<CaptureState> emit) async {
    await _windowService.enterFloatingMode();
    emit(
      state.copyWith(
        windowDisplayMode: WindowDisplayMode.floating,
        windowVisible: true,
      ),
    );
  }

  Future<void> _exitFloatingMode(Emitter<CaptureState> emit) async {
    await _windowService.exitFloatingMode();
    emit(
      state.copyWith(
        windowDisplayMode: WindowDisplayMode.full,
        windowVisible: true,
      ),
    );
  }

  Future<void> _onTrayStopCaptureRequested(
    TrayStopCaptureRequested event,
    Emitter<CaptureState> emit,
  ) async {
    add(const StopCaptureRequested());
  }

  Future<void> _onQuitApplicationRequested(
    QuitApplicationRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (_quitting) {
      return;
    }
    _quitting = true;

    if (state.isCapturing) {
      await _onStopCapture(const StopCaptureRequested(), emit);
    }

    await _trayService.destroy();
    await _windowService.destroy();
    await _capture.dispose();
    await _nativeSubscription?.cancel();
    exit(0);
  }

  Future<void> _onSelectMonitor(
    SelectMonitorRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (!state.canSelectMonitor) {
      return;
    }

    emit(state.copyWith(phase: CapturePhase.selectingSource, isBusy: true));
    try {
      final monitors = await _capture.listMonitors();
      emit(
        state.copyWith(
          availableMonitors: monitors,
          phase: CapturePhase.selectingSource,
          isBusy: false,
          clearError: true,
        ),
      );
    } on CaptureError catch (error) {
      emit(
        state.copyWith(
          error: error,
          phase: CapturePhase.failed,
          isBusy: false,
        ),
      );
    }
  }

  Future<void> _onMonitorSelected(
    MonitorSelected event,
    Emitter<CaptureState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final outputFolder = await _storage.createSessionDirectory();
      final sessionId = outputFolder.split(Platform.pathSeparator).last;
      final session = await _capture.prepareCapture(
        source: event.source,
        sessionId: sessionId,
      );
      emit(
        state.copyWith(
          selectedSource: event.source,
          sessionId: session.sessionId,
          outputFolder: outputFolder,
          phase: CapturePhase.ready,
          isBusy: false,
          elapsed: Duration.zero,
          screenshotCount: 0,
          clearError: true,
        ),
      );
    } on CaptureError catch (error) {
      emit(
        state.copyWith(
          error: error,
          phase: CapturePhase.failed,
          isBusy: false,
        ),
      );
    }
  }

  void _onIntervalChanged(IntervalChanged event, Emitter<CaptureState> emit) {
    if (event.seconds < 5) {
      return;
    }
    emit(state.copyWith(intervalSeconds: event.seconds));
  }

  void _onFormatChanged(FormatChanged event, Emitter<CaptureState> emit) {
    emit(state.copyWith(format: event.format));
  }

  Future<void> _onStartCapture(
    StartCaptureRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (!state.canStartCapture ||
        state.sessionId == null ||
        state.outputFolder == null) {
      return;
    }

    _captureStartedAt = DateTime.now();
    _activeSessionId = state.sessionId;
    _activeOutputFolder = state.outputFolder;
    _activeFormat = state.format;
    var nextState = state.copyWith(
      phase: CapturePhase.capturing,
      elapsed: Duration.zero,
      clearError: true,
    );
    emit(nextState);
    await _syncTray(nextState);

    if (nextState.backgroundModeEnabled) {
      await _windowService.hide();
      nextState = nextState.copyWith(
        windowVisible: false,
        windowDisplayMode: WindowDisplayMode.hidden,
      );
      emit(nextState);
    }

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_captureStartedAt != null) {
        add(TickElapsed(DateTime.now().difference(_captureStartedAt!)));
      }
    });

    _scheduler.start(
      interval: Duration(seconds: state.intervalSeconds),
      onTick: () async {
        final sessionId = _activeSessionId;
        final outputFolder = _activeOutputFolder;
        if (sessionId == null || outputFolder == null) {
          return;
        }

        try {
          final outputPath = _storage.nextScreenshotPath(
            sessionDirectory: outputFolder,
            format: _activeFormat,
          );
          final result = await _capture.takeScreenshot(
            sessionId: sessionId,
            outputPath: outputPath,
            format: _activeFormat,
            quality: 80,
          );
          add(ScreenshotSucceeded(result));
        } on CaptureError catch (error) {
          add(ScreenshotFailed(error));
        }
      },
    );
  }

  Future<void> _onStopCapture(
    StopCaptureRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (state.phase != CapturePhase.capturing &&
        state.phase != CapturePhase.stopping) {
      return;
    }

    emit(state.copyWith(phase: CapturePhase.stopping));
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    await _scheduler.stop();

    final sessionId = state.sessionId;
    if (sessionId != null) {
      try {
        await _capture.stopCapture(sessionId);
      } on CaptureError catch (error) {
        emit(state.copyWith(error: error));
      }
    }

    emit(
      state.copyWith(
        phase: CapturePhase.completed,
        captureInProgress: false,
      ),
    );
    _activeSessionId = null;
    _activeOutputFolder = null;
    if (state.windowDisplayMode == WindowDisplayMode.floating) {
      await _exitFloatingMode(emit);
    }
    await _syncTray(state);
  }

  void _onTickElapsed(TickElapsed event, Emitter<CaptureState> emit) {
    if (state.phase == CapturePhase.capturing) {
      emit(state.copyWith(elapsed: event.elapsed));
    }
  }

  Future<void> _onScreenshotSucceeded(
    ScreenshotSucceeded event,
    Emitter<CaptureState> emit,
  ) async {
    emit(
      state.copyWith(
        screenshotCount: state.screenshotCount + 1,
        lastScreenshotAt: event.result.capturedAt,
        lastSavedFile: event.result.filePath,
        captureInProgress: false,
        clearError: true,
      ),
    );
  }

  Future<void> _onScreenshotFailed(
    ScreenshotFailed event,
    Emitter<CaptureState> emit,
  ) async {
    emit(
      state.copyWith(
        error: event.error,
        phase: CapturePhase.failed,
        captureInProgress: false,
      ),
    );
    add(const StopCaptureRequested());
  }

  Future<void> _onNativeEvent(
    NativeCaptureEventReceived event,
    Emitter<CaptureState> emit,
  ) async {
    switch (event.event) {
      case SourceDisconnected():
        emit(
          state.copyWith(
            phase: CapturePhase.sourceDisconnected,
            error: const CaptureError(
              code: CaptureErrorCode.sourceDisconnected,
              message: AppStrings.errorDisplayDisconnected,
            ),
          ),
        );
        add(const StopCaptureRequested());
      case PermissionRevoked():
        emit(
          state.copyWith(
            phase: CapturePhase.permissionRevoked,
            error: const CaptureError(
              code: CaptureErrorCode.permissionDenied,
              message: AppStrings.errorPermissionRevoked,
            ),
          ),
        );
        add(const StopCaptureRequested());
      case CapturePhaseChanged(:final phase):
        if (phase == CapturePhase.sourceDisconnected ||
            phase == CapturePhase.permissionRevoked) {
          emit(state.copyWith(phase: phase));
        }
      case SessionClosed():
        break;
    }
    await _syncTray(state);
  }

  Future<void> _onOpenFolder(
    OpenFolderRequested event,
    Emitter<CaptureState> emit,
  ) async {
    final folder = state.outputFolder;
    if (folder == null) {
      return;
    }
    final uri = Uri.file(folder);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _onStartNewSession(
    StartNewSessionRequested event,
    Emitter<CaptureState> emit,
  ) async {
    emit(
      CaptureState(
        platformLabel: state.platformLabel,
        consentAccepted: state.consentAccepted,
        permissionStatus: state.permissionStatus,
        intervalSeconds: state.intervalSeconds,
        format: state.format,
        backgroundModeEnabled: state.backgroundModeEnabled,
        trayActive: state.trayActive,
        windowDisplayMode: WindowDisplayMode.full,
      ),
    );
    if (state.windowDisplayMode == WindowDisplayMode.floating) {
      await _windowService.exitFloatingMode();
    }
    _autoStartAttempted = false;
    add(const CheckPermissionRequested());
  }

  Future<void> _syncTray(CaptureState current) async {
    if (!current.trayActive) {
      return;
    }
    await _trayService.updateTray(capturing: current.isCapturing);
  }

  @override
  Future<void> close() async {
    _elapsedTimer?.cancel();
    await _scheduler.stop();
    await _nativeSubscription?.cancel();
    if (!_quitting) {
      await _trayService.destroy();
      await _windowService.destroy();
      await _capture.dispose();
    }
    return super.close();
  }
}
