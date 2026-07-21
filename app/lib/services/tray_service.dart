import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import '../constants/app_config.dart';
import '../constants/app_strings.dart';

typedef TrayActionCallback = void Function();

abstract class TrayServiceBase {
  Future<void> initialize({
    required TrayActionCallback onShowWindow,
    required TrayActionCallback onStopCapture,
    required TrayActionCallback onQuit,
  });

  Future<void> updateTray({required bool capturing});

  Future<void> destroy();
}

class NoOpTrayService implements TrayServiceBase {
  @override
  Future<void> destroy() async {}

  @override
  Future<void> initialize({
    required TrayActionCallback onShowWindow,
    required TrayActionCallback onStopCapture,
    required TrayActionCallback onQuit,
  }) async {}

  @override
  Future<void> updateTray({required bool capturing}) async {}
}

class TrayService with TrayListener implements TrayServiceBase {
  TrayActionCallback? _onShowWindow;
  TrayActionCallback? _onStopCapture;
  TrayActionCallback? _onQuit;
  bool _initialized = false;
  bool _capturing = false;

  @override
  Future<void> initialize({
    required TrayActionCallback onShowWindow,
    required TrayActionCallback onStopCapture,
    required TrayActionCallback onQuit,
  }) async {
    if (_initialized) {
      return;
    }
    _onShowWindow = onShowWindow;
    _onStopCapture = onStopCapture;
    _onQuit = onQuit;

    await trayManager.setIcon(
      AppConfig.trayIconAsset,
      isTemplate: true,
    );
    trayManager.addListener(this);
    await updateTray(capturing: false);
    _initialized = true;
  }

  @override
  Future<void> updateTray({required bool capturing}) async {
    if (!_initialized) {
      return;
    }
    _capturing = capturing;
    await trayManager.setToolTip(
      capturing ? AppStrings.trayCapturingTooltip : AppStrings.trayIdleTooltip,
    );
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: AppConfig.trayMenuKeyShow,
            label: AppStrings.trayOpenApp,
          ),
          MenuItem(
            key: AppConfig.trayMenuKeyStop,
            label: AppStrings.stopRecording,
            disabled: !capturing,
          ),
          MenuItem.separator(),
          MenuItem(
            key: AppConfig.trayMenuKeyQuit,
            label: AppStrings.trayQuit,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> destroy() async {
    if (!_initialized) {
      return;
    }
    trayManager.removeListener(this);
    await trayManager.destroy();
    _initialized = false;
  }

  @override
  void onTrayIconMouseDown() {
    _onShowWindow?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case AppConfig.trayMenuKeyShow:
        _onShowWindow?.call();
      case AppConfig.trayMenuKeyStop:
        if (_capturing) {
          _onStopCapture?.call();
        }
      case AppConfig.trayMenuKeyQuit:
        _onQuit?.call();
    }
  }
}

TrayServiceBase createTrayService() {
  if (kIsWeb) {
    return NoOpTrayService();
  }
  return TrayService();
}
