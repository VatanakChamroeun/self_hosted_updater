// Old names from 1.x must keep working (with a deprecation warning) until 3.0.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:self_hosted_updater/self_hosted_updater.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DialogStyle.snackbar is an alias of bottomSheet', () {
    expect(DialogStyle.snackbar, same(DialogStyle.bottomSheet));
    expect(DialogStyle.values, hasLength(3));
  });

  test('old UpdaterConfig parameters map to the new names', () {
    final config = UpdaterConfig(
      updateCheckUrl: 'https://example.com',
      timeout: const Duration(seconds: 7),
      okButtonText: 'OK',
      snackbarBackgroundColor: Colors.white,
      snackbarIconColor: Colors.red,
      snackbarDescription: 'desc',
    );

    expect(config.checkTimeout, const Duration(seconds: 7));
    expect(config.closeButtonText, 'OK');
    expect(config.sheetBackgroundColor, Colors.white);
    expect(config.sheetAccentColor, Colors.red);
    expect(config.sheetDescription, 'desc');

    // Old getters still read the values.
    expect(config.timeout, const Duration(seconds: 7));
    expect(config.okButtonText, 'OK');
    expect(config.snackbarIconColor, Colors.red);
  });

  test('new names win when both are given', () {
    final config = UpdaterConfig(
      updateCheckUrl: 'https://example.com',
      checkTimeout: const Duration(seconds: 3),
      timeout: const Duration(seconds: 7),
      closeButtonText: 'Close',
      okButtonText: 'OK',
    );
    expect(config.checkTimeout, const Duration(seconds: 3));
    expect(config.closeButtonText, 'Close');
  });

  test('defaults are unchanged', () {
    final config = UpdaterConfig(updateCheckUrl: 'https://example.com');
    expect(config.checkTimeout, const Duration(seconds: 30));
    expect(config.downloadTimeout, const Duration(minutes: 5));
    expect(config.dialogStyle, DialogStyle.material);
    expect(config.closeButtonText, isNull);
  });
}
