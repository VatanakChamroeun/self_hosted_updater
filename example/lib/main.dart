import 'dart:io';

import 'package:flutter/material.dart';
import 'package:self_hosted_updater/self_hosted_updater.dart';

// Minimal integration of self_hosted_updater: check for an update when the
// app starts, and again from a button.
//
// To try it, start the mock server from the repo root:
//   cd mock_server && npm install && node server.js
//
// For the full demo (every dialog style, update callbacks, version status):
//   flutter run -t lib/demo.dart

void main() => runApp(const MyApp());

/// Your update endpoint. The Android emulator reaches the host machine on
/// 10.0.2.2; the iOS simulator can use localhost.
final String updateCheckUrl = Platform.isAndroid
    ? 'http://10.0.2.2:3000/api/check-update'
    : 'http://localhost:3000/api/check-update';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self-Hosted Updater Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Wait for the first frame so the update prompt has a Navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
  }

  /// Checks the server and, if there is an update, walks the user through
  /// downloading and installing it. [manual] checks also report "no update"
  /// and errors, which a silent check on startup should not.
  Future<void> _checkForUpdates({bool manual = false}) {
    return AppUpdater(
      context: context,
      config: UpdaterConfig(
        updateCheckUrl: updateCheckUrl,
        // customHeaders: {'Authorization': 'Bearer <token>'},
        dialogStyle: DialogStyle.bottomSheet, // or material, cupertino
        onNoUpdateAvailable: manual
            ? () => _showMessage('You are on the latest version.')
            : null,
        onError: manual
            ? (message) => _showMessage('Update check failed: $message')
            : null,
      ),
    ).checkAndUpdate();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Self-Hosted Updater Example')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => _checkForUpdates(manual: true),
          icon: const Icon(Icons.system_update_rounded),
          label: const Text('Check for updates'),
        ),
      ),
    );
  }
}
