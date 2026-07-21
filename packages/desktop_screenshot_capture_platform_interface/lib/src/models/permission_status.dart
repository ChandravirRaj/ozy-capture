import 'package:equatable/equatable.dart';

enum PermissionState {
  unknown,
  granted,
  denied,
  restricted,
  revoked,
  restartRequired,
  reauthorizeInSettings,
}

class PermissionStatus extends Equatable {
  const PermissionStatus({
    required this.state,
    required this.platform,
    this.guidanceMessage,
    this.bundleId,
    this.diagnostics,
  });

  final PermissionState state;
  final String platform;
  final String? guidanceMessage;
  final String? bundleId;
  final Map<String, dynamic>? diagnostics;

  factory PermissionStatus.fromMap(Map<dynamic, dynamic> map) {
    return PermissionStatus(
      state: PermissionState.values.byName(map['state'] as String),
      platform: map['platform'] as String,
      guidanceMessage: map['guidanceMessage'] as String?,
      bundleId: map['bundleId'] as String?,
      diagnostics: (map['diagnostics'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toMap() => {
        'state': state.name,
        'platform': platform,
        if (guidanceMessage != null) 'guidanceMessage': guidanceMessage,
        if (bundleId != null) 'bundleId': bundleId,
        if (diagnostics != null) 'diagnostics': diagnostics,
      };

  bool get isUsable => state == PermissionState.granted;

  String? get diagnosticsSummary {
    final details = diagnostics;
    if (details == null || details.isEmpty) {
      return null;
    }
    final parts = <String>[
      if (details['preflight'] != null) 'preflight=${details['preflight']}',
      if (details['requestGranted'] != null) 'request=${details['requestGranted']}',
      if (details['shareableContentError'] != null)
        'probeError=${details['shareableContentError']}',
      if (details['shareableContentTimedOut'] == true) 'probeTimedOut=true',
      if (details['cdHash'] != null) 'cdHash=${details['cdHash']}',
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  List<Object?> get props =>
      [state, platform, guidanceMessage, bundleId, diagnostics];
}
