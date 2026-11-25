import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/update_info.dart';
import '../models/updater_config.dart';
import 'update_content.dart';

/// Bottom-sheet update prompt (the `DialogStyle.bottomSheet` style).
class UpdateSheet extends StatelessWidget {
  final UpdateInfo updateInfo;
  final UpdaterConfig config;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  const UpdateSheet({
    super.key,
    required this.updateInfo,
    required this.config,
    required this.onUpdate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final forceUpdate = updateInfo.forceUpdate ?? false;
    final canDismiss = !forceUpdate && onDismiss != null;

    final accent = config.sheetAccentColor ?? scheme.primary;
    final onAccent = config.sheetAccentColor != null
        ? onColor(accent)
        : scheme.onPrimary;

    final notes = updateInfo.releaseNotes?.trim();
    final hasReleaseNotes = notes != null && notes.isNotEmpty;
    final fallbackText = config.sheetDescription ?? config.dialogContent;

    final subtitle = [
      if (updateInfo.version != null) versionLabel(config, updateInfo.version!),
      if ((updateInfo.fileSize ?? 0) > 0 &&
          defaultTargetPlatform == TargetPlatform.android)
        formatFileSize(updateInfo.fileSize!),
    ].join('  ·  ');

    final bodyStyle =
        config.dialogContentStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.4,
        );

    return UpdateSheetCard(
      backgroundColor: config.sheetBackgroundColor,
      child: Column(
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
                  Icons.system_update_rounded,
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
                      config.dialogTitle ?? 'Update Available',
                      style:
                          config.dialogTitleStyle ??
                          theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canDismiss)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: scheme.onSurfaceVariant,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (forceUpdate) ...[
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: UpdateChip(
                label: requiredUpdateLabel(config),
                icon: Icons.priority_high_rounded,
                background: scheme.errorContainer,
                foreground: scheme.onErrorContainer,
              ),
            ),
          ],
          if (hasReleaseNotes) ...[
            const SizedBox(height: 16),
            UpdateReleaseNotes(
              text: notes,
              maxHeight: 160,
              bulletColor: accent,
              style: bodyStyle,
            ),
          ] else if (fallbackText != null) ...[
            const SizedBox(height: 12),
            Text(fallbackText, style: bodyStyle),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (!forceUpdate) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style:
                        config.laterButtonStyle ??
                        OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                    child: Text(
                      config.laterButtonText ?? 'Later',
                      style: config.buttonTextStyle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: onUpdate,
                  style:
                      config.updateButtonStyle ??
                      FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: accent,
                        foregroundColor: onAccent,
                      ),
                  child: Text(
                    config.updateButtonText ?? 'Update Now',
                    style: config.buttonTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
