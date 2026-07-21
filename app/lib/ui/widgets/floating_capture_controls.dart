import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/capture/capture_bloc.dart';
import '../../constants/app_strings.dart';

class FloatingCaptureControls extends StatelessWidget {
  const FloatingCaptureControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaptureBloc, CaptureState>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;

        return Material(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  color: colorScheme.error,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.floatingRecordingStatus(
                      state.elapsed,
                      state.screenshotCount,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: state.phase == CapturePhase.stopping
                      ? null
                      : () => context
                          .read<CaptureBloc>()
                          .add(const StopCaptureRequested()),
                  child: const Text(AppStrings.stopRecording),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
