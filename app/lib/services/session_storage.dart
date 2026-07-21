import 'dart:async';
import 'dart:io';

import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_config.dart';

class SessionStorage {
  SessionStorage({DateFormat? timestampFormat})
      : _timestampFormat = timestampFormat ??
            DateFormat(AppConfig.sessionTimestampPattern);

  final DateFormat _timestampFormat;
  final DateFormat _fileTimestampFormat =
      DateFormat(AppConfig.fileTimestampPattern);

  Future<String> createSessionDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final baseDir =
        Directory(p.join(documents.path, AppConfig.outputBaseFolder));
    final sessionId =
        '${AppConfig.sessionFolderPrefix}${_timestampFormat.format(DateTime.now())}';
    final sessionDir = Directory(p.join(baseDir.path, sessionId));
    await sessionDir.create(recursive: true);
    return sessionDir.path;
  }

  String nextScreenshotPath({
    required String sessionDirectory,
    required ScreenshotFormat format,
  }) {
    final filename =
        '${AppConfig.screenshotFilePrefix}${_fileTimestampFormat.format(DateTime.now())}.${format.fileExtension}';
    return p.join(sessionDirectory, filename);
  }
}

String platformLabel() {
  if (Platform.isMacOS) {
    return AppConfig.platformMacOS;
  }
  if (Platform.isWindows) {
    return AppConfig.platformWindows;
  }
  if (Platform.isLinux) {
    return Platform.environment['XDG_SESSION_TYPE'] == 'wayland'
        ? AppConfig.platformLinuxWayland
        : AppConfig.platformLinuxX11;
  }
  return Platform.operatingSystem;
}
