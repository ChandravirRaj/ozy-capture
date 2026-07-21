import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/capture/capture_bloc.dart';
import 'constants/app_strings.dart';
import 'services/session_storage.dart';
import 'services/tray_service.dart';
import 'services/window_lifecycle_service.dart';
import 'ui/screens/capture_screen.dart';

class OxyCaptureApp extends StatelessWidget {
  const OxyCaptureApp({
    super.key,
    required this.capture,
    required this.storage,
    this.trayService,
    this.windowLifecycleService,
  });

  final DesktopScreenshotCapture capture;
  final SessionStorage storage;
  final TrayServiceBase? trayService;
  final WindowLifecycleServiceBase? windowLifecycleService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CaptureBloc(
        capture: capture,
        storage: storage,
        trayService: trayService,
        windowLifecycleService: windowLifecycleService,
      ),
      child: MaterialApp(
        title: AppStrings.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const CaptureScreen(),
      ),
    );
  }
}
