import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/exercise_library_entry.dart';

const exerciseDbTestMediaEnabled = kDebugMode;

class ExerciseMediaFailure implements Exception {
  const ExerciseMediaFailure(this.message, {this.retryAfter});
  final String message;
  final Duration? retryAfter;
  @override
  String toString() => message;
}

final exerciseDbServiceProvider = Provider.autoDispose<ExerciseDbService>((
  ref,
) {
  final service = ExerciseDbService();
  ref.onDispose(service.close);
  return service;
});

class ExerciseDbService {
  ExerciseDbService({
    http.Client? client,
    this.enabled = exerciseDbTestMediaEnabled,
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final bool enabled;
  static const maxGifBytes = 8 * 1024 * 1024;
  static const timeout = Duration(seconds: 20);
  DateTime? _retryAt;
  final _pending = <Completer<void>, Object?>{};

  Completer<void> _beginRequest(Object? owner) {
    final abort = Completer<void>();
    _pending[abort] = owner;
    return abort;
  }

  void cancelPending({Object? owner}) {
    final requests = _pending.entries
        .where((entry) => owner == null || identical(entry.value, owner))
        .map((entry) => entry.key)
        .toList();
    for (final abort in requests) {
      if (!abort.isCompleted) abort.complete();
      _pending.remove(abort);
    }
  }

  /// Only the selected ExerciseDB source can resolve or download media.
  Future<Uri> resolveEntryMedia(ExerciseLibraryEntry entry, {Object? owner}) {
    if (entry.sourceProvider != 'exercisedb') {
      throw const ExerciseMediaFailure(
        'HealthMate chỉ sử dụng minh họa ExerciseDB.',
      );
    }
    return resolveGif(entry.sourceId, owner: owner);
  }

  Future<Uint8List> loadEntryMedia(
    Uri uri,
    ExerciseLibraryEntry entry, {
    Object? owner,
  }) {
    if (entry.sourceProvider != 'exercisedb') {
      throw const ExerciseMediaFailure(
        'HealthMate chỉ sử dụng minh họa ExerciseDB.',
      );
    }
    return loadGif(uri, entry.sourceId, owner: owner);
  }

  Future<Uri> resolveGif(String sourceId, {Object? owner}) async {
    if (!enabled) {
      throw const ExerciseMediaFailure(
        'GIF ExerciseDB miễn phí chỉ bật trong bản kiểm thử, chưa dùng cho bản phát hành thương mại.',
      );
    }
    if (!RegExp(r'^[a-zA-Z0-9]{7}$').hasMatch(sourceId)) {
      throw const ExerciseMediaFailure('Mã ExerciseDB không hợp lệ.');
    }
    final retryAt = _retryAt;
    if (retryAt != null && retryAt.isAfter(DateTime.now())) {
      throw ExerciseMediaFailure(
        'Nguồn GIF đang giới hạn lượt gọi. Vui lòng chờ rồi thử lại.',
        retryAfter: retryAt.difference(DateTime.now()),
      );
    }
    final abort = _beginRequest(owner);
    final deadline = Timer(timeout, () {
      if (!abort.isCompleted) abort.complete();
    });
    try {
      final request = http.AbortableRequest(
        'GET',
        Uri.https('oss.exercisedb.dev', '/api/v1/exercises/$sourceId'),
        abortTrigger: abort.future,
      )..followRedirects = false;
      final response = await _client.send(request).timeout(timeout);
      if (response.statusCode == 429) {
        final seconds = int.tryParse(response.headers['retry-after'] ?? '');
        DateTime? date;
        if (seconds == null) {
          try {
            date = DateFormat(
              "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
              'en_US',
            ).parseUtc(response.headers['retry-after'] ?? '');
          } catch (_) {
            /* Missing/malformed header uses bounded backoff. */
          }
        }
        final wait = seconds != null
            ? Duration(seconds: seconds.clamp(1, 86400))
            : date != null && date.isAfter(DateTime.now())
            ? date.difference(DateTime.now())
            : const Duration(minutes: 1);
        _retryAt = DateTime.now().add(wait);
        await response.stream.listen(null).cancel();
        throw ExerciseMediaFailure(
          'Nguồn GIF đang giới hạn lượt gọi. Vui lòng chờ rồi thử lại.',
          retryAfter: wait,
        );
      }
      if (response.statusCode != 200) {
        await response.stream.listen(null).cancel();
        throw const ExerciseMediaFailure(
          'Chưa tải được GIF của bài tập này. Bạn vẫn có thể xem hướng dẫn bên dưới.',
        );
      }
      final bytes = await _readBounded(response, 128 * 1024).timeout(timeout);
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        throw const FormatException();
      }
      final data = decoded['data'] as Map;
      if (data['exerciseId'] != sourceId || data['gifUrl'] is! String) {
        throw const FormatException();
      }
      final uri = Uri.tryParse(data['gifUrl'] as String);
      if (uri == null || !validGifUri(uri, sourceId)) {
        throw const FormatException();
      }
      return uri;
    } on ExerciseMediaFailure {
      rethrow;
    } on TimeoutException {
      throw const ExerciseMediaFailure(
        'Kết nối GIF quá lâu. Kiểm tra Internet rồi thử lại.',
      );
    } on FormatException {
      throw const ExerciseMediaFailure(
        'Nguồn trả về dữ liệu GIF không hợp lệ.',
      );
    } catch (_) {
      throw const ExerciseMediaFailure(
        'Không kết nối được nguồn GIF. Hướng dẫn chữ vẫn dùng được.',
      );
    } finally {
      deadline.cancel();
      _pending.remove(abort);
    }
  }

  static bool validGifUri(Uri uri, String sourceId) =>
      uri.scheme == 'https' &&
      uri.host == 'static.exercisedb.dev' &&
      uri.userInfo.isEmpty &&
      !uri.hasPort &&
      uri.fragment.isEmpty &&
      uri.path == '/media/$sourceId.gif';

  Future<Uint8List> loadGif(Uri uri, String sourceId, {Object? owner}) async {
    if (!enabled || !validGifUri(uri, sourceId)) {
      throw const ExerciseMediaFailure('Đường dẫn GIF không hợp lệ.');
    }
    return _loadMedia(uri, owner: owner);
  }

  Future<Uint8List> _loadMedia(Uri uri, {Object? owner}) async {
    final abort = _beginRequest(owner);
    final deadline = Timer(timeout, () {
      if (!abort.isCompleted) abort.complete();
    });
    try {
      final response = await _client
          .send(
            http.AbortableRequest('GET', uri, abortTrigger: abort.future)
              ..followRedirects = false,
          )
          .timeout(timeout);
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').toLowerCase().startsWith(
            'image/gif',
          )) {
        await response.stream.listen(null).cancel();
        throw const ExerciseMediaFailure(
          'Không tải được hình GIF. Thử mở lại sau.',
        );
      }
      final bytes = await _readBounded(response, maxGifBytes).timeout(timeout);
      final valid =
          bytes.length >= 10 &&
          [
            'GIF87a',
            'GIF89a',
          ].contains(ascii.decode(bytes.take(6).toList(), allowInvalid: true));
      if (!valid) {
        throw const ExerciseMediaFailure('Tệp minh họa động không hợp lệ.');
      }
      return bytes;
    } on ExerciseMediaFailure {
      rethrow;
    } catch (_) {
      throw const ExerciseMediaFailure(
        'Chưa tải được hình GIF. Kiểm tra Internet rồi thử lại.',
      );
    } finally {
      deadline.cancel();
      _pending.remove(abort);
    }
  }

  Future<Uint8List> _readBounded(
    http.StreamedResponse response,
    int max,
  ) async {
    if ((response.contentLength ?? 0) > max) {
      await response.stream.listen(null).cancel();
      throw const ExerciseMediaFailure(
        'Tệp minh họa vượt giới hạn dung lượng.',
      );
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (builder.length + chunk.length > max) {
        throw const ExerciseMediaFailure(
          'Tệp minh họa vượt giới hạn dung lượng.',
        );
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  void close() {
    cancelPending();
    _client.close();
  }
}
