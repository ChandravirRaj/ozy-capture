import 'package:equatable/equatable.dart';

enum CaptureErrorCode {
  permissionDenied,
  selectionCancelled,
  captureApiUnavailable,
  sourceDisconnected,
  captureFailed,
  encodingFailed,
  directoryCreationFailed,
  diskWriteFailed,
  diskFull,
  sessionClosed,
}

extension CaptureErrorCodeChannel on CaptureErrorCode {
  String get channelCode {
    switch (this) {
      case CaptureErrorCode.permissionDenied:
        return 'permission_denied';
      case CaptureErrorCode.selectionCancelled:
        return 'selection_cancelled';
      case CaptureErrorCode.captureApiUnavailable:
        return 'capture_api_unavailable';
      case CaptureErrorCode.sourceDisconnected:
        return 'source_disconnected';
      case CaptureErrorCode.captureFailed:
        return 'capture_failed';
      case CaptureErrorCode.encodingFailed:
        return 'encoding_failed';
      case CaptureErrorCode.directoryCreationFailed:
        return 'directory_creation_failed';
      case CaptureErrorCode.diskWriteFailed:
        return 'disk_write_failed';
      case CaptureErrorCode.diskFull:
        return 'disk_full';
      case CaptureErrorCode.sessionClosed:
        return 'session_closed';
    }
  }

  static CaptureErrorCode fromChannelCode(String code) {
    for (final value in CaptureErrorCode.values) {
      if (value.channelCode == code) {
        return value;
      }
    }
    return CaptureErrorCode.captureFailed;
  }
}

class CaptureError extends Equatable implements Exception {
  const CaptureError({
    required this.code,
    required this.message,
    this.debugInfo,
  });

  final CaptureErrorCode code;
  final String message;
  final String? debugInfo;

  factory CaptureError.fromPlatformException({
    required String code,
    required String message,
    String? details,
  }) {
    return CaptureError(
      code: CaptureErrorCodeChannel.fromChannelCode(code),
      message: message,
      debugInfo: details,
    );
  }

  @override
  List<Object?> get props => [code, message, debugInfo];

  @override
  String toString() => 'CaptureError(${code.channelCode}): $message';
}
