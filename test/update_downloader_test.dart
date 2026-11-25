import 'dart:async';
import 'dart:io';

import 'package:self_hosted_updater/src/download/update_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('updater_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  File target() => File('${dir.path}/app.apk');
  bool hasPartialFile() => File('${target().path}.part').existsSync();

  /// Serves [chunks] as a streamed response with an optional Content-Length.
  MockClient streamingClient(
    Stream<List<int>> chunks, {
    int status = 200,
    int? contentLength,
  }) {
    return MockClient.streaming(
      (request, _) async =>
          http.StreamedResponse(chunks, status, contentLength: contentLength),
    );
  }

  test('writes the file and reports progress', () async {
    final chunks = [List.filled(400, 1), List.filled(600, 2)];
    final downloader = UpdateDownloader(
      url: Uri.parse('https://example.com/app.apk'),
      destination: target(),
    );
    final seen = <DownloadProgress>[];
    downloader.progress.addListener(() => seen.add(downloader.progress.value));

    final file = await http.runWithClient(
      downloader.start,
      () => streamingClient(Stream.fromIterable(chunks), contentLength: 1000),
    );

    expect(await file.length(), 1000);
    expect(file.path, target().path);
    expect(hasPartialFile(), isFalse);
    expect(seen.last, const DownloadProgress(1000, 1000));
    expect(seen.map((p) => p.received), containsAllInOrder([400, 1000]));
    expect(seen.last.fraction, 1.0);
  });

  test(
    'falls back to the expected size when there is no Content-Length',
    () async {
      final downloader = UpdateDownloader(
        url: Uri.parse('https://example.com/app.apk'),
        destination: target(),
        expectedSize: 10,
      );

      await http.runWithClient(
        downloader.start,
        () => streamingClient(Stream.value(List.filled(10, 0))),
      );

      expect(downloader.progress.value, const DownloadProgress(10, 10));
    },
  );

  test('throws on a non-200 response and leaves no file behind', () async {
    final downloader = UpdateDownloader(
      url: Uri.parse('https://example.com/app.apk'),
      destination: target(),
    );

    await expectLater(
      http.runWithClient(
        downloader.start,
        () => streamingClient(const Stream.empty(), status: 404),
      ),
      throwsA(predicate((e) => '$e'.contains('404'))),
    );
    expect(target().existsSync(), isFalse);
    expect(hasPartialFile(), isFalse);
  });

  test('cancel stops the download and removes the partial file', () async {
    final controller = StreamController<List<int>>();
    final downloader = UpdateDownloader(
      url: Uri.parse('https://example.com/app.apk'),
      destination: target(),
    );

    final result = http.runWithClient(
      downloader.start,
      () => streamingClient(controller.stream, contentLength: 1000),
    );

    controller.add(List.filled(100, 1));
    await pumpEventQueue();
    expect(downloader.progress.value.received, 100);

    downloader.cancel();
    await expectLater(result, throwsA(isA<DownloadCancelledException>()));
    expect(target().existsSync(), isFalse);
    expect(hasPartialFile(), isFalse);
    await controller.close();
  });

  test('rejects a truncated download', () async {
    final downloader = UpdateDownloader(
      url: Uri.parse('https://example.com/app.apk'),
      destination: target(),
    );

    await expectLater(
      http.runWithClient(
        downloader.start,
        () => streamingClient(
          Stream.value(List.filled(300, 1)),
          contentLength: 1000,
        ),
      ),
      throwsA(predicate((e) => '$e'.contains('incomplete'))),
    );
    expect(target().existsSync(), isFalse);
    expect(hasPartialFile(), isFalse);
  });

  test('times out', () async {
    final controller = StreamController<List<int>>();
    final downloader = UpdateDownloader(
      url: Uri.parse('https://example.com/app.apk'),
      destination: target(),
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      http.runWithClient(
        downloader.start,
        () => streamingClient(controller.stream, contentLength: 1000),
      ),
      throwsA(predicate((e) => '$e'.contains('timeout'))),
    );
    expect(hasPartialFile(), isFalse);
    await controller.close();
  });

  test('DownloadProgress.fraction', () {
    expect(const DownloadProgress(50, 200).fraction, 0.25);
    expect(const DownloadProgress(50, null).fraction, isNull);
    expect(const DownloadProgress(50, 0).fraction, isNull);
    expect(const DownloadProgress(300, 200).fraction, 1.0);
  });
}
