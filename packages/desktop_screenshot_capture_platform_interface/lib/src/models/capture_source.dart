import 'package:equatable/equatable.dart';

class CaptureSource extends Equatable {
  const CaptureSource({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.isPrimary,
  });

  final String id;
  final String label;
  final int width;
  final int height;
  final bool isPrimary;

  factory CaptureSource.fromMap(Map<dynamic, dynamic> map) {
    return CaptureSource(
      id: map['id'] as String,
      label: map['label'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      isPrimary: map['isPrimary'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'width': width,
        'height': height,
        'isPrimary': isPrimary,
      };

  @override
  List<Object?> get props => [id, label, width, height, isPrimary];
}
