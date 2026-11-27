import 'package:example/demo.dart';
import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'example',
      packageName: 'com.example.example',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('minimal example shows the check button', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Check for updates'), findsOneWidget);
  });

  testWidgets('demo app builds', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pump();

    expect(find.text('Self-Hosted Updater Demo'), findsOneWidget);
  });
}
