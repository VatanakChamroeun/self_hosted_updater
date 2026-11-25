import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_custom_updater/flutter_custom_updater.dart';
import 'package:flutter_custom_updater/src/widgets/material_update_dialog.dart';
import 'package:flutter_custom_updater/src/utils/update_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('sanitizeApkFileName', () {
    test('keeps a plain file name', () {
      expect(sanitizeApkFileName('app-v1.2.3.apk'), 'app-v1.2.3.apk');
    });

    test('falls back when no name is given', () {
      expect(sanitizeApkFileName(null), 'app_update.apk');
      expect(sanitizeApkFileName('   '), 'app_update.apk');
    });

    test('strips directory components from server-provided names', () {
      expect(sanitizeApkFileName('../../evil.apk'), 'evil.apk');
      expect(sanitizeApkFileName('/data/x/evil.apk'), 'evil.apk');
      expect(sanitizeApkFileName(r'..\..\evil.apk'), 'evil.apk');
    });

    test('rejects names that are only dots', () {
      expect(sanitizeApkFileName('..'), 'app_update.apk');
      expect(sanitizeApkFileName('.'), 'app_update.apk');
    });
  });

  group('buildItmsServicesUri', () {
    test('builds an itms-services download-manifest URL', () {
      final uri = buildItmsServicesUri(
        'https://example.com/ios/manifest.plist',
      );

      expect(uri.scheme, 'itms-services');
      expect(uri.queryParameters['action'], 'download-manifest');
      expect(
        uri.queryParameters['url'],
        'https://example.com/ios/manifest.plist',
      );
    });

    test('keeps the manifest URL query string intact', () {
      const manifestUrl =
          'https://cdn.example.com/manifest.plist?token=abc&expires=123';

      final uri = buildItmsServicesUri(manifestUrl);

      expect(uri.queryParameters['url'], manifestUrl);
      expect(uri.queryParameters.containsKey('expires'), isFalse);
    });
  });

  group('AppUpdater.checkAndUpdate', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'test',
        packageName: 'com.example.test',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext hostContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: Text('home'));
            },
          ),
        ),
      );
      return hostContext;
    }

    http.Response jsonResponse(Map<String, dynamic> data) =>
        http.Response(jsonEncode({'data': data}), 200);

    testWidgets('reports a failed update check exactly once', (tester) async {
      final context = await pumpHost(tester);
      final errors = <String>[];

      await http.runWithClient(
        () => AppUpdater(
          context: context,
          config: UpdaterConfig(
            updateCheckUrl: 'https://example.com/check',
            onError: errors.add,
          ),
        ).checkAndUpdate(),
        () => MockClient((_) async => http.Response('oops', 500)),
      );

      expect(errors, hasLength(1));
      expect(errors.single, contains('Failed to check for updates'));
      expect(errors.single, contains('500'));
    });

    testWidgets('calls onNoUpdateAvailable when there is no update', (
      tester,
    ) async {
      final context = await pumpHost(tester);
      var noUpdateCalls = 0;

      await http.runWithClient(
        () => AppUpdater(
          context: context,
          config: UpdaterConfig(
            updateCheckUrl: 'https://example.com/check',
            onNoUpdateAvailable: () => noUpdateCalls++,
          ),
        ).checkAndUpdate(),
        () => MockClient(
          (_) async => jsonResponse({'has_update': false, 'download_url': ''}),
        ),
      );

      expect(noUpdateCalls, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('does nothing if the caller is disposed during the check', (
      tester,
    ) async {
      final context = await pumpHost(tester);
      final errors = <String>[];
      final responseGate = Completer<http.Response>();

      late Future<void> result;
      http.runWithClient(() {
        result = AppUpdater(
          context: context,
          config: UpdaterConfig(
            updateCheckUrl: 'https://example.com/check',
            onError: errors.add,
          ),
        ).checkAndUpdate();
      }, () => MockClient((_) => responseGate.future));

      // Dispose the widget that owns the context while the request is pending.
      await tester.pumpWidget(const SizedBox());

      responseGate.complete(
        jsonResponse({
          'has_update': true,
          'version': '2.0.0',
          'download_url': 'https://example.com/app.apk',
        }),
      );
      await result;
      await tester.pump();

      expect(errors, isEmpty);
      expect(find.byType(MaterialUpdateDialog), findsNothing);
    });

    testWidgets('choosing Later closes only the update dialog', (tester) async {
      final context = await pumpHost(tester);

      late Future<void> result;
      http.runWithClient(
        () {
          result = AppUpdater(
            context: context,
            config: UpdaterConfig(updateCheckUrl: 'https://example.com/check'),
          ).checkAndUpdate();
        },
        () => MockClient(
          (_) async => jsonResponse({
            'has_update': true,
            'version': '2.0.0',
            'download_url': 'https://example.com/app.apk',
          }),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(MaterialUpdateDialog), findsOneWidget);
      expect(find.text('Version 2.0.0'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      await result;

      expect(find.byType(MaterialUpdateDialog), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });
}
