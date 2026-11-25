import 'package:flutter/material.dart';
import 'package:self_hosted_updater/src/models/dialog_style.dart';

/// Configuration for [AppUpdater]: where to check for updates, how the update
/// UI looks and what it says, and callbacks for each step.
///
/// Every text option is optional and falls back to English.
class UpdaterConfig {
  // ---------------------------------------------------------------------------
  // Update check
  // ---------------------------------------------------------------------------

  /// URL of your update check endpoint. Required.
  final String updateCheckUrl;

  /// Extra headers sent with the update check (e.g. `Authorization`).
  final Map<String, String>? customHeaders;

  /// Language code sent as `Accept-Language` (e.g. `en`, `km`, `zh`), so the
  /// server can return translated release notes. Defaults to the device
  /// language.
  final String? language;

  /// Maximum time for the update check request. Defaults to 30 seconds.
  final Duration checkTimeout;

  /// Maximum time for the whole APK download (Android). Defaults to 5 minutes.
  final Duration downloadTimeout;

  // ---------------------------------------------------------------------------
  // Appearance
  // ---------------------------------------------------------------------------

  /// Look of the update UI. Defaults to [DialogStyle.material].
  final DialogStyle dialogStyle;

  /// Whether optional updates can be dismissed by tapping outside the prompt
  /// or pressing back. Required updates can never be dismissed.
  final bool allowDismiss;

  /// Background colour of the [DialogStyle.bottomSheet] card.
  final Color? sheetBackgroundColor;

  /// Accent colour (icon and buttons) of the [DialogStyle.bottomSheet] card.
  /// Defaults to the theme's primary colour.
  final Color? sheetAccentColor;

  final TextStyle? dialogTitleStyle;
  final TextStyle? dialogContentStyle;
  final TextStyle? buttonTextStyle;
  final ButtonStyle? updateButtonStyle;
  final ButtonStyle? laterButtonStyle;

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Update prompt title (default `Update Available`).
  final String? dialogTitle;

  /// Shown when the server sends no release notes.
  final String? dialogContent;

  /// [DialogStyle.bottomSheet] only: shown instead of [dialogContent] when the
  /// server sends no release notes.
  final String? sheetDescription;

  final String? updateButtonText;
  final String? laterButtonText;

  /// Version label template; `{version}` is replaced (default `Version {version}`).
  final String? versionText;

  /// Label shown on required updates (default `Required update`).
  final String? requiredUpdateText;

  /// Shown while the APK downloads (default `Downloading update...`).
  final String? downloadingText;

  /// Download size label template; `{received}` and `{total}` are replaced
  /// with formatted sizes (default `{received} of {total}`).
  final String? downloadProgressText;

  final String? cancelButtonText;

  /// iOS: shown while the install is handed to the system.
  final String? iosInstallText;

  /// Title of the error prompt (default `Update failed`).
  final String? errorTitle;

  final String? retryButtonText;

  /// Closes the error prompt (default `Close`). Not shown for required updates.
  final String? closeButtonText;

  /// Android: explanation shown before sending the user to the
  /// "install unknown apps" setting.
  final String? installPermissionTitle;
  final String? installPermissionMessage;
  final String? openSettingsButtonText;

  /// Required updates: shown after the installer was opened, until the update
  /// is installed.
  final String? installPendingTitle;
  final String? installPendingMessage;
  final String? installButtonText;

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  /// The server reported no update.
  final VoidCallback? onNoUpdateAvailable;

  /// Something failed; receives a readable message.
  final void Function(String message)? onError;

  /// Android: the APK finished downloading; receives its file path.
  final void Function(String filePath)? onDownloadComplete;

  /// The system installer was opened.
  final VoidCallback? onInstallStart;

  UpdaterConfig({
    required this.updateCheckUrl,
    this.customHeaders,
    this.language,
    Duration? checkTimeout,
    this.downloadTimeout = const Duration(minutes: 5),
    this.dialogStyle = DialogStyle.material,
    this.allowDismiss = false,
    Color? sheetBackgroundColor,
    Color? sheetAccentColor,
    this.dialogTitleStyle,
    this.dialogContentStyle,
    this.buttonTextStyle,
    this.updateButtonStyle,
    this.laterButtonStyle,
    this.dialogTitle,
    this.dialogContent,
    String? sheetDescription,
    this.updateButtonText,
    this.laterButtonText,
    this.versionText,
    this.requiredUpdateText,
    this.downloadingText,
    this.downloadProgressText,
    this.cancelButtonText,
    this.iosInstallText,
    this.errorTitle,
    this.retryButtonText,
    String? closeButtonText,
    this.installPermissionTitle,
    this.installPermissionMessage,
    this.openSettingsButtonText,
    this.installPendingTitle,
    this.installPendingMessage,
    this.installButtonText,
    this.onNoUpdateAvailable,
    this.onError,
    this.onDownloadComplete,
    this.onInstallStart,
    // Renamed in 2.0.0; kept so existing code keeps compiling.
    @Deprecated('Use checkTimeout. Will be removed in 3.0.0.')
    Duration? timeout,
    @Deprecated('Use closeButtonText. Will be removed in 3.0.0.')
    String? okButtonText,
    @Deprecated('Use sheetBackgroundColor. Will be removed in 3.0.0.')
    Color? snackbarBackgroundColor,
    @Deprecated('Use sheetAccentColor. Will be removed in 3.0.0.')
    Color? snackbarIconColor,
    @Deprecated('Use sheetDescription. Will be removed in 3.0.0.')
    String? snackbarDescription,
  }) : checkTimeout = checkTimeout ?? timeout ?? const Duration(seconds: 30),
       closeButtonText = closeButtonText ?? okButtonText,
       sheetBackgroundColor = sheetBackgroundColor ?? snackbarBackgroundColor,
       sheetAccentColor = sheetAccentColor ?? snackbarIconColor,
       sheetDescription = sheetDescription ?? snackbarDescription;

  @Deprecated('Use checkTimeout. Will be removed in 3.0.0.')
  Duration get timeout => checkTimeout;

  @Deprecated('Use closeButtonText. Will be removed in 3.0.0.')
  String? get okButtonText => closeButtonText;

  @Deprecated('Use sheetBackgroundColor. Will be removed in 3.0.0.')
  Color? get snackbarBackgroundColor => sheetBackgroundColor;

  @Deprecated('Use sheetAccentColor. Will be removed in 3.0.0.')
  Color? get snackbarIconColor => sheetAccentColor;

  @Deprecated('Use sheetDescription. Will be removed in 3.0.0.')
  String? get snackbarDescription => sheetDescription;
}
