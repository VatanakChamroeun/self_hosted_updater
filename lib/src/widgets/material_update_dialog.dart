import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/update_info.dart';
import '../models/updater_config.dart';
import 'update_content.dart';

/// Material 3 update prompt.
class MaterialUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final UpdaterConfig config;

  const MaterialUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final forceUpdate = updateInfo.forceUpdate ?? false;
    final notes = updateInfo.releaseNotes?.trim();
    final showSize =
        (updateInfo.fileSize ?? 0) > 0 &&
        defaultTargetPlatform == TargetPlatform.android;

    return PopScope(
      canPop: !forceUpdate && config.allowDismiss,
      child: AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.system_update_rounded,
            size: 28,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          config.dialogTitle ?? 'Update Available',
          textAlign: TextAlign.center,
          style: config.dialogTitleStyle,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (updateInfo.version != null || showSize || forceUpdate)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (forceUpdate)
                      UpdateChip(
                        label: requiredUpdateLabel(config),
                        background: scheme.errorContainer,
                        foreground: scheme.onErrorContainer,
                      ),
                    if (updateInfo.version != null)
                      UpdateChip(
                        label: versionLabel(config, updateInfo.version!),
                        background: scheme.secondaryContainer,
                        foreground: scheme.onSecondaryContainer,
                      ),
                    if (showSize)
                      UpdateChip(
                        label: formatFileSize(updateInfo.fileSize!),
                        background: scheme.surfaceContainerHighest,
                        foreground: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              if (notes != null && notes.isNotEmpty)
                UpdateReleaseNotes(
                  text: notes,
                  maxHeight: 220,
                  bulletColor: scheme.primary,
                  style:
                      config.dialogContentStyle ??
                      theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                )
              else
                Text(
                  config.dialogContent ??
                      'A new version is available. Would you like to update now?',
                  textAlign: TextAlign.center,
                  style:
                      config.dialogContentStyle ??
                      theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: config.laterButtonStyle,
              child: Text(
                config.laterButtonText ?? 'Later',
                style: config.buttonTextStyle,
              ),
            ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: config.updateButtonStyle,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              config.updateButtonText ?? 'Update Now',
              style: config.buttonTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
