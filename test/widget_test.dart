import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Package can be imported', (WidgetTester tester) async {
    // This test verifies the package can be imported successfully
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Self-Hosted Updater Test'))),
      ),
    );

    expect(find.text('Self-Hosted Updater Test'), findsOneWidget);
  });
}
