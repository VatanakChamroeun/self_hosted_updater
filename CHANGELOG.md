# Changelog

## 2.0.1

- Declare iOS as a supported platform, so pub.dev lists both Android and iOS.
  No behaviour change.

## 2.0.0

### Upgrading from 1.x

The package was renamed from `flutter_custom_updater` to
`self_hosted_updater`. Update the dependency key in `pubspec.yaml` and your
imports:

```dart
// Before
import 'package:flutter_custom_updater/flutter_custom_updater.dart';
// After
import 'package:self_hosted_updater/self_hosted_updater.dart';
```

Renamed options still work in 2.x but show deprecation warnings. They will be
removed in 3.0.0.

| 1.x | 2.0.0 |
| --- | --- |
| `DialogStyle.snackbar` | `DialogStyle.bottomSheet` |
| `UpdaterConfig(timeout:)` | `checkTimeout:` |
| `UpdaterConfig(okButtonText:)` | `closeButtonText:` |
| `UpdaterConfig(snackbarBackgroundColor:)` | `sheetBackgroundColor:` |
| `UpdaterConfig(snackbarIconColor:)` | `sheetAccentColor:` |
| `UpdaterConfig(snackbarDescription:)` | `sheetDescription:` |

Breaking changes without a replacement:

- `UpdateDialog` and `DownloadDialog` are no longer exported. The package now
  shows all of its UI itself; use `UpdaterConfig` to customise it.
- The error prompt's default title is now "Update failed" (was "Error") and
  its dismiss button says "Close" (was "OK"). Set `errorTitle` and
  `closeButtonText` to keep the old wording.
- `onError` messages no longer contain `Exception:` prefixes.
- The package is now a Flutter plugin with a small Android component, so do a
  full rebuild (not a hot restart) after upgrading.
- Android: the storage permissions and the `FileProvider` setup from the 1.x
  README are no longer needed and can be removed.

### New

- Download progress on Android: progress bar, downloaded size and percentage,
  plus a Cancel button. The APK is streamed to disk instead of into memory,
  and a partial download is never installed.
- Retry: failed downloads and installs offer Retry instead of a dead end.
- Android "install unknown apps" guidance: explained before the system would
  block the install, with a button that opens the right Settings screen; the
  installer opens automatically when the user returns.
- Required updates show a "Required update" badge, cannot be cancelled, offer
  only Retry on failure, and keep the app blocked ("Finish updating") if the
  user backs out of the installer.
- Redesigned, theme-aware UI (Material 3 colours and dark mode) for all three
  styles. Release notes render `-`/`*`/`•` lines as bullets and `Heading:`
  lines as headings.
- New text options for translation: `versionText`, `requiredUpdateText`,
  `downloadProgressText`, `cancelButtonText`, `retryButtonText`,
  `closeButtonText`, `installPermissionTitle`, `installPermissionMessage`,
  `openSettingsButtonText`, `installPendingTitle`, `installPendingMessage`,
  `installButtonText`.

### Fixed

- A failed download (e.g. HTTP 404) could close the app's own screen.
- `onError` was called twice when the update check failed.
- Using the updater after the calling screen was closed could crash.
- iOS: manifest URLs with their own query string (e.g. signed URLs) broke the
  install link.
- A file name sent by the server could point outside the app's storage folder.
- A server-reported file size of 0 was shown as "0 B".

### Other

- Dependencies: `mockito` and `cupertino_icons` removed; `path` added;
  `package_info_plus` 9–10 and `open_filex` 4–5 supported.
- Example app updated for current Flutter, Xcode 27 and Android Gradle Plugin 9.
- Mock server: `SLOW_DOWNLOAD_KBPS` and `FORCE_UPDATE` switches for testing.

## 1.0.0

- Initial release as `flutter_custom_updater`: update check against your own server, APK download and
  install on Android, enterprise (itms-services) install on iOS, Material,
  Cupertino and snackbar dialog styles, multi-language release notes.
