import 'dart:io';

import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';

abstract final class AppStrings {
  static const appName = 'Oxy Capture';

  static const consentTitle = 'Consent';
  static const consentBody =
      'This proof-of-concept application periodically captures screenshots '
      'of the monitor selected by you. Screenshots are stored locally on this '
      'computer and are not uploaded. You can stop capture at any time.';
  static const consentWarning =
      'Warning: Do not use real customer or confidential information during POC testing.';
  static const consentCheckbox = 'I understand and agree';

  static const launchDialogTitle = 'Welcome to Oxy Capture';
  static const launchDialogContinue = 'Continue';
  static const launchDialogCancel = 'Cancel';
  static const macPermissionExplanation =
      'Oxy Capture needs Screen Recording permission to capture your primary '
      'monitor. You may be prompted by macOS or need to enable Oxy Capture in '
      'System Settings → Privacy & Security → Screen Recording.';
  static const windowsPermissionExplanation =
      'Oxy Capture needs screen capture permission to capture your primary '
      'monitor. Windows may prompt you to allow screen capture, or you may need '
      'to enable it in Settings → Privacy & security.';
  static const linuxPermissionExplanation =
      'Oxy Capture needs screen capture permission to capture your primary '
      'monitor. On Wayland, a portal prompt may appear. Screen capture support '
      'on Linux is limited in this proof-of-concept build.';
  static const permissionRequiredTitle = 'Screen Recording permission required';
  static const windowsPermissionRequiredTitle =
      'Screen capture permission required';
  static const linuxPermissionRequiredTitle = 'Screen capture permission required';
  static const retryPermission = 'Retry';
  static const trayRunningMessage =
      'Oxy Capture runs from the system tray while capturing. '
      'Use the tray icon to open or stop recording.';

  static const captureSetupTitle = 'Capture setup';
  static const platformLabel = 'Platform';
  static const permissionStatusLabel = 'Permission status';
  static const appIdentifierLabel = 'App identifier';
  static const refreshPermissionStatus = 'Refresh permission status';
  static const openScreenRecordingSettings = 'Open Screen Recording Settings';
  static const openPrivacySettings = 'Open Privacy Settings';
  static const autoCaptureHint =
      'After Screen Recording permission is granted, Oxy Capture '
      'automatically selects your primary monitor and starts capturing.';
  static const stoppingCapture = 'Stopping capture...';
  static const selectedMonitorLabel = 'Selected monitor';
  static const screenshotIntervalLabel = 'Screenshot interval';
  static const interval5Seconds = '5 seconds';
  static const interval10Seconds = '10 seconds';
  static const interval15Seconds = '15 seconds';
  static const interval30Seconds = '30 seconds';
  static const interval60Seconds = '60 seconds';
  static const imageFormatLabel = 'Image format';
  static const formatJpeg = 'JPEG (quality 80)';
  static const formatPng = 'PNG (debug)';
  static const outputFolderLabel = 'Output folder';
  static const stopRecording = 'Stop Recording';
  static const selectMonitor = 'Select Monitor';
  static const startCapture = 'Start Capture';
  static const hideToFloatingBar = 'Hide to floating bar';
  static const hideToTray = 'Hide to tray';

  static const permissionGranted = 'Granted';
  static const permissionDenied = 'Denied';
  static const permissionRestartRequired = 'Restart required';
  static const permissionReauthorizeInSettings = 'Re-enable in Settings';
  static const permissionRestricted = 'Restricted';
  static const permissionRevoked = 'Revoked';
  static const permissionUnknown = 'Unknown';

  static const none = 'None';
  static const notCreatedYet = 'Not created yet';
  static const unknown = 'Unknown';
  static const primaryDisplay = 'Primary display';
  static const secondaryDisplay = 'Secondary display';

  static const selectMonitorTitle = 'Select a monitor';
  static const noMonitorsAvailable = 'No monitors available';
  static const cancel = 'Cancel';

  static const captureCompletedTitle = 'Capture completed';
  static const totalCaptureDurationPrefix = 'Total capture duration: ';
  static const totalScreenshotsPrefix = 'Total screenshots: ';
  static const outputFolderPrefix = 'Output folder: ';
  static const openFolder = 'Open Folder';
  static const startNewSession = 'Start New Session';

  static const trayOpenApp = 'Open Oxy Capture';
  static const trayQuit = 'Quit';
  static const trayCapturingTooltip = 'Oxy Capture — Capturing';
  static const trayIdleTooltip = 'Oxy Capture — Idle';

  static const errorNoMonitorsAutoCapture =
      'No monitors available for automatic capture.';
  static const errorDisplayDisconnected =
      'The selected display was disconnected.';
  static const errorPermissionRevoked =
      'Screen Recording permission was revoked.';

  static const debugInfoTitle = 'Debug info';
  static const details = 'Details';
  static const close = 'Close';

  static String diagnosticsSummary(String summary) => 'Diagnostics: $summary';

  static String recordingStatus(Duration elapsed, int count) =>
      'Recording · ${formatDuration(elapsed)} · $count screenshots saved';

  static String floatingRecordingStatus(Duration elapsed, int count) =>
      'Recording · ${formatDuration(elapsed)} · $count shots';

  static String completedDuration(Duration elapsed) =>
      '$totalCaptureDurationPrefix${formatDurationMinutesSeconds(elapsed)}';

  static String launchPermissionExplanation() {
    if (Platform.isMacOS) {
      return macPermissionExplanation;
    }
    if (Platform.isWindows) {
      return windowsPermissionExplanation;
    }
    if (Platform.isLinux) {
      return linuxPermissionExplanation;
    }
    return macPermissionExplanation;
  }

  static String permissionRequiredTitleForPlatform() {
    if (Platform.isMacOS) {
      return permissionRequiredTitle;
    }
    if (Platform.isWindows) {
      return windowsPermissionRequiredTitle;
    }
    if (Platform.isLinux) {
      return linuxPermissionRequiredTitle;
    }
    return permissionRequiredTitle;
  }

  static String? openSettingsLabelForPlatform() {
    if (Platform.isMacOS) {
      return openScreenRecordingSettings;
    }
    if (Platform.isWindows) {
      return openPrivacySettings;
    }
    return null;
  }

  static String permissionDeniedFallbackGuidance() {
    if (Platform.isMacOS) {
      return 'Enable Screen Recording for Oxy Capture in System Settings.';
    }
    if (Platform.isWindows) {
      return 'Enable screen capture for Oxy Capture in Windows Privacy settings.';
    }
    return 'Grant screen capture permission and retry.';
  }

  static String permissionLabel(PermissionState? state) {
    return switch (state) {
      PermissionState.granted => permissionGranted,
      PermissionState.denied => permissionDenied,
      PermissionState.restartRequired => permissionRestartRequired,
      PermissionState.reauthorizeInSettings => permissionReauthorizeInSettings,
      PermissionState.restricted => permissionRestricted,
      PermissionState.revoked => permissionRevoked,
      PermissionState.unknown || null => permissionUnknown,
    };
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  static String formatDurationMinutesSeconds(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }
}