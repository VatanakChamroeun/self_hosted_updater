import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_updater/src/download/update_downloader.dart';
import 'package:flutter_custom_updater/src/models/dialog_style.dart';
import 'package:flutter_custom_updater/src/models/update_info.dart';
import 'package:flutter_custom_updater/src/models/updater_config.dart';
import 'package:flutter_custom_updater/src/platform/install_permission.dart';
import 'package:flutter_custom_updater/src/utils/update_utils.dart';
import 'package:flutter_custom_updater/src/widgets/cupertino_download_dialog.dart';
import 'package:flutter_custom_updater/src/widgets/cupertino_update_dialog.dart';
import 'package:flutter_custom_updater/src/widgets/download_sheet.dart';
import 'package:flutter_custom_updater/src/widgets/material_download_dialog.dart';
import 'package:flutter_custom_updater/src/widgets/material_update_dialog.dart';
import 'package:flutter_custom_updater/src/widgets/update_content.dart';
import 'package:flutter_custom_updater/src/widgets/update_message_prompt.dart';
import 'package:flutter_custom_updater/src/widgets/update_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdater {
  final BuildContext context;
  final UpdaterConfig config;

  AppUpdater({required this.context, required this.config});

  /// Main method to check and update app (works for both Android & iOS)
  Future<void> checkAndUpdate() async {
    final UpdateInfo updateInfo;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      updateInfo = await _checkForUpdate(packageInfo.version);
    } catch (e) {
      _reportError('Failed to check for updates: $e');
      return;
    }

    if (!updateInfo.hasUpdate) {
      config.onNoUpdateAvailable?.call();
      return;
    }

    // The caller's widget may have been disposed while the request was in flight.
    if (!context.mounted) return;

    try {
      final shouldUpdate = await _showUpdateDialog(updateInfo);
      if (shouldUpdate != true || !context.mounted) return;

      if (Platform.isAndroid) {
        await _downloadAndInstallApk(updateInfo);
      } else if (Platform.isIOS) {
        await _handleIosUpdate(updateInfo);
      }
    } catch (e) {
      _reportError(e.toString());
    }
  }

  void _reportError(String message) {
    _notifyError(message);
    debugPrint('AppUpdater Error: $message');
  }

  /// Passes a human readable message (without `Exception: ` noise) to
  /// [UpdaterConfig.onError].
  void _notifyError(String message) {
    config.onError?.call(readableError(message));
  }

  String _getLanguageCode() {
    // If language is explicitly set in config, use it
    if (config.language != null && config.language!.isNotEmpty) {
      return config.language!;
    }

    // Otherwise, try to get from device locale
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      // Return language code (e.g., 'en', 'km', 'zh')
      return locale.languageCode;
    } catch (e) {
      debugPrint('Failed to get locale: $e');
      return 'en'; // Default to English
    }
  }

  /// Check for update from server
  Future<UpdateInfo> _checkForUpdate(String currentVersion) async {
    final languageCode = _getLanguageCode();

    final headers = {
      'Content-Type': 'application/json',
      'Current-Version': currentVersion,
      'Platform': Platform.isAndroid ? 'android' : 'ios',
      'Accept-Language': languageCode,
      ...?config.customHeaders,
    };

    debugPrint('🌐 Requesting update with language: $languageCode');

    final response = await http
        .get(Uri.parse(config.updateCheckUrl), headers: headers)
        .timeout(
          config.checkTimeout,
          onTimeout: () => throw Exception('Connection timeout'),
        );

    if (response.statusCode != 200) {
      throw Exception('Server returned status code ${response.statusCode}');
    }

    final jsonResponse = json.decode(response.body);
    final data = jsonResponse['data'] ?? jsonResponse;
    return UpdateInfo.fromJson(data);
  }

  /// Show update dialog
  Future<bool?> _showUpdateDialog(UpdateInfo updateInfo) async {
    if (config.dialogStyle == DialogStyle.bottomSheet) {
      // Use bottom sheet for snackbar style
      return await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible:
            config.allowDismiss && !(updateInfo.forceUpdate ?? false),
        enableDrag: config.allowDismiss && !(updateInfo.forceUpdate ?? false),
        builder: (BuildContext context) {
          return UpdateSheet(
            updateInfo: updateInfo,
            config: config,
            onUpdate: () => Navigator.of(context).pop(true),
            onDismiss: (updateInfo.forceUpdate ?? false)
                ? null
                : () => Navigator.of(context).pop(false),
          );
        },
      );
    } else {
      return await showDialog<bool>(
        context: context,
        barrierDismissible:
            config.allowDismiss && !(updateInfo.forceUpdate ?? false),
        builder: (BuildContext context) {
          if (config.dialogStyle == DialogStyle.cupertino) {
            return CupertinoUpdateDialog(
              updateInfo: updateInfo,
              config: config,
            );
          } else {
            return MaterialUpdateDialog(updateInfo: updateInfo, config: config);
          }
        },
      );
    }
  }

  /// Download and install APK (Android)
  Future<void> _downloadAndInstallApk(UpdateInfo updateInfo) async {
    final force = updateInfo.forceUpdate ?? false;

    String filePath;
    while (true) {
      try {
        filePath = await _downloadApk(updateInfo, force: force);
        break;
      } on DownloadCancelledException {
        return;
      } catch (e) {
        _notifyError('Download failed: $e');
        final retry = await _showErrorPrompt(
          'Failed to download update: $e',
          force: force,
        );
        if (!retry) return;
      }
    }

    config.onDownloadComplete?.call(filePath);
    await _installApk(filePath, force: force);
  }

  /// Streams the APK to disk while showing progress. Throws
  /// [DownloadCancelledException] if the user cancels.
  Future<String> _downloadApk(
    UpdateInfo updateInfo, {
    required bool force,
  }) async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('External storage is not available');
    }
    if (!context.mounted) throw const DownloadCancelledException();

    final downloader = UpdateDownloader(
      url: Uri.parse(updateInfo.downloadUrl),
      destination: File(
        p.join(directory.path, sanitizeApkFileName(updateInfo.fileName)),
      ),
      expectedSize: updateInfo.fileSize,
      timeout: config.downloadTimeout,
    );
    final progressRoute = _showBlockingProgress(
      _buildProgress(
        progress: downloader.progress,
        // Forced updates cannot be cancelled.
        onCancel: force ? null : downloader.cancel,
      ),
    );

    try {
      final file = await downloader.start();
      return file.path;
    } finally {
      _closeRoute(progressRoute);
    }
  }

  /// Install APK (Android)
  Future<void> _installApk(String filePath, {required bool force}) async {
    while (context.mounted) {
      if (!await _ensureInstallPermission(force: force)) return;

      try {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception(result.message);
        }
      } catch (e) {
        _notifyError('Installation failed: $e');
        final retry = await _showErrorPrompt(
          'Failed to install update: $e',
          force: force,
        );
        if (retry) continue;
        return;
      }

      config.onInstallStart?.call();
      if (!force) return;

      // Forced update: if the user backs out of the system installer, keep
      // the app blocked and offer to open it again.
      if (!await _showInstallPendingPrompt()) return;
    }
  }

  /// Android 8+: the system refuses APK installs from an app until the user
  /// allows it in Settings. Explain why before sending them there, then wait
  /// until they come back. Returns `false` if the user declined.
  Future<bool> _ensureInstallPermission({required bool force}) async {
    while (!await InstallPermission.isGranted()) {
      final openSettings = await _showPrompt(
        icon: Icons.install_mobile_rounded,
        title: config.installPermissionTitle ?? 'Allow app updates',
        message:
            config.installPermissionMessage ??
            'To install the update, this app needs permission to install '
                'apps. Turn on "Allow from this source", then come back here.',
        primaryLabel: config.openSettingsButtonText ?? 'Open Settings',
        secondaryLabel: force ? null : (config.laterButtonText ?? 'Later'),
      );
      if (!openSettings) return false;

      final returned = _nextResume();
      if (!await InstallPermission.openSettings()) {
        // Settings could not be opened; let the system installer prompt.
        return true;
      }
      await returned;
      if (!context.mounted) return false;
    }
    return true;
  }

  /// Completes the next time the app returns to the foreground.
  Future<void> _nextResume() {
    final resumed = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        listener.dispose();
        if (!resumed.isCompleted) resumed.complete();
      },
    );
    return resumed.future;
  }

  /// Handle iOS update (Enterprise Distribution)
  Future<void> _handleIosUpdate(UpdateInfo updateInfo) async {
    final force = updateInfo.forceUpdate ?? false;

    while (context.mounted) {
      try {
        await _installEnterpriseIpa(updateInfo);
      } catch (e) {
        _notifyError('iOS update failed: $e');
        if (await _showErrorPrompt('Update failed: $e', force: force)) {
          continue;
        }
        return;
      }

      if (!force) return;
      // Forced update: keep the app blocked until the new build replaces it.
      if (!await _showInstallPendingPrompt()) return;
    }
  }

  /// Install Enterprise IPA using itms-services
  Future<void> _installEnterpriseIpa(UpdateInfo updateInfo) async {
    final progressRoute = _showBlockingProgress(
      _buildProgress(
        message:
            config.iosInstallText ??
            'Preparing installation...\nPlease follow the system prompts.',
      ),
    );

    try {
      // The manifest URL should point to a .plist file on HTTPS server
      final uri = buildItmsServicesUri(
        updateInfo.iosManifestUrl ?? updateInfo.downloadUrl,
      );

      // Small delay so the user can read the message before the system prompt
      await Future<void>.delayed(const Duration(seconds: 1));
      _closeRoute(progressRoute);

      if (!await canLaunchUrl(uri)) {
        throw Exception(
          'Could not launch installation. Please ensure the manifest URL is correct and accessible via HTTPS.',
        );
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      config.onInstallStart?.call();
    } finally {
      _closeRoute(progressRoute);
    }
  }

  /// Progress UI in the configured style. [message] defaults to
  /// [UpdaterConfig.downloadingText]; with [progress] a progress bar is shown.
  WidgetBuilder _buildProgress({
    String? message,
    ValueListenable<DownloadProgress>? progress,
    VoidCallback? onCancel,
  }) {
    return (context) {
      switch (config.dialogStyle) {
        case DialogStyle.bottomSheet:
          return DownloadSheet(
            config: config,
            message: message,
            progress: progress,
            onCancel: onCancel,
          );
        case DialogStyle.cupertino:
          return CupertinoDownloadDialog(
            config: config,
            message: message,
            progress: progress,
            onCancel: onCancel,
          );
        case DialogStyle.material:
          return MaterialDownloadDialog(
            config: config,
            message: message,
            progress: progress,
            onCancel: onCancel,
          );
      }
    };
  }

  /// Pushes a non-dismissible progress UI in the configured style and returns
  /// its route, so it can be closed later with [_closeRoute] regardless of
  /// what else is on the navigator stack.
  Route<void> _showBlockingProgress(WidgetBuilder builder) {
    if (config.dialogStyle == DialogStyle.bottomSheet) {
      final navigator = Navigator.of(context);
      final route = ModalBottomSheetRoute<void>(
        builder: builder,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        barrierLabel: MaterialLocalizations.of(context).scrimLabel,
        backgroundColor: Colors.transparent,
        isScrollControlled: false,
        isDismissible: false,
        enableDrag: false,
      );
      navigator.push(route);
      return route;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierDismissible: false,
    );
    navigator.push(route);
    return route;
  }

  /// Closes [route] if it is still showing. Safe to call more than once.
  void _closeRoute(Route<void> route) {
    final navigator = route.navigator;
    if (navigator == null || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  /// Shows a [UpdateMessagePrompt] in the configured style. Resolves to
  /// `true` when the primary action is chosen.
  Future<bool> _showPrompt({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    String? secondaryLabel,
    UpdatePromptTone tone = UpdatePromptTone.info,
  }) async {
    if (!context.mounted) return false;
    final dismissible = secondaryLabel != null;

    Widget builder(BuildContext _) => UpdateMessagePrompt(
      config: config,
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
    );

    final result = config.dialogStyle == DialogStyle.bottomSheet
        ? await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: Colors.transparent,
            isDismissible: dismissible,
            enableDrag: dismissible,
            builder: builder,
          )
        : await showDialog<bool>(
            context: context,
            barrierDismissible: dismissible,
            builder: builder,
          );
    return result ?? false;
  }

  /// Error with a Retry action. Forced updates offer only Retry, so the app
  /// stays blocked until the update succeeds. Resolves to `true` on Retry.
  Future<bool> _showErrorPrompt(String message, {required bool force}) {
    return _showPrompt(
      icon: Icons.error_outline_rounded,
      tone: UpdatePromptTone.error,
      title: config.errorTitle ?? 'Update failed',
      message: readableError(message),
      primaryLabel: config.retryButtonText ?? 'Retry',
      secondaryLabel: force ? null : (config.closeButtonText ?? 'Close'),
    );
  }

  /// Forced updates: shown once the installer was opened. Resolves to `true`
  /// when the user asks to open the installer again.
  Future<bool> _showInstallPendingPrompt() {
    return _showPrompt(
      icon: Icons.system_update_rounded,
      title: config.installPendingTitle ?? 'Finish updating',
      message:
          config.installPendingMessage ??
          'Install the new version to keep using the app.',
      primaryLabel: config.installButtonText ?? 'Install',
    );
  }
}
