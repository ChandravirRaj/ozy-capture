import 'dart:async';

typedef CaptureTickCallback = Future<void> Function();

class CaptureScheduler {
  Timer? _timer;
  bool _captureInProgress = false;
  bool _stopped = true;

  bool get captureInProgress => _captureInProgress;
  bool get isRunning => !_stopped;

  void start({
    required Duration interval,
    required CaptureTickCallback onTick,
  }) {
    stop();
    _stopped = false;
    _timer = Timer.periodic(interval, (_) async {
      if (_stopped || _captureInProgress) {
        return;
      }
      _captureInProgress = true;
      try {
        await onTick();
      } finally {
        _captureInProgress = false;
      }
    });
  }

  Future<void> stop({Duration waitTimeout = const Duration(seconds: 30)}) async {
    _stopped = true;
    _timer?.cancel();
    _timer = null;

    final deadline = DateTime.now().add(waitTimeout);
    while (_captureInProgress && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
