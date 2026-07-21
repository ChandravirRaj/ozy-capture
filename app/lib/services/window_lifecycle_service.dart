import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../constants/app_strings.dart';

typedef WindowCloseCallback = void Function();

enum WindowDisplayMode {
  full,
  floating,
  hidden,
}

abstract class WindowLifecycleServiceBase {
  Future<void> initialize({required WindowCloseCallback onWindowClose});

  Future<void> setBackgroundModeEnabled(bool enabled);

  Future<void> enterFloatingMode();

  Future<void> exitFloatingMode();

  Future<void> hide();

  Future<void> show();

  Future<void> destroy();
}

class NoOpWindowLifecycleService implements WindowLifecycleServiceBase {
  @override
  Future<void> destroy() async {}

  @override
  Future<void> enterFloatingMode() async {}

  @override
  Future<void> exitFloatingMode() async {}

  @override
  Future<void> hide() async {}

  @override
  Future<void> initialize({required WindowCloseCallback onWindowClose}) async {}

  @override
  Future<void> setBackgroundModeEnabled(bool enabled) async {}

  @override
  Future<void> show() async {}
}

class WindowLifecycleService with WindowListener
    implements WindowLifecycleServiceBase {
  WindowCloseCallback? _onWindowClose;
  bool _initialized = false;
  bool _floating = false;
  Size? _savedSize;
  Offset? _savedPosition;
  Size? _savedMinimumSize;

  static const _fullSize = Size(960, 720);
  static const _fullMinimumSize = Size(900, 700);
  static const _floatingSize = Size(320, 88);

  @override
  Future<void> initialize({required WindowCloseCallback onWindowClose}) async {
    if (_initialized) {
      return;
    }
    _onWindowClose = onWindowClose;
    windowManager.addListener(this);
    _initialized = true;
  }

  @override
  Future<void> setBackgroundModeEnabled(bool enabled) async {
    await windowManager.setPreventClose(enabled);
  }

  @override
  Future<void> enterFloatingMode() async {
    if (_floating) {
      await windowManager.show();
      return;
    }

    _savedSize = await windowManager.getSize();
    _savedPosition = await windowManager.getPosition();
    _savedMinimumSize = _fullMinimumSize;

    await windowManager.setMinimumSize(_floatingSize);
    await windowManager.setSize(_floatingSize);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setPosition(await _floatingPosition());
    await windowManager.show();
    await windowManager.focus();
    _floating = true;
  }

  @override
  Future<void> exitFloatingMode() async {
    if (!_floating) {
      await windowManager.show();
      await windowManager.focus();
      return;
    }

    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setMinimumSize(_savedMinimumSize ?? _fullMinimumSize);
    await windowManager.setSize(_savedSize ?? _fullSize);
    if (_savedPosition != null) {
      await windowManager.setPosition(_savedPosition!);
    } else {
      await windowManager.center();
    }
    await windowManager.show();
    await windowManager.focus();
    _floating = false;
  }

  @override
  Future<void> hide() async {
    await windowManager.hide();
  }

  @override
  Future<void> show() async {
    if (_floating) {
      await windowManager.show();
      await windowManager.focus();
      return;
    }
    await exitFloatingMode();
  }

  @override
  Future<void> destroy() async {
    if (!_initialized) {
      return;
    }
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    if (_floating) {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    }
    await windowManager.destroy();
    _initialized = false;
    _floating = false;
  }

  @override
  void onWindowClose() {
    _onWindowClose?.call();
  }

  Future<Offset> _floatingPosition() async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final visibleSize = display.visibleSize ?? display.size;
      return Offset(
        visibleSize.width - _floatingSize.width - 24,
        visibleSize.height - _floatingSize.height - 24,
      );
    } catch (_) {
      return const Offset(24, 24);
    }
  }
}

Future<void> initializeWindowManager() async {
  if (kIsWeb) {
    return;
  }
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(960, 720),
    minimumSize: Size(900, 700),
    center: true,
    title: AppStrings.appName,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

WindowLifecycleServiceBase createWindowLifecycleService() {
  if (kIsWeb) {
    return NoOpWindowLifecycleService();
  }
  return WindowLifecycleService();
}
