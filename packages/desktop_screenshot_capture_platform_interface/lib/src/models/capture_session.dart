import 'package:equatable/equatable.dart';

import 'capture_phase.dart';
import 'capture_source.dart';

class CaptureSession extends Equatable {
  const CaptureSession({
    required this.sessionId,
    required this.source,
    required this.phase,
  });

  final String sessionId;
  final CaptureSource source;
  final CapturePhase phase;

  factory CaptureSession.fromMap(Map<dynamic, dynamic> map) {
    return CaptureSession(
      sessionId: map['sessionId'] as String,
      source: CaptureSource.fromMap(map['source'] as Map<dynamic, dynamic>),
      phase: CapturePhase.values.byName(map['phase'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'source': source.toMap(),
        'phase': phase.name,
      };

  @override
  List<Object?> get props => [sessionId, source, phase];
}
