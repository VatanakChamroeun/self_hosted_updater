import 'dart:io';

import 'package:flutter/services.dart';

/// Android's "install unknown apps" permission, which an app needs before the
/// system installer will accept an APK it downloaded.
class InstallPermission {
  static const MethodChannel _channel = MethodChannel('flutter_custom_updater');

  /// Whether the app may launch the package installer. Always `true` off
  /// Android or when the native helper is unavailable (the installer then
  /// shows its own prompt, as before).
  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('canRequestPackageInstalls') ??
          true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  /// Opens the system screen where the user can allow this app to install
  /// updates. Returns `false` if the screen could not be opened.
  static Future<bool> openSettings() async {
    try {
      return await _channel.invokeMethod<bool>(
            'openInstallPermissionSettings',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
