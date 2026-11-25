import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;

import '../download/update_downloader.dart';
import '../models/updater_config.dart';
import 'update_content.dart';

/// iOS-style progress dialog.
///
/// With [progress] it shows a progress bar, the downloaded size and a
/// percentage; without it (e.g. while the iOS install is being prepared) it
/// shows an activity indicator and [message].
class CupertinoDownloadDialog extends StatelessWidget {
  final UpdaterConfig config;

  /// Overrides [UpdaterConfig.downloadingText].
  final String? message;

  /// Live download progress. When `null` an activity indicator is shown.
  final ValueListenable<DownloadProgress>? progress;

  /// Shows a Cancel action when set.
  final VoidCallback? onCancel;

  const CupertinoDownloadDialog({
    super.key,
    required this.config,
    this.message,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final text = message ?? config.downloadingText ?? 'Downloading update...';
    final label = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final progress = this.progress;

    if (progress == null) {
      return PopScope(
        canPop: false,
        child: CupertinoAlertDialog(
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 14),
                const SizedBox(height: 16),
                Text(
                  text,
                  style:
                      config.dialogContentStyle ??
                      TextStyle(fontSize: 14, height: 1.4, color: label),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: CupertinoAlertDialog(
        title: Text(text, style: config.dialogTitleStyle),
        content: ValueListenableBuilder<DownloadProgress>(
          valueListenable: progress,
          builder: (context, value, _) {
            final percent = downloadPercentLabel(value);
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: value.fraction,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    color: CupertinoColors.systemBlue.resolveFrom(context),
                    backgroundColor: CupertinoColors.systemFill.resolveFrom(
                      context,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          downloadProgressLabel(config, value),
                          textAlign: TextAlign.start,
                          style:
                              config.dialogContentStyle ??
                              TextStyle(fontSize: 12, color: secondaryLabel),
                        ),
                      ),
                      Text(
                        percent,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryLabel,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          if (onCancel != null)
            CupertinoDialogAction(
              onPressed: onCancel,
              child: Text(
                config.cancelButtonText ?? 'Cancel',
                style: config.buttonTextStyle,
              ),
            ),
        ],
      ),
    );
  }
}
