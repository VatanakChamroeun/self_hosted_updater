import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:self_hosted_updater/self_hosted_updater.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _updateStatus = 'No update check performed';
  String _appVersion = 'Loading...';
  String _buildNumber = '';
  String _latestVersion = '...';
  bool _hasUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
  }

  // ============================================================================
  // Version Management
  // ============================================================================

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() => _appVersion = 'Unknown');
    }
  }

  // ============================================================================
  // Update Logic
  // ============================================================================

  String _getServerUrl() {
    // Android Emulator uses 10.0.2.2 to access host's localhost
    // iOS Simulator can use localhost directly
    return Platform.isAndroid
        ? 'http://10.0.2.2:3000/api/check-update'
        : 'http://localhost:3000/api/check-update';
  }

  Future<void> _checkForUpdates() async {
    _setCheckingState();

    try {
      final updateInfo = await _fetchUpdateInfo();
      _handleUpdateInfo(updateInfo);

      if (updateInfo.hasUpdate) {
        await _showUpdateDialog();
      }
    } catch (e) {
      _handleUpdateError(e);
    }
  }

  void _setCheckingState() {
    setState(() {
      _updateStatus = 'Checking for updates...';
      _latestVersion = '...';
      _hasUpdate = false;
    });
  }

  Future<UpdateInfo> _fetchUpdateInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final response = await http
        .get(
          Uri.parse(_getServerUrl()),
          headers: {
            'current-version': currentVersion,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Server returned status code ${response.statusCode}');
    }

    final jsonResponse = json.decode(response.body);
    final responseData = jsonResponse['data'] ?? jsonResponse;

    // Same model the package uses to parse the server response.
    return UpdateInfo.fromJson(responseData);
  }

  void _handleUpdateInfo(UpdateInfo info) {
    setState(() {
      _latestVersion = info.version ?? _appVersion;
      _hasUpdate = info.hasUpdate;
      _updateStatus = info.hasUpdate
          ? '🆕 Update available!'
          : '✅ App is up to date';
    });
  }

  Future<void> _showUpdateDialog() async {
    final updater = AppUpdater(context: context, config: _buildUpdaterConfig());
    await updater.checkAndUpdate();
  }

  /// Dialog style to demo. Override at build time, e.g.
  /// `flutter run --dart-define=DIALOG_STYLE=cupertino`
  /// (material | cupertino | bottomSheet).
  static final DialogStyle _dialogStyle = DialogStyle.values.firstWhere(
    (style) =>
        style.name ==
        const String.fromEnvironment(
          'DIALOG_STYLE',
          defaultValue: 'bottomSheet',
        ),
    orElse: () => DialogStyle.bottomSheet,
  );

  UpdaterConfig _buildUpdaterConfig() {
    return UpdaterConfig(
      dialogStyle: _dialogStyle,
      updateCheckUrl: _getServerUrl(),
      language: 'en', // your current app language
      dialogTitle: 'Update Available! 🚀',
      updateButtonText: 'Update Now',
      laterButtonText: 'Later',
      downloadingText: 'Downloading update...',
      iosInstallText:
          'Preparing installation...\nPlease follow the system prompts.',
      allowDismiss: true,
      onDownloadComplete: _onDownloadComplete,
      onInstallStart: _onInstallStart,
      onError: _onUpdateError,
    );
  }

  void _onDownloadComplete(String path) {
    setState(() => _updateStatus = '✅ Download complete');
  }

  void _onInstallStart() {
    setState(() => _updateStatus = '⚙️ Installing update...');
  }

  void _onUpdateError(String error) {
    setState(() => _updateStatus = '❌ Error occurred');
    _showErrorSnackBar('Update failed: $error');
  }

  void _handleUpdateError(Object error) {
    setState(() {
      _updateStatus = '❌ Connection failed';
      _latestVersion = 'Unknown';
    });
    _showErrorSnackBar('Update check failed: $error');
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        backgroundColor: scheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================================
  // UI Helpers
  // ============================================================================

  bool get _isUpToDate =>
      _latestVersion == _appVersion && _latestVersion != '...';

  Color _getVersionColor(ColorScheme scheme) {
    if (_hasUpdate) return scheme.tertiary;
    if (_isUpToDate) return scheme.primary;
    return scheme.onSurfaceVariant;
  }

  IconData _getStatusIcon() {
    if (_hasUpdate) return Icons.new_releases_rounded;
    if (_updateStatus.contains('✅')) return Icons.check_circle_rounded;
    return Icons.info_outline_rounded;
  }

  // ============================================================================
  // Build Methods
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Hosted Updater Demo'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildStatusCard(context),
                const SizedBox(height: 32),
                _buildCheckUpdateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.system_update_rounded,
            size: 56,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Self-Hosted Updater',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Self-hosted updates for Android & iOS',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAndroid = Platform.isAndroid;

    return Card.filled(
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isAndroid ? Icons.android_rounded : Icons.apple_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  isAndroid ? 'Android (APK)' : 'iOS (IPA)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVersionRow(
              context,
              icon: Icons.smartphone_rounded,
              label: 'Current',
              version: _buildNumber.isNotEmpty
                  ? '$_appVersion ($_buildNumber)'
                  : _appVersion,
              color: scheme.onSurface,
            ),
            const SizedBox(height: 10),
            _buildVersionRow(
              context,
              icon: Icons.cloud_download_rounded,
              label: 'Latest',
              version: _latestVersion,
              color: _getVersionColor(scheme),
              trailing: _hasUpdate
                  ? Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: scheme.tertiary,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 18,
                  color: _hasUpdate ? scheme.tertiary : scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _updateStatus,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String version,
    required Color color,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          version,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 4), trailing],
      ],
    );
  }

  Widget _buildCheckUpdateButton() {
    return FilledButton.tonalIcon(
      onPressed: _checkForUpdates,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Check for Updates'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }
}
