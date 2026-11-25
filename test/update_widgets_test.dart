import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_updater/flutter_custom_updater.dart';
import 'package:flutter_custom_updater/src/widgets/material_update_dialog.dart';
import 'package:flutter_custom_updater/src/widgets/material_download_dialog.dart';
import 'package:flutter_custom_updater/src/download/update_downloader.dart';
import 'package:flutter_custom_updater/src/widgets/cupertino_download_dialog.dart';
import 'package:flutter_custom_updater/src/widgets/cupertino_update_dialog.dart';
import 'package:flutter_custom_updater/src/widgets/download_sheet.dart';
import 'package:flutter_custom_updater/src/widgets/update_sheet.dart';
import 'package:flutter_custom_updater/src/widgets/update_message_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

UpdaterConfig config({DialogStyle style = DialogStyle.material}) =>
    UpdaterConfig(updateCheckUrl: 'https://example.com', dialogStyle: style);

UpdateInfo info({bool force = false, String? notes}) => UpdateInfo(
  hasUpdate: true,
  version: '2.0.0',
  downloadUrl: 'https://example.com/app.apk',
  forceUpdate: force,
  releaseNotes: notes,
);

Future<void> pumpBody(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('required update label', () {
    testWidgets('material shows it only for forced updates', (tester) async {
      await pumpBody(
        tester,
        MaterialUpdateDialog(updateInfo: info(force: true), config: config()),
      );
      expect(find.text('Required update'), findsOneWidget);
      expect(find.text('Later'), findsNothing);

      await pumpBody(
        tester,
        MaterialUpdateDialog(updateInfo: info(), config: config()),
      );
      expect(find.text('Required update'), findsNothing);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('cupertino and sheet show it for forced updates', (
      tester,
    ) async {
      await pumpBody(
        tester,
        CupertinoUpdateDialog(updateInfo: info(force: true), config: config()),
      );
      expect(find.text('Required update'), findsOneWidget);

      await pumpBody(
        tester,
        UpdateSheet(
          updateInfo: info(force: true),
          config: config(),
          onUpdate: () {},
        ),
      );
      expect(find.text('Required update'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('labels can be customised', (tester) async {
      await pumpBody(
        tester,
        MaterialUpdateDialog(
          updateInfo: info(force: true),
          config: UpdaterConfig(
            updateCheckUrl: 'https://example.com',
            versionText: 'កំណែ {version}',
            requiredUpdateText: 'ត្រូវការ',
          ),
        ),
      );
      expect(find.text('កំណែ 2.0.0'), findsOneWidget);
      expect(find.text('ត្រូវការ'), findsOneWidget);
    });
  });

  testWidgets('shows the download size on Android, but not a zero size', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      Widget dialog(int size) => MaterialUpdateDialog(
        updateInfo: UpdateInfo(
          hasUpdate: true,
          version: '2.0.0',
          downloadUrl: 'https://example.com/app.apk',
          fileSize: size,
        ),
        config: config(),
      );

      await pumpBody(tester, dialog(25 * 1024 * 1024));
      expect(find.text('25.0 MB'), findsOneWidget);

      await pumpBody(tester, dialog(0));
      expect(find.text('0 B'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  group('release notes', () {
    testWidgets('renders bullets and headings', (tester) async {
      await pumpBody(
        tester,
        MaterialUpdateDialog(
          updateInfo: info(notes: 'New:\n- Faster sync\n* Dark mode\n• Fixes'),
          config: config(),
        ),
      );
      expect(find.text('New:'), findsOneWidget);
      expect(find.text('Faster sync'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Fixes'), findsOneWidget);
      expect(find.text('•'), findsNWidgets(3));
    });
  });

  group('download progress', () {
    for (final style in DialogStyle.values) {
      testWidgets('$style shows size, percent and cancel', (tester) async {
        final progress = ValueNotifier(
          const DownloadProgress(5 * 1024 * 1024, 20 * 1024 * 1024),
        );
        var cancelled = false;
        void cancel() => cancelled = true;
        final c = config(style: style);

        await pumpBody(tester, switch (style) {
          DialogStyle.material => MaterialDownloadDialog(
            config: c,
            progress: progress,
            onCancel: cancel,
          ),
          DialogStyle.cupertino => CupertinoDownloadDialog(
            config: c,
            progress: progress,
            onCancel: cancel,
          ),
          DialogStyle.bottomSheet => DownloadSheet(
            config: c,
            progress: progress,
            onCancel: cancel,
          ),
        });

        expect(find.text('5.0 MB of 20.0 MB'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);
        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.value, 0.25);

        progress.value = const DownloadProgress(
          15 * 1024 * 1024,
          20 * 1024 * 1024,
        );
        await tester.pump();
        expect(find.text('75%'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        expect(cancelled, isTrue);
      });
    }

    testWidgets('forced downloads have no cancel button', (tester) async {
      await pumpBody(
        tester,
        MaterialDownloadDialog(
          config: config(),
          progress: ValueNotifier(const DownloadProgress(1, 2)),
        ),
      );
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('unknown size shows an indeterminate bar', (tester) async {
      await pumpBody(
        tester,
        MaterialDownloadDialog(
          config: config(),
          progress: ValueNotifier(const DownloadProgress(2048, null)),
        ),
      );
      expect(find.text('2.0 KB'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);
    });
  });

  group('message prompt', () {
    for (final style in DialogStyle.values) {
      testWidgets('$style returns the chosen action', (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => UpdateMessagePrompt(
                      config: config(style: style),
                      icon: Icons.error_outline,
                      title: 'Update failed',
                      message: 'Server returned status code 404',
                      primaryLabel: 'Retry',
                      secondaryLabel: 'Close',
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Update failed'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(result, isTrue);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(result, isFalse);
      });
    }

    testWidgets('without a secondary action it cannot be dismissed', (
      tester,
    ) async {
      await pumpBody(
        tester,
        UpdateMessagePrompt(
          config: config(),
          icon: Icons.system_update,
          title: 'Finish updating',
          message: 'Install the new version to keep using the app.',
          primaryLabel: 'Install',
        ),
      );
      expect(find.text('Install'), findsOneWidget);
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });
  });
}
