import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/play_billing_repository.dart';
import '../data/play_store.dart';
import '../models/play_billing_models.dart';

class PlayBillingController extends ChangeNotifier {
  PlayBillingController(
    this.repository,
    this.store, {
    required this.isCurrent,
    this.operationTimeout = const Duration(seconds: 30),
    this.verificationTimeout = const Duration(seconds: 130),
  });
  final PlayBillingRepository repository;
  final PlayStore store;
  final bool Function() isCurrent;
  final Duration operationTimeout, verificationTimeout;
  PlayBillingConfig? config;
  PlayProduct? product;
  bool loading = true;
  String? message;
  bool _disposed = false,
      _restoring = false,
      _verifying = false,
      _checkoutOpen = false;
  final _pending = <String>{};
  final _queued = <String>{};
  int _events = 0;
  Future<void>? _startup, _reload;
  StreamSubscription<List<StorePurchase>>? _subscription;
  Future<void> _queue = Future.value();
  bool get _current => !_disposed && isCurrent();
  bool get busy =>
      _restoring ||
      _verifying ||
      _checkoutOpen ||
      _pending.isNotEmpty ||
      _queued.isNotEmpty;
  bool get restoring => _restoring;
  bool get canReload => !loading && !busy;
  bool get canRestore =>
      !loading &&
      config?.enabled == true &&
      !_restoring &&
      !_verifying &&
      _queued.isEmpty;
  void _publish() {
    if (_current) notifyListeners();
  }

  Future<void> start() => _startup ??= _start();
  Future<void> _start() async {
    try {
      _subscription = store.purchases.listen(
        (events) {
          _events += events.length;
          for (final event in events) {
            final verify =
                event.status == StorePurchaseStatus.purchased ||
                event.status == StorePurchaseStatus.restored;
            // Duplicate callbacks already queued/in flight share one verification.
            // Clear afterwards so a later renewal with the same token can refresh.
            if (verify && !_queued.add(event.token)) continue;
            _queue = _queue.then((_) async {
              try {
                if (_current) await _handle(event);
              } finally {
                if (verify) _queued.remove(event.token);
                _publish();
              }
            });
          }
        },
        onError: (Object error) {
          if (_current) {
            _checkoutOpen = false;
            message = 'Mất kết nối Google Play. Hãy khôi phục giao dịch.';
            _publish();
          }
        },
      );
      await reload();
      if (_current && config?.enabled == true) await restore();
    } catch (_) {
      if (_current) {
        loading = false;
        message = 'Chưa kết nối được Google Play.';
        _publish();
      }
    }
  }

  Future<void> reload() {
    if (_reload case final existing?) return existing;
    if (!_current || busy) return Future.value();
    return _reload = _load().whenComplete(() => _reload = null);
  }

  Future<void> _load() async {
    loading = true;
    product = null;
    config = null;
    message = null;
    _publish();
    try {
      final result = await repository.prepare().timeout(operationTimeout);
      if (!_current) return;
      config = result;
      if (result.enabled) {
        final loaded = await store.load(result).timeout(operationTimeout);
        if (!_current) return;
        product = loaded;
        if (loaded == null) {
          message =
              'Chưa tìm thấy gói trên Google Play. Kiểm tra tài khoản Play và bản cài ứng dụng.';
        }
      }
    } catch (_) {
      if (_current) {
        message =
            'Chưa kết nối được dịch vụ thanh toán. Hãy tải lại khi có mạng.';
      }
    } finally {
      if (_current) {
        loading = false;
        _publish();
      }
    }
  }

  Future<void> buy() async {
    if (!_current ||
        busy ||
        loading ||
        config?.enabled != true ||
        product == null) {
      return;
    }
    _checkoutOpen = true;
    message = 'Đang mở Google Play…';
    _publish();
    try {
      final opened = await store.buy(config!).timeout(operationTimeout);
      if (_current && !opened) {
        _checkoutOpen = false;
        message = 'Google Play chưa mở được thanh toán. Hãy thử lại.';
        _publish();
      }
    } catch (_) {
      if (_current) {
        _checkoutOpen = false;
        message =
            'Chưa mở được thanh toán. Nếu đã trả tiền, hãy khôi phục giao dịch.';
        _publish();
      }
    }
  }

  Future<void> restore() async {
    if (!_current ||
        loading ||
        config?.enabled != true ||
        _restoring ||
        _verifying ||
        _queued.isNotEmpty) {
      return;
    }
    _restoring = true;
    final before = _events;
    message = 'Đang tìm giao dịch trong tài khoản Google Play…';
    _publish();
    try {
      await store.restore().timeout(operationTimeout);
      await _queue;
      if (_current && before == _events) {
        // Manual restore also recovers a checkout whose close callback was lost.
        // A known pending purchase remains pending until Play reports otherwise.
        _checkoutOpen = false;
        message = _pending.isNotEmpty
            ? 'Google Play vẫn đang chờ hoàn tất thanh toán. Chưa cấp Premium.'
            : 'Đã yêu cầu khôi phục. Giao dịch tìm được sẽ được máy chủ xác minh.';
      }
    } catch (_) {
      if (_current) {
        message =
            'Chưa khôi phục được giao dịch. Hãy kiểm tra mạng và thử lại.';
      }
    } finally {
      _restoring = false;
      _publish();
    }
  }

  Future<void> _handle(StorePurchase event) async {
    final key = event.token.isEmpty ? 'pending-store-event' : event.token;
    if (event.status == StorePurchaseStatus.pending) {
      _checkoutOpen = false;
      _pending.add(key);
      message = 'Google Play đang chờ hoàn tất thanh toán. Chưa cấp Premium.';
      _publish();
      return;
    }
    _pending.remove(key);
    // Pending callbacks may omit the token that a terminal callback supplies.
    _pending.remove('pending-store-event');
    _checkoutOpen = false;
    if (event.status == StorePurchaseStatus.cancelled ||
        event.status == StorePurchaseStatus.error) {
      message = event.status == StorePurchaseStatus.cancelled
          ? 'Đã đóng thanh toán.'
          : 'Google Play chưa hoàn tất giao dịch. Nếu đã trả tiền, hãy khôi phục.';
      _publish();
      return;
    }
    _verifying = true;
    message = 'Đang xác minh giao dịch với máy chủ…';
    _publish();
    try {
      final result = await repository
          .verify(event.token)
          .timeout(verificationTimeout);
      if (!_current) return;
      if (!result.verified) throw StateError('Unverified');
      if (result.pending) {
        _pending.add(key);
        message = 'Thanh toán đang chờ Google xác nhận.';
        return;
      }
      if (!result.completionAllowed) {
        message =
            'Giao dịch chưa đủ điều kiện hoàn tất. Hãy khôi phục để đối soát với Google; không cần mua lại.';
        return;
      }
      if (event.needsCompletion) {
        await store.complete(event).timeout(operationTimeout);
      }
      if (_current) {
        message = 'Đã đối soát giao dịch. Quyền Premium lấy từ máy chủ.';
      }
    } catch (_) {
      if (_current) {
        message =
            'Chưa xác minh được giao dịch. Dùng đúng tài khoản HealthMate đã mua và bấm Khôi phục giao dịch; không cần mua lại.';
      }
    } finally {
      _verifying = false;
      _publish();
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      await _subscription?.cancel();
    } catch (_) {
      /* Disposed stream cleanup only. */
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cancelSubscription());
    super.dispose();
  }
}
