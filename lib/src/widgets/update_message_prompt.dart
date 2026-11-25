import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/dialog_style.dart';
import '../models/updater_config.dart';
import 'update_content.dart';

/// Tone of an [UpdateMessagePrompt]; controls its icon colours.
enum UpdatePromptTone { info, error }

/// A short message with one or two actions, drawn in the configured
/// [DialogStyle]. Used for errors (with Retry), the Android install
/// permission explanation and the forced-update install gate.
///
/// Pops `true` for the primary action and `false` for the secondary one.
class UpdateMessagePrompt extends StatelessWidget {
  final UpdaterConfig config;
  final IconData icon;
  final UpdatePromptTone tone;
  final String title;
  final String message;
  final String primaryLabel;

  /// Omit to show only the primary action (e.g. forced updates).
  final String? secondaryLabel;

  const UpdateMessagePrompt({
    super.key,
    required this.config,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.secondaryLabel,
    this.tone = UpdatePromptTone.info,
  });

  @override
  Widget build(BuildContext context) {
    void pop(bool value) => Navigator.of(context).pop(value);

    final child = switch (config.dialogStyle) {
      DialogStyle.cupertino => _buildCupertino(context, pop),
      DialogStyle.bottomSheet => _buildSheet(context, pop),
      DialogStyle.material => _buildMaterial(context, pop),
    };
    return PopScope(canPop: secondaryLabel != null, child: child);
  }

  Widget _buildMaterial(BuildContext context, void Function(bool) pop) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isError = tone == UpdatePromptTone.error;

    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isError ? scheme.errorContainer : scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: isError ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: config.dialogTitleStyle,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style:
            config.dialogContentStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
      ),
      actions: [
        if (secondaryLabel != null)
          TextButton(
            onPressed: () => pop(false),
            style: config.laterButtonStyle,
            child: Text(secondaryLabel!, style: config.buttonTextStyle),
          ),
        FilledButton(
          onPressed: () => pop(true),
          style: config.updateButtonStyle,
          child: Text(primaryLabel, style: config.buttonTextStyle),
        ),
      ],
    );
  }

  Widget _buildCupertino(BuildContext context, void Function(bool) pop) {
    return CupertinoAlertDialog(
      title: Text(title, style: config.dialogTitleStyle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message, style: config.dialogContentStyle),
      ),
      actions: [
        if (secondaryLabel != null)
          CupertinoDialogAction(
            onPressed: () => pop(false),
            child: Text(secondaryLabel!, style: config.buttonTextStyle),
          ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => pop(true),
          child: Text(primaryLabel, style: config.buttonTextStyle),
        ),
      ],
    );
  }

  Widget _buildSheet(BuildContext context, void Function(bool) pop) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isError = tone == UpdatePromptTone.error;
    // Buttons keep the normal accent; only the icon signals an error, so a
    // retry doesn't look like a destructive action.
    final accent = config.sheetAccentColor ?? scheme.primary;
    final onAccent = config.sheetAccentColor != null
        ? onColor(accent)
        : scheme.onPrimary;
    final iconColor = isError ? scheme.error : accent;

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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style:
                      config.dialogTitleStyle ??
                      theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style:
                config.dialogContentStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (secondaryLabel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pop(false),
                    style:
                        config.laterButtonStyle ??
                        OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                    child: Text(secondaryLabel!, style: config.buttonTextStyle),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () => pop(true),
                  style:
                      config.updateButtonStyle ??
                      FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: accent,
                        foregroundColor: onAccent,
                      ),
                  child: Text(primaryLabel, style: config.buttonTextStyle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
