import 'package:desktop_screenshot_capture/desktop_screenshot_capture.dart';
import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});

  final CaptureError error;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      content: Text('${error.message} (${error.code.name})'),
      actions: [
        if (error.debugInfo != null)
          TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(AppStrings.debugInfoTitle),
                  content: Text(error.debugInfo!),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(AppStrings.close),
                    ),
                  ],
                ),
              );
            },
            child: const Text(AppStrings.details),
          ),
      ],
    );
  }
}
