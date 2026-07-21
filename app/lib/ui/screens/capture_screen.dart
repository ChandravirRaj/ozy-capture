import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/capture/capture_bloc.dart';
import '../../constants/app_strings.dart';
import '../../services/window_lifecycle_service.dart';
import '../widgets/completed_section.dart';
import '../widgets/desktop_launch_flow.dart';
import '../widgets/error_banner.dart';
import '../widgets/floating_capture_controls.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopLaunchFlowListener(
      child: BlocBuilder<CaptureBloc, CaptureState>(
        builder: (context, state) {
          if (state.windowDisplayMode == WindowDisplayMode.floating) {
            return const Scaffold(
              body: FloatingCaptureControls(),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.appName),
              actions: [
                if (state.isCapturing)
                  TextButton(
                    onPressed: state.phase == CapturePhase.stopping
                        ? null
                        : () => context
                            .read<CaptureBloc>()
                            .add(const StopCaptureRequested()),
                    child: const Text(AppStrings.stopRecording),
                  ),
              ],
            ),
            body: _buildBody(state),
          );
        },
      ),
    );
  }

  Widget _buildBody(CaptureState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.error != null) ErrorBanner(error: state.error!),
        if (!state.isCapturing && state.phase != CapturePhase.completed)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                AppStrings.trayRunningMessage,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const CompletedSection(),
      ],
    );
  }
}
