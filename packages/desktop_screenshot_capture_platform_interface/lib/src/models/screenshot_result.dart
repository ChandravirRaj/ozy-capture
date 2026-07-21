import 'package:equatable/equatable.dart';

class ScreenshotResult extends Equatable {
  const ScreenshotResult({
    required this.filePath,
    required this.width,
    required this.height,
    required this.bytesWritten,
    required this.capturedAt,
  });

  final String filePath;
  final int width;
  final int height;
  final int bytesWritten;
  final DateTime capturedAt;

  factory ScreenshotResult.fromMap(Map<dynamic, dynamic> map) {
    return ScreenshotResult(
      filePath: map['filePath'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      bytesWritten: map['bytesWritten'] as int,
      capturedAt: DateTime.parse(map['capturedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'filePath': filePath,
        'width': width,
        'height': height,
        'bytesWritten': bytesWritten,
        'capturedAt': capturedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [filePath, width, height, bytesWritten, capturedAt];
}
