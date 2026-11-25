import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../download/update_downloader.dart';
import '../models/updater_config.dart';
import 'update_content.dart';

/// Material progress dialog.
///
/// With [progress] it shows a progress bar, the downloaded size and a
/// percentage; without it (e.g. while the iOS install is being prepared) it
/// shows a spinner and [message].
class MaterialDownloadDialog extends StatelessWidget {
  final UpdaterConfig config;

  /// Overrides [UpdaterConfig.downloadingText].
  final String? message;

  /// Live download progress. When `null` an indeterminate spinner is shown.
  final ValueListenable<DownloadProgress>? progress;

  /// Shows a Cancel button when set.
  final VoidCallback? onCancel;

  const MaterialDownloadDialog({
    super.key,
    required this.config,
    this.message,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = message ?? config.downloadingText ?? 'Downloading update...';
    final progress = this.progress;

    if (progress == null) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                text,
                textAlign: TextAlign.center,
                style:
                    config.dialogContentStyle ??
                    theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(text, style: config.dialogTitleStyle),
        content: ValueListenableBuilder<DownloadProgress>(
          valueListenable: progress,
          builder: (context, value, _) {
            final percent = downloadPercentLabel(value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: value.fraction,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        downloadProgressLabel(config, value),
                        style:
                            config.dialogContentStyle ??
                            theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    if (percent.isNotEmpty)
                      Text(
                        percent,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              style: config.laterButtonStyle,
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
