import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/capture/capture_bloc.dart';
import '../../constants/app_strings.dart';

class CompletedSection extends StatelessWidget {
  const CompletedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaptureBloc, CaptureState>(
      builder: (context, state) {
        if (state.phase != CapturePhase.completed) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.captureCompletedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(AppStrings.completedDuration(state.elapsed)),
                Text('${AppStrings.totalScreenshotsPrefix}${state.screenshotCount}'),
                const SizedBox(height: 8),
                SelectableText(
                  '${AppStrings.outputFolderPrefix}${state.outputFolder ?? ''}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: state.outputFolder == null
                          ? null
                          : () => context
                              .read<CaptureBloc>()
                              .add(const OpenFolderRequested()),
                      child: const Text(AppStrings.openFolder),
                    ),
                    OutlinedButton(
                      onPressed: () => context
                          .read<CaptureBloc>()
                          .add(const StartNewSessionRequested()),
                      child: const Text(AppStrings.startNewSession),
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
}
