import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/capture/capture_bloc.dart';
import '../../constants/app_strings.dart';

class DesktopLaunchFlowListener extends StatefulWidget {
  const DesktopLaunchFlowListener({super.key, required this.child});

  final Widget child;

  @override
  State<DesktopLaunchFlowListener> createState() =>
      _DesktopLaunchFlowListenerState();
}

class _DesktopLaunchFlowListenerState extends State<DesktopLaunchFlowListener> {
  bool _launchDialogShown = false;
  bool _permissionDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _maybeShowLaunchDialog(context.read<CaptureBloc>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CaptureBloc, CaptureState>(
      listenWhen: (previous, current) =>
          previous.consentAccepted != current.consentAccepted ||
          previous.permissionStatus != current.permissionStatus,
      listener: (context, state) {
        _maybeShowLaunchDialog(state);
        _maybeShowPermissionDeniedDialog(state);
      },
      child: widget.child,
    );
  }

  void _maybeShowLaunchDialog(CaptureState state) {
    if (state.consentAccepted || _launchDialogShown) {
      return;
    }

    _launchDialogShown = true;
    DesktopLaunchFlow.showLaunchDialog(context);
  }

  void _maybeShowPermissionDeniedDialog(CaptureState state) {
    if (!state.consentAccepted ||
        state.permissionStatus?.isUsable == true ||
        state.isCapturing) {
      if (state.permissionStatus?.isUsable == true) {
        _permissionDialogShown = false;
      }
      return;
    }

    if (_permissionDialogShown) {
      return;
    }

    _permissionDialogShown = true;
    DesktopLaunchFlow.showPermissionDeniedDialog(
      context,
      state.permissionStatus!,
    ).whenComplete(() {
      _permissionDialogShown = false;
    });
  }
}

abstract final class DesktopLaunchFlow {
  static Future<void> showLaunchDialog(BuildContext context) {
    final permissionExplanation = AppStrings.launchPermissionExplanation();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.launchDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(AppStrings.consentBody),
                const SizedBox(height: 12),
                const Text(AppStrings.consentWarning),
                const SizedBox(height: 12),
                Text(permissionExplanation),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CaptureBloc>().add(const QuitApplicationRequested());
              },
              child: const Text(AppStrings.launchDialogCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CaptureBloc>().add(const ConsentToggled(true));
              },
              child: const Text(AppStrings.launchDialogContinue),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showPermissionDeniedDialog(
    BuildContext context,
    PermissionStatus status,
  ) {
    final guidance =
        status.guidanceMessage ?? AppStrings.permissionDeniedFallbackGuidance();
    final settingsLabel = AppStrings.openSettingsLabelForPlatform();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppStrings.permissionRequiredTitleForPlatform()),
          content: SingleChildScrollView(
            child: Text(guidance),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CaptureBloc>().add(const QuitApplicationRequested());
              },
              child: const Text(AppStrings.trayQuit),
            ),
            if (settingsLabel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context
                      .read<CaptureBloc>()
                      .add(const OpenScreenRecordingSettingsRequested());
                },
                child: Text(settingsLabel),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context
                    .read<CaptureBloc>()
                    .add(const CheckPermissionRequested());
              },
              child: const Text(AppStrings.retryPermission),
            ),
          ],
        );
      },
    );
  }
}
