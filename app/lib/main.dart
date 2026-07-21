import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/session_storage.dart';
import 'services/window_lifecycle_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeWindowManager();
  final capture = createDesktopScreenshotCapture();
  runApp(
    OxyCaptureApp(
      capture: capture,
      storage: SessionStorage(),
    ),
  );
}
