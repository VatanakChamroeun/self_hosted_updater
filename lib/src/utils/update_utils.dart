import 'package:path/path.dart' as p;

/// Returns a safe file name for the downloaded APK.
///
/// The name comes from the server, so any directory components are stripped
/// to keep the file inside the app's storage directory.
String sanitizeApkFileName(String? fileName) {
  const fallback = 'app_update.apk';
  if (fileName == null) return fallback;
  final name = p.posix.basename(fileName.trim().replaceAll('\\', '/'));
  if (name.isEmpty || name == '.' || name == '..') return fallback;
  return name;
}

/// Builds the `itms-services` URL that triggers an iOS enterprise install.
///
/// The manifest URL is percent-encoded so manifest URLs that carry their own
/// query string (e.g. signed URLs) are passed through intact.
Uri buildItmsServicesUri(String manifestUrl) {
  return Uri.parse(
    'itms-services://?action=download-manifest'
    '&url=${Uri.encodeComponent(manifestUrl)}',
  );
}
