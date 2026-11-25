import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Progress of an update download.
@immutable
class DownloadProgress {
  /// Bytes received so far.
  final int received;

  /// Total bytes, when the server (or the update info) reports it.
  final int? total;

  const DownloadProgress(this.received, this.total);

  /// Completed fraction between 0 and 1, or `null` when the size is unknown.
  double? get fraction {
    final total = this.total;
    if (total == null || total <= 0) return null;
    return (received / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is DownloadProgress &&
      other.received == received &&
      other.total == total;

  @override
  int get hashCode => Object.hash(received, total);
}

/// Thrown by [UpdateDownloader.start] after [UpdateDownloader.cancel].
class DownloadCancelledException implements Exception {
  const DownloadCancelledException();

  @override
  String toString() => 'Download cancelled';
}

/// Streams a file to disk, reporting [progress] as it goes.
///
/// Data is written to `<destination>.part` and only renamed to [destination]
/// once the download is complete, so a partial file is never installed.
class UpdateDownloader {
  final Uri url;
  final File destination;

  /// Size from the update info, used when the server sends no Content-Length.
  final int? expectedSize;

  /// Maximum time for the whole download.
  final Duration timeout;

  final ValueNotifier<DownloadProgress> progress;

  http.Client? _client;
  void Function(Object error)? _abort;
  bool _cancelled = false;

  UpdateDownloader({
    required this.url,
    required this.destination,
    this.expectedSize,
    this.timeout = const Duration(minutes: 5),
  }) : progress = ValueNotifier(DownloadProgress(0, expectedSize));

  /// Downloads the file and returns [destination].
  ///
  /// Throws [DownloadCancelledException] if [cancel] was called.
  Future<File> start() async {
    if (_cancelled) throw const DownloadCancelledException();

    final client = _client = http.Client();
    final partFile = File('${destination.path}.part');
    final done = Completer<void>();
    StreamSubscription<List<int>>? subscription;
    IOSink? sink;

    void fail(Object error) {
      subscription?.cancel();
      if (!done.isCompleted) done.completeError(error);
      client.close();
    }

    _abort = fail;
    final timer = Timer(timeout, () => fail(Exception('Download timeout')));

    try {
      final response = await Future.any([
        client.send(http.Request('GET', url)),
        // Surfaces cancel/timeout while still waiting for the response headers.
        done.future.then((_) => throw StateError('unreachable')),
      ]);

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final total = response.contentLength ?? expectedSize;
      var received = 0;
      progress.value = DownloadProgress(0, total);

      await partFile.parent.create(recursive: true);
      final out = sink = partFile.openWrite();
      subscription = response.stream.listen(
        (chunk) {
          out.add(chunk);
          received += chunk.length;
          progress.value = DownloadProgress(received, total);
        },
        onError: (Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
      await done.future;

      await out.flush();
      await out.close();
      sink = null;

      if (total != null && received != total) {
        throw Exception('Download incomplete ($received of $total bytes)');
      }
      if (await destination.exists()) await destination.delete();
      return await partFile.rename(destination.path);
    } catch (error) {
      try {
        await sink?.close();
      } catch (_) {}
      if (await partFile.exists()) await partFile.delete();
      if (_cancelled) throw const DownloadCancelledException();
      rethrow;
    } finally {
      timer.cancel();
      _abort = null;
      _client = null;
      client.close();
    }
  }

  /// Stops the download; [start] then throws [DownloadCancelledException].
  void cancel() {
    _cancelled = true;
    _abort?.call(const DownloadCancelledException());
    _client?.close();
  }
}
