import 'dart:io';

import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/capture/capture_bloc.dart';
import '../../constants/app_strings.dart';

class SetupSection extends StatelessWidget {
  const SetupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaptureBloc, CaptureState>(
      builder: (context, state) {
        if (!state.consentAccepted) {
          return const SizedBox.shrink();
        }

        final permission = state.permissionStatus;
        final needsPermissionAction =
            permission != null && !permission.isUsable;
        final isRecording = state.isCapturing;
        final showPermissionDetails = !isRecording;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.captureSetupTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (showPermissionDetails) ...[
                  _InfoRow(
                    label: AppStrings.platformLabel,
                    value: state.platformLabel,
                  ),
                  _InfoRow(
                    label: AppStrings.permissionStatusLabel,
                    value: AppStrings.permissionLabel(permission?.state),
                  ),
                  if (permission?.bundleId != null) ...[
                    _InfoRow(
                      label: AppStrings.appIdentifierLabel,
                      value: permission!.bundleId!,
                    ),
                  ],
                  if (permission?.guidanceMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: permission!.state == PermissionState.granted
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : permission.state ==
                                        PermissionState.restartRequired ||
                                    permission.state ==
                                        PermissionState.reauthorizeInSettings
                                ? Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer
                                : Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(permission.guidanceMessage!),
                    ),
                  ],
                  if (permission?.diagnosticsSummary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.diagnosticsSummary(
                        permission!.diagnosticsSummary!,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (needsPermissionAction) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context
                              .read<CaptureBloc>()
                              .add(const CheckPermissionRequested()),
                          icon: const Icon(Icons.refresh),
                          label: const Text(AppStrings.refreshPermissionStatus),
                        ),
                        if (Platform.isMacOS)
                          OutlinedButton.icon(
                            onPressed: () => context.read<CaptureBloc>().add(
                                  const OpenScreenRecordingSettingsRequested(),
                                ),
                            icon: const Icon(Icons.settings),
                            label: const Text(
                              AppStrings.openScreenRecordingSettings,
                            ),
                          ),
                        if (Platform.isWindows)
                          OutlinedButton.icon(
                            onPressed: () => context.read<CaptureBloc>().add(
                                  const OpenScreenRecordingSettingsRequested(),
                                ),
                            icon: const Icon(Icons.settings),
                            label: const Text(AppStrings.openPrivacySettings),
                          ),
                      ],
                    ),
                  ],
                  if (state.backgroundModeEnabled && !isRecording) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(AppStrings.autoCaptureHint),
                    ),
                  ],
                ],
                if (isRecording) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.phase == CapturePhase.stopping
                          ? AppStrings.stoppingCapture
                          : AppStrings.recordingStatus(
                              state.elapsed,
                              state.screenshotCount,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _InfoRow(
                  label: AppStrings.selectedMonitorLabel,
                  value: state.selectedSource?.label ?? AppStrings.none,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: state.intervalSeconds,
                  decoration: const InputDecoration(
                    labelText: AppStrings.screenshotIntervalLabel,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 5,
                      child: Text(AppStrings.interval5Seconds),
                    ),
                    DropdownMenuItem(
                      value: 10,
                      child: Text(AppStrings.interval10Seconds),
                    ),
                    DropdownMenuItem(
                      value: 15,
                      child: Text(AppStrings.interval15Seconds),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text(AppStrings.interval30Seconds),
                    ),
                    DropdownMenuItem(
                      value: 60,
                      child: Text(AppStrings.interval60Seconds),
                    ),
                  ],
                  onChanged: isRecording
                      ? null
                      : (value) {
                          if (value != null) {
                            context
                                .read<CaptureBloc>()
                                .add(IntervalChanged(value));
                          }
                        },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ScreenshotFormat>(
                  value: state.format,
                  decoration: const InputDecoration(
                    labelText: AppStrings.imageFormatLabel,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ScreenshotFormat.jpeg,
                      child: Text(AppStrings.formatJpeg),
                    ),
                    DropdownMenuItem(
                      value: ScreenshotFormat.png,
                      child: Text(AppStrings.formatPng),
                    ),
                  ],
                  onChanged: isRecording
                      ? null
                      : (value) {
                          if (value != null) {
                            context
                                .read<CaptureBloc>()
                                .add(FormatChanged(value));
                          }
                        },
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: AppStrings.outputFolderLabel,
                  value: state.outputFolder ?? AppStrings.notCreatedYet,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isRecording)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                        ),
                        onPressed: state.phase == CapturePhase.stopping
                            ? null
                            : () => context
                                .read<CaptureBloc>()
                                .add(const StopCaptureRequested()),
                        child: const Text(AppStrings.stopRecording),
                      )
                    else ...[
                      FilledButton(
                        onPressed: state.canSelectMonitor && !state.isBusy
                            ? () => _selectMonitor(context, state)
                            : null,
                        child: state.isBusy &&
                                state.phase == CapturePhase.selectingSource
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(AppStrings.selectMonitor),
                      ),
                      FilledButton(
                        onPressed: state.canStartCapture
                            ? () => context
                                .read<CaptureBloc>()
                                .add(const StartCaptureRequested())
                            : null,
                        child: const Text(AppStrings.startCapture),
                      ),
                    ],
                    if (isRecording && state.backgroundModeEnabled)
                      OutlinedButton(
                        onPressed: () => context
                            .read<CaptureBloc>()
                            .add(const TrayHideWindowRequested()),
                        child: const Text(AppStrings.hideToFloatingBar),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectMonitor(BuildContext context, CaptureState state) async {
    final bloc = context.read<CaptureBloc>();
    bloc.add(const SelectMonitorRequested());

    final nextState = await bloc.stream.firstWhere(
      (s) =>
          (!s.isBusy && s.availableMonitors.isNotEmpty) ||
          s.error != null ||
          (s.phase == CapturePhase.failed),
    );

    if (!context.mounted) {
      return;
    }

    if (nextState.error != null) {
      return;
    }

    final monitors = nextState.availableMonitors;
    if (monitors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.noMonitorsAvailable)),
      );
      return;
    }

    final selected = await showDialog<CaptureSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.selectMonitorTitle),
        content: SizedBox(
          width: 420,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: monitors.length,
            itemBuilder: (context, index) {
              final monitor = monitors[index];
              return ListTile(
                title: Text(monitor.label),
                subtitle: Text(
                  monitor.isPrimary
                      ? AppStrings.primaryDisplay
                      : AppStrings.secondaryDisplay,
                ),
                onTap: () => Navigator.pop(context, monitor),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );

    if (selected != null) {
      bloc.add(MonitorSelected(selected));
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
