import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Full demo: shows the installed and latest version, every dialog style and
/// the update callbacks. Run it with `flutter run -t lib/demo.dart`.
///
/// For the minimal integration, see `main.dart`.
void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self-Hosted Updater Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
