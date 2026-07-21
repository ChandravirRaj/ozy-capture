import 'capture_phase.dart';
import 'capture_source.dart';

sealed class CaptureEvent {}

class CapturePhaseChanged extends CaptureEvent {
  CapturePhaseChanged({
    required this.sessionId,
    required this.phase,
  });

  final String sessionId;
  final CapturePhase phase;
}

class SourceDisconnected extends CaptureEvent {
  SourceDisconnected({
    required this.sessionId,
    this.source,
  });

  final String sessionId;
  final CaptureSource? source;
}

class PermissionRevoked extends CaptureEvent {
  PermissionRevoked();
}

class SessionClosed extends CaptureEvent {
  SessionClosed({
    required this.sessionId,
    this.error,
  });

  final String sessionId;
  final String? error;
}

CaptureEvent captureEventFromMap(Map<dynamic, dynamic> map) {
  final type = map['type'] as String;
  switch (type) {
    case 'phaseChanged':
      return CapturePhaseChanged(
        sessionId: map['sessionId'] as String,
        phase: CapturePhase.values.byName(map['phase'] as String),
      );
    case 'sourceDisconnected':
      return SourceDisconnected(
        sessionId: map['sessionId'] as String,
        source: map['source'] == null
            ? null
            : CaptureSource.fromMap(map['source'] as Map<dynamic, dynamic>),
      );
    case 'permissionRevoked':
      return PermissionRevoked();
    case 'sessionClosed':
      return SessionClosed(
        sessionId: map['sessionId'] as String,
        error: map['error'] as String?,
      );
    default:
      throw ArgumentError('Unknown capture event type: $type');
  }
}

Map<String, dynamic> captureEventToMap(CaptureEvent event) {
  switch (event) {
    case CapturePhaseChanged(:final sessionId, :final phase):
      return {
        'type': 'phaseChanged',
        'sessionId': sessionId,
        'phase': phase.name,
      };
    case SourceDisconnected(:final sessionId, :final source):
      return {
        'type': 'sourceDisconnected',
        'sessionId': sessionId,
        if (source != null) 'source': source.toMap(),
      };
    case PermissionRevoked():
      return {'type': 'permissionRevoked'};
    case SessionClosed(:final sessionId, :final error):
      return {
        'type': 'sessionClosed',
        'sessionId': sessionId,
        if (error != null) 'error': error,
      };
  }
}
