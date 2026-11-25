import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';

import '../models/update_info.dart';
import '../models/updater_config.dart';
import 'update_content.dart';

/// iOS-style update prompt.
class CupertinoUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final UpdaterConfig config;

  const CupertinoUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final forceUpdate = updateInfo.forceUpdate ?? false;
    final notes = updateInfo.releaseNotes?.trim();
    final blue = CupertinoColors.systemBlue.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final showSize =
        (updateInfo.fileSize ?? 0) > 0 &&
        defaultTargetPlatform == TargetPlatform.android;

    final bodyStyle =
        config.dialogContentStyle ??
        TextStyle(
          fontSize: 13,
          height: 1.4,
          color: CupertinoColors.label.resolveFrom(context),
        );

    return PopScope(
      canPop: !forceUpdate && config.allowDismiss,
      child: CupertinoAlertDialog(
        title: Text(
          config.dialogTitle ?? 'Update Available',
          style: config.dialogTitleStyle,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (updateInfo.version != null || showSize || forceUpdate)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (forceUpdate)
                      UpdateChip(
                        label: requiredUpdateLabel(config),
                        background: CupertinoColors.systemRed
                            .resolveFrom(context)
                            .withValues(alpha: 0.14),
                        foreground: CupertinoColors.systemRed.resolveFrom(
                          context,
                        ),
                      ),
                    if (updateInfo.version != null)
                      UpdateChip(
                        label: versionLabel(config, updateInfo.version!),
                        background: blue.withValues(alpha: 0.14),
                        foreground: blue,
                      ),
                    if (showSize)
                      UpdateChip(
                        label: formatFileSize(updateInfo.fileSize!),
                        background: CupertinoColors.tertiarySystemFill
                            .resolveFrom(context),
                        foreground: secondaryLabel,
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              if (notes != null && notes.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: UpdateReleaseNotes(
                    text: notes,
                    maxHeight: 220,
                    bulletColor: blue,
                    style: bodyStyle,
                  ),
                )
              else
                Text(
                  config.dialogContent ??
                      'A new version is available. Would you like to update now?',
                  style: bodyStyle,
                ),
            ],
          ),
        ),
        actions: [
          if (!forceUpdate)
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                config.laterButtonText ?? 'Later',
                style: config.buttonTextStyle,
              ),
            ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              config.updateButtonText ?? 'Update Now',
              style: config.buttonTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
