import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oxy_capture/app.dart';
import 'package:oxy_capture/constants/app_strings.dart';
import 'package:oxy_capture/services/session_storage.dart';
import 'package:oxy_capture/services/tray_service.dart';
import 'package:oxy_capture/services/window_lifecycle_service.dart';

void main() {
  testWidgets('App launches welcome dialog on all desktop platforms',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      OxyCaptureApp(
        capture: MockScreenshotCapture(
          permissionGranted: false,
          captureDelay: Duration.zero,
        ),
        storage: SessionStorage(),
        trayService: NoOpTrayService(),
        windowLifecycleService: NoOpWindowLifecycleService(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.launchDialogTitle), findsOneWidget);
    expect(find.text(AppStrings.consentCheckbox), findsNothing);
    expect(find.text(AppStrings.selectMonitor), findsNothing);
  });
}
