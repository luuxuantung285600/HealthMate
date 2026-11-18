import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/workout_tutorial.dart';

enum TutorialPlaybackState { loading, ready, failed }

/// A small boundary around the platform player so lifecycle/error behavior can
/// be tested without a WebView or a connection to YouTube.
abstract class WorkoutTutorialPlayer extends ChangeNotifier {
  TutorialPlaybackState get state;
  Widget buildView(double aspectRatio);
  Future<void> pause();
}

typedef WorkoutTutorialPlayerFactory =
    WorkoutTutorialPlayer Function(WorkoutTutorial tutorial);

final workoutTutorialPlayerFactoryProvider =
    Provider<WorkoutTutorialPlayerFactory>((ref) => _YoutubeTutorialPlayer.new);

bool get supportsWorkoutVideo =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class _YoutubeTutorialPlayer extends WorkoutTutorialPlayer {
  _YoutubeTutorialPlayer(WorkoutTutorial tutorial) {
    _controller = YoutubePlayerController(
      key: tutorial.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        privacyEnhancedMode: true,
        interfaceLanguage: 'vi',
        strictRelatedVideos: true,
        // Native WebViews must identify the real application to YouTube.
        // The package uses this base URL as the native HTTP Referer.
        origin: kIsWeb ? null : 'https://com.example.healthmate',
      ),
    );
    _subscription = _controller.stream.listen((value) {
      if (_disposed || _state == TutorialPlaybackState.failed) return;
      if (value.hasError) {
        _fail();
      } else if (value.playerState != PlayerState.unknown) {
        _timeout.cancel();
        if (_state != TutorialPlaybackState.ready) {
          _state = TutorialPlaybackState.ready;
          notifyListeners();
        }
      }
    }, onError: (_, _) => _fail());
    _timeout = Timer(const Duration(seconds: 20), _fail);
    // Handle initialization failures too: fromVideoId discards this Future,
    // which otherwise leaves an uncaught readiness timeout when offline.
    unawaited(
      _controller
          .cueVideoById(
            videoId: tutorial.videoId,
            endSeconds: tutorial.endSeconds,
          )
          .catchError((Object error, StackTrace stack) => _fail()),
    );
  }

  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _subscription;
  late final Timer _timeout;
  TutorialPlaybackState _state = TutorialPlaybackState.loading;
  bool _disposed = false;
  Future<void>? _closing;

  @override
  TutorialPlaybackState get state => _state;

  void _fail() {
    if (_disposed || _state == TutorialPlaybackState.failed) return;
    _timeout.cancel();
    _state = TutorialPlaybackState.failed;
    unawaited(_close());
    notifyListeners();
  }

  @override
  Widget buildView(double aspectRatio) => YoutubePlayer(
    controller: _controller,
    aspectRatio: aspectRatio,
    autoFullScreen: false,
    enableFullScreenOnVerticalDrag: false,
    keepAlive: false,
  );

  @override
  Future<void> pause() async {
    if (_disposed || _state != TutorialPlaybackState.ready) return;
    try {
      await _controller.pauseVideo();
    } catch (_) {
      // Losing the network while leaving the screen must not crash the app.
    }
  }

  Future<void> _close() => _closing ??= _closeController();

  Future<void> _closeController() async {
    try {
      await _controller.close();
    } catch (_) {
      // A WebView may already have been destroyed by its host.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timeout.cancel();
    unawaited(_subscription.cancel());
    unawaited(_close());
    super.dispose();
  }
}
