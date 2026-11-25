import 'package:flutter/material.dart';

import 'home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self-Hosted Updater Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: HomeScreen(),
    );
  }
}
