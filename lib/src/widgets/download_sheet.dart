import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../download/update_downloader.dart';
import '../models/updater_config.dart';
import 'update_content.dart';

/// Bottom-sheet progress card.
///
/// With [progress] it shows a progress bar, the downloaded size and a
/// percentage; without it (e.g. while the iOS install is being prepared) it
/// shows a spinner and [message].
class DownloadSheet extends StatelessWidget {
  final UpdaterConfig config;

  /// Overrides [UpdaterConfig.downloadingText].
  final String? message;

  /// Live download progress. When `null` a spinner is shown.
  final ValueListenable<DownloadProgress>? progress;

  /// Shows a Cancel button when set.
  final VoidCallback? onCancel;

  const DownloadSheet({
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
    final accent = config.sheetAccentColor ?? scheme.primary;
    final text = message ?? config.downloadingText ?? 'Downloading update...';
    final progress = this.progress;

    if (progress == null) {
      return UpdateSheetCard(
        backgroundColor: config.sheetBackgroundColor,
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style:
                    config.dialogContentStyle ??
                    theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return UpdateSheetCard(
      backgroundColor: config.sheetBackgroundColor,
      child: ValueListenableBuilder<DownloadProgress>(
        valueListenable: progress,
        builder: (context, value, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.downloading_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style:
                              config.dialogTitleStyle ??
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          downloadProgressLabel(config, value),
                          style:
                              config.dialogContentStyle ??
                              theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    downloadPercentLabel(value),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: value.fraction,
                minHeight: 8,
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onCancel,
                    style: config.laterButtonStyle,
                    child: Text(
                      config.cancelButtonText ?? 'Cancel',
                      style: config.buttonTextStyle,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
