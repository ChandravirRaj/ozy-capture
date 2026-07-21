part of 'capture_bloc.dart';

sealed class CaptureBlocEvent extends Equatable {
  const CaptureBlocEvent();

  @override
  List<Object?> get props => [];
}

final class ConsentToggled extends CaptureBlocEvent {
  const ConsentToggled(this.accepted);

  final bool accepted;

  @override
  List<Object?> get props => [accepted];
}

final class CheckPermissionRequested extends CaptureBlocEvent {
  const CheckPermissionRequested();
}

final class SelectMonitorRequested extends CaptureBlocEvent {
  const SelectMonitorRequested();
}

final class MonitorSelected extends CaptureBlocEvent {
  const MonitorSelected(this.source);

  final CaptureSource source;

  @override
  List<Object?> get props => [source];
}

final class IntervalChanged extends CaptureBlocEvent {
  const IntervalChanged(this.seconds);

  final int seconds;

  @override
  List<Object?> get props => [seconds];
}

final class FormatChanged extends CaptureBlocEvent {
  const FormatChanged(this.format);

  final ScreenshotFormat format;

  @override
  List<Object?> get props => [format];
}

final class StartCaptureRequested extends CaptureBlocEvent {
  const StartCaptureRequested();
}

final class StopCaptureRequested extends CaptureBlocEvent {
  const StopCaptureRequested();
}

final class TickElapsed extends CaptureBlocEvent {
  const TickElapsed(this.elapsed);

  final Duration elapsed;

  @override
  List<Object?> get props => [elapsed];
}

final class ScreenshotSucceeded extends CaptureBlocEvent {
  const ScreenshotSucceeded(this.result);

  final ScreenshotResult result;

  @override
  List<Object?> get props => [result];
}

final class ScreenshotFailed extends CaptureBlocEvent {
  const ScreenshotFailed(this.error);

  final CaptureError error;

  @override
  List<Object?> get props => [error];
}

final class NativeCaptureEventReceived extends CaptureBlocEvent {
  const NativeCaptureEventReceived(this.event);

  final CaptureEvent event;

  @override
  List<Object?> get props => [event];
}

final class OpenFolderRequested extends CaptureBlocEvent {
  const OpenFolderRequested();
}

final class StartNewSessionRequested extends CaptureBlocEvent {
  const StartNewSessionRequested();
}

final class PermissionGrantedBackgroundMode extends CaptureBlocEvent {
  const PermissionGrantedBackgroundMode();
}

final class WindowCloseRequested extends CaptureBlocEvent {
  const WindowCloseRequested();
}

final class TrayShowWindowRequested extends CaptureBlocEvent {
  const TrayShowWindowRequested();
}

final class TrayHideWindowRequested extends CaptureBlocEvent {
  const TrayHideWindowRequested();
}

final class TrayStopCaptureRequested extends CaptureBlocEvent {
  const TrayStopCaptureRequested();
}

final class AutoStartCaptureRequested extends CaptureBlocEvent {
  const AutoStartCaptureRequested();
}

final class OpenScreenRecordingSettingsRequested extends CaptureBlocEvent {
  const OpenScreenRecordingSettingsRequested();
}

final class QuitApplicationRequested extends CaptureBlocEvent {
  const QuitApplicationRequested();
}
