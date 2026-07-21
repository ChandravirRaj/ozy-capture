import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_screenshot_capture_platform.dart';
import 'models/capture_error.dart';
import 'models/capture_event.dart';
import 'models/capture_phase.dart';
import 'models/capture_session.dart';
import 'models/capture_source.dart';
import 'models/permission_status.dart';
import 'models/screenshot_result.dart';

class MethodChannelDesktopScreenshotCapture
    extends DesktopScreenshotCapturePlatform {
  MethodChannelDesktopScreenshotCapture({
    @visibleForTesting MethodChannel? methodChannel,
    @visibleForTesting EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ??
            const MethodChannel('dev.oxy.screen_capture/desktop_screenshot_capture'),
        _eventChannel = eventChannel ??
            const EventChannel('dev.oxy.screen_capture/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<CaptureEvent>? _events;

  Future<T> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      final result = await _methodChannel.invokeMethod<T>(method, args);
      return result as T;
    } on PlatformException catch (error) {
      throw CaptureError.fromPlatformException(
        code: error.code,
        message: error.message ?? 'Platform error',
        details: error.details?.toString(),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _methodChannel.invokeMethod<void>('dispose');
    _events = null;
  }

  @override
  Future<PermissionStatus> getPermissionStatus() async {
    final map = await _invoke<Map<dynamic, dynamic>>('getPermissionStatus');
    return PermissionStatus.fromMap(map);
  }

  @override
  Future<List<CaptureSource>> listMonitors() async {
    final list = await _invoke<List<dynamic>>('listMonitors');
    return list
        .cast<Map<dynamic, dynamic>>()
        .map(CaptureSource.fromMap)
        .toList();
  }

  @override
  Future<CaptureSource?> selectMonitor({CaptureSource? source}) async {
    final map = await _invoke<Map<dynamic, dynamic>?>(
      'selectMonitor',
      source?.toMap(),
    );
    if (map == null) {
      return null;
    }
    return CaptureSource.fromMap(map);
  }

  @override
  Future<CaptureSession> prepareCapture({
    required CaptureSource source,
    required String sessionId,
  }) async {
    final map = await _invoke<Map<dynamic, dynamic>>(
      'prepareCapture',
      {
        'sourceId': source.id,
        'sessionId': sessionId,
        'source': source.toMap(),
      },
    );
    return CaptureSession.fromMap(map);
  }

  @override
  Future<ScreenshotResult> takeScreenshot({
    required String sessionId,
    required String outputPath,
    required ScreenshotFormat format,
    required int quality,
  }) async {
    final map = await _invoke<Map<dynamic, dynamic>>(
      'takeScreenshot',
      {
        'sessionId': sessionId,
        'outputPath': outputPath,
        'format': format.channelName,
        'quality': quality,
      },
    );
    return ScreenshotResult.fromMap(map);
  }

  @override
  Future<void> stopCapture(String sessionId) async {
    await _invoke<void>('stopCapture', {'sessionId': sessionId});
  }

  @override
  Stream<CaptureEvent> watchEvents() {
    return _events ??= _eventChannel.receiveBroadcastStream().map((event) {
      return captureEventFromMap(event as Map<dynamic, dynamic>);
    });
  }
}
