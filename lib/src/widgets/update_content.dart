import 'package:flutter/material.dart';

import '../download/update_downloader.dart';
import '../models/updater_config.dart';

/// Formats a byte count as a short human readable size (e.g. `24.4 MB`).
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Removes Dart's `Exception: ` prefixes so error text reads naturally.
String readableError(String message) =>
    message.replaceAll('Exception: ', '').trim();

final RegExp _bulletPattern = RegExp(r'^\s*[-*•]\s+');

/// Renders release notes with light formatting:
/// lines starting with `-`, `*` or `•` become bullet points and lines ending
/// with `:` are emphasised as headings. Long notes scroll within [maxHeight].
class UpdateReleaseNotes extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? bulletColor;
  final double maxHeight;

  const UpdateReleaseNotes({
    super.key,
    required this.text,
    this.style,
    this.bulletColor,
    this.maxHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final lines = text.trim().split('\n');

    final children = <Widget>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
      } else if (_bulletPattern.hasMatch(line)) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: base.copyWith(
                    color: bulletColor ?? base.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.replaceFirst(_bulletPattern, ''),
                    // Dialogs like CupertinoAlertDialog centre text by
                    // default; notes always read start-aligned.
                    textAlign: TextAlign.start,
                    style: base,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final isHeading = trimmed.endsWith(':');
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: isHeading ? 6 : 4),
            child: Text(
              trimmed,
              textAlign: TextAlign.start,
              style: isHeading
                  ? base.copyWith(fontWeight: FontWeight.w600)
                  : base,
            ),
          ),
        );
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// Small rounded label used for the version and download size.
class UpdateChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  const UpdateChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card used by the bottom-sheet ("snackbar") style. Floats above the bottom
/// edge and respects the safe area / gesture bar.
class UpdateSheetCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const UpdateSheetCard({super.key, required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          color: backgroundColor ?? scheme.surfaceContainerLow,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}

/// Picks a readable foreground colour for text drawn on [background].
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;

/// `Version 1.2.3`, using [UpdaterConfig.versionText] when set.
String versionLabel(UpdaterConfig config, String version) =>
    (config.versionText ?? 'Version {version}').replaceAll(
      '{version}',
      version,
    );

/// `Required update`, using [UpdaterConfig.requiredUpdateText] when set.
String requiredUpdateLabel(UpdaterConfig config) =>
    config.requiredUpdateText ?? 'Required update';

/// `12.3 MB of 42.5 MB` (or just `12.3 MB` when the total is unknown).
String downloadProgressLabel(UpdaterConfig config, DownloadProgress progress) {
  final received = formatFileSize(progress.received);
  final total = progress.total;
  if (total == null || total <= 0) return received;
  return (config.downloadProgressText ?? '{received} of {total}')
      .replaceAll('{received}', received)
      .replaceAll('{total}', formatFileSize(total));
}

/// `27%`, or an empty string when the total size is unknown.
String downloadPercentLabel(DownloadProgress progress) {
  final fraction = progress.fraction;
  return fraction == null ? '' : '${(fraction * 100).floor()}%';
}
