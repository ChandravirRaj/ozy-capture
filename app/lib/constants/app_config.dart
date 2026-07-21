abstract final class AppConfig {
  static const trayIconAsset = 'assets/tray_icon.png';

  static const trayMenuKeyShow = 'show';
  static const trayMenuKeyStop = 'stop';
  static const trayMenuKeyQuit = 'quit';

  static const macScreenRecordingSettingsUri =
      'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture';
  static const windowsPrivacySettingsUri = 'ms-settings:privacy';

  static const outputBaseFolder = 'OxyCapture';
  static const sessionFolderPrefix = 'session_';
  static const screenshotFilePrefix = 'screenshot_';
  static const sessionTimestampPattern = 'yyyy-MM-dd_HH-mm-ss';
  static const fileTimestampPattern = 'yyyy-MM-dd_HH-mm-ss-SSS';

  static const platformMacOS = 'macOS';
  static const platformWindows = 'Windows';
  static const platformLinuxWayland = 'Linux (Wayland)';
  static const platformLinuxX11 = 'Linux (X11)';
}
