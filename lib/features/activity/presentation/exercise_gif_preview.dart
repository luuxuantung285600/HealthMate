import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../data/exercise_db_service.dart';
import '../models/exercise_library_entry.dart';
import 'exercise_gif_background.dart';
import 'exercise_gif_web_background_stub.dart'
    if (dart.library.js_interop) 'exercise_gif_web_background.dart';
import 'workout_ui.dart';

/// Visible list cards and explicit detail views request transient media.
/// Backgrounding/unmounting removes
/// the player; native frames/codecs are disposed and nothing is written to disk.
class ExerciseGifPreview extends ConsumerStatefulWidget {
  const ExerciseGifPreview({
    super.key,
    required this.entry,
    this.autoLoad = false,
    this.compact = false,
    this.thumbnail = false,
    this.stage = false,
    this.height,
  });
  final ExerciseLibraryEntry entry;
  final bool autoLoad;
  final bool compact;
  final bool thumbnail;
  final bool stage;
  final double? height;
  @override
  ConsumerState<ExerciseGifPreview> createState() => _ExerciseGifPreviewState();
}

class _ExerciseGifPreviewState extends ConsumerState<ExerciseGifPreview>
    with WidgetsBindingObserver {
  int _generation = 0;
  bool _loading = false, _playing = false;
  Uri? _uri;
  Uint8List? _bytes;
  String? _error;
  ExerciseDbService? _service;
  final _requestOwner = Object();
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            TickerMode.valuesOf(context).enabled &&
            ref.read(exerciseDbServiceProvider).enabled) {
          _load();
        }
      });
    }
  }

  @override
  void didUpdateWidget(ExerciseGifPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.sourceId != widget.entry.sourceId ||
        oldWidget.entry.sourceProvider != widget.entry.sourceProvider ||
        oldWidget.entry.id != widget.entry.id) {
      _reset();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Indexed navigation branches stay mounted while hidden. A GIF must not
    // continue decoding behind another tab or while motion is disabled.
    final visible = TickerMode.valuesOf(context).enabled;
    if (!visible) _reset();
    if (visible && !_visible && widget.compact && widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            TickerMode.valuesOf(context).enabled &&
            ref.read(exerciseDbServiceProvider).enabled) {
          _load();
        }
      });
    }
    _visible = visible;
    if (MediaQuery.disableAnimationsOf(context)) _playing = false;
  }

  void _reset() {
    _service?.cancelPending(owner: _requestOwner);
    _generation++;
    _loading = false;
    _playing = false;
    _uri = null;
    _bytes = null;
    _error = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) setState(_reset);
  }

  @override
  void dispose() {
    _reset();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    final generation = ++_generation,
        service = ref.read(exerciseDbServiceProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = await service.resolveEntryMedia(
        widget.entry,
        owner: _requestOwner,
      );
      if (!mounted || generation != _generation) return;
      final bytes = kIsWeb
          ? null
          : await service.loadEntryMedia(
              uri,
              widget.entry,
              owner: _requestOwner,
            );
      if (!mounted || generation != _generation) return;
      setState(() {
        _uri = uri;
        _bytes = bytes;
        _loading = false;
        _playing = !MediaQuery.disableAnimationsOf(context);
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = error is ExerciseMediaFailure
            ? error.message
            : 'Không tải được GIF. Hãy thử lại sau.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(exerciseDbServiceProvider);
    _service = service;
    final theme = Theme.of(context);
    configureExerciseGifWebBackground(theme.brightness == Brightness.dark);
    if (widget.stage) return _stagePreview(service, theme);
    if (widget.compact && widget.thumbnail) return _thumbnail(service, theme);
    if (widget.compact) return _compactPreview(service, theme);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Minh họa động tác',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  widget.entry.mediaFormat,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: workoutAccent(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_uri != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: theme.brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  child: SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: _media(),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('pause-exercise-gif'),
                    onPressed: () => setState(() => _playing = !_playing),
                    icon: Icon(_playing ? AppIcons.pause : AppIcons.play),
                    label: Text(_playing ? 'Tạm dừng' : 'Phát GIF'),
                  ),
                  TextButton(
                    onPressed: () => setState(_reset),
                    child: const Text('Đóng GIF'),
                  ),
                ],
              ),
            ] else if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang tải GIF…'),
                  ],
                ),
              )
            else ...[
              if (_error != null)
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              if (!service.enabled)
                const Text(
                  'Minh họa miễn phí chỉ bật ở bản kiểm thử. Hướng dẫn chữ vẫn dùng được.',
                ),
              if (service.enabled)
                FilledButton.icon(
                  key: const ValueKey('load-exercise-gif'),
                  onPressed: _load,
                  icon: const Icon(AppIcons.play),
                  label: Text(_error == null ? 'Xem GIF' : 'Thử tải lại GIF'),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              widget.entry.mediaCredit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stagePreview(ExerciseDbService service, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_uri != null || _loading)
        SizedBox(
          key: const ValueKey('exercise-gif-frame'),
          height: widget.height ?? 260,
          child: ColoredBox(
            color: theme.brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            child: _uri != null
                ? _media()
                : const Center(child: CircularProgressIndicator()),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error == null ? AppIcons.workout : AppIcons.cloudAlert,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                !service.enabled
                    ? 'Minh họa miễn phí chỉ bật ở bản kiểm thử. Hướng dẫn chữ vẫn dùng được.'
                    : _error ?? 'Xem minh họa để nắm kỹ thuật.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              'ExerciseDB / GIF minh họa',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_uri != null)
              TextButton.icon(
                key: const ValueKey('pause-exercise-gif'),
                onPressed: () => setState(() => _playing = !_playing),
                icon: Icon(_playing ? AppIcons.pause : AppIcons.play, size: 16),
                label: Text(_playing ? 'Tạm dừng GIF' : 'Phát GIF'),
              )
            else
              TextButton.icon(
                key: const ValueKey('load-exercise-gif'),
                onPressed: service.enabled && !_loading ? _load : null,
                icon: const Icon(AppIcons.play, size: 16),
                label: Text(_error == null ? 'Xem GIF' : 'Thử tải lại GIF'),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _media() => Semantics(
    label: 'GIF minh họa ${widget.entry.name}',
    child: kIsWeb
        ? (_playing
              ? Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      _uri.toString(),
                      fit: BoxFit.contain,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, _, _) => Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Chưa tải được GIF. Dừng rồi thử mở lại.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    'GIF đã dừng. Bấm phát để xem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ))
        : _MemoryGif(
            bytes: _bytes!,
            sourceId: widget.entry.sourceId,
            playing: _playing,
            darkBackground: Theme.of(context).brightness == Brightness.dark,
          ),
  );

  Widget _compactPreview(ExerciseDbService service, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          key: const ValueKey('exercise-gif-frame'),
          height: 150,
          width: double.infinity,
          child: ColoredBox(
            color: _uri != null
                ? (theme.brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white)
                : theme.colorScheme.surfaceContainer,
            child: _uri != null
                ? _media()
                : _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        !service.enabled
                            ? 'GIF chỉ có trong bản kiểm thử.'
                            : _error ?? 'GIF minh họa động tác',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _error == null
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: _uri != null
            ? TextButton.icon(
                key: const ValueKey('pause-exercise-gif'),
                onPressed: () => setState(() => _playing = !_playing),
                icon: Icon(_playing ? AppIcons.pause : AppIcons.play, size: 18),
                label: Text(_playing ? 'Tạm dừng GIF' : 'Phát GIF'),
              )
            : TextButton.icon(
                key: const ValueKey('load-exercise-gif'),
                onPressed: service.enabled && !_loading ? _load : null,
                icon: const Icon(AppIcons.play, size: 18),
                label: Text(_error == null ? 'Xem GIF' : 'Thử lại GIF'),
              ),
      ),
    ],
  );

  Widget _thumbnail(ExerciseDbService service, ThemeData theme) => SizedBox(
    key: const ValueKey('exercise-gif-frame'),
    height: widget.height ?? 150,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: _uri != null
              ? (theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white)
              : theme.colorScheme.surfaceContainer,
          child: _uri != null
              ? _media()
              : _loading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 44),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _error == null
                              ? AppIcons.workout
                              : AppIcons.cloudAlert,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          !service.enabled
                              ? 'GIF kiểm thử'
                              : _error == null
                              ? 'GIF minh họa'
                              : 'Chưa tải được',
                          style: theme.textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (!_loading)
          Positioned(
            right: 4,
            bottom: 4,
            child: IconButton.filledTonal(
              key: ValueKey(
                _uri != null ? 'pause-exercise-gif' : 'load-exercise-gif',
              ),
              tooltip: _uri != null
                  ? (_playing ? 'Tạm dừng GIF' : 'Phát GIF')
                  : !service.enabled
                  ? 'GIF chỉ có trong bản kiểm thử'
                  : (_error ?? 'Xem GIF'),
              onPressed: _uri != null
                  ? () => setState(() => _playing = !_playing)
                  : service.enabled
                  ? _load
                  : null,
              style: IconButton.styleFrom(
                backgroundColor: _uri != null ? const Color(0xE6212121) : null,
                foregroundColor: _uri != null ? Colors.white : null,
                minimumSize: const Size(44, 44),
              ),
              icon: Icon(
                _uri != null && _playing ? AppIcons.pause : AppIcons.play,
                size: 18,
              ),
            ),
          ),
      ],
    ),
  );
}

class _MemoryGif extends StatefulWidget {
  const _MemoryGif({
    required this.bytes,
    required this.sourceId,
    required this.playing,
    required this.darkBackground,
  });
  final Uint8List bytes;
  final String sourceId;
  final bool playing;
  final bool darkBackground;
  @override
  State<_MemoryGif> createState() => _MemoryGifState();
}

class _MemoryGifState extends State<_MemoryGif> {
  ui.Codec? _codec;
  ui.Image? _image;
  ui.Image? _darkFrame;
  Timer? _timer;
  bool _decoding = false, _failed = false;
  Duration _duration = const Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.bytes,
        targetWidth: 360,
        allowUpscaling: false,
      );
      if (!mounted) {
        codec.dispose();
        return;
      }
      _codec = codec;
      await _nextFrame();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _nextFrame() async {
    if (_decoding || _codec == null || !mounted) return;
    _decoding = true;
    ui.Image? pendingImage, pendingDark;
    try {
      final frame = await _codec!.getNextFrame();
      pendingImage = frame.image;
      if (!mounted) {
        return;
      }
      if (widget.darkBackground) {
        pendingDark = await _makeDarkFrame(frame.image);
      }
      if (!mounted) {
        return;
      }
      final old = _image, oldDark = _darkFrame;
      setState(() {
        _image = frame.image;
        _darkFrame = pendingDark;
        _duration = frame.duration < const Duration(milliseconds: 30)
            ? const Duration(milliseconds: 100)
            : frame.duration;
      });
      pendingImage = null;
      pendingDark = null;
      old?.dispose();
      oldDark?.dispose();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      pendingImage?.dispose();
      pendingDark?.dispose();
      _decoding = false;
    }
    _schedule();
  }

  Future<ui.Image> _makeDarkFrame(ui.Image source) async {
    final data = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) throw StateError('Cannot read GIF frame.');
    final rgba = clearExerciseGifBackground(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      source.width,
      source.height,
      sourceId: widget.sourceId,
    );
    final result = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      source.width,
      source.height,
      ui.PixelFormat.rgba8888,
      result.complete,
    );
    return result.future;
  }

  Future<void> _prepareDarkFrame() async {
    final source = _image;
    if (source == null || _darkFrame != null) return;
    final retained = source.clone();
    try {
      final darkFrame = await _makeDarkFrame(retained);
      if (!mounted || !identical(source, _image) || _darkFrame != null) {
        darkFrame.dispose();
        return;
      }
      setState(() => _darkFrame = darkFrame);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      retained.dispose();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (mounted &&
        widget.playing &&
        !_failed &&
        (_codec?.frameCount ?? 0) > 1) {
      _timer = Timer(_duration, _nextFrame);
    }
  }

  @override
  void didUpdateWidget(_MemoryGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.darkBackground && !oldWidget.darkBackground) {
      unawaited(_prepareDarkFrame());
    }
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codec?.dispose();
    _image?.dispose();
    _darkFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _failed
      ? const Center(child: Text('Không đọc được GIF. Đóng GIF rồi thử lại.'))
      : _image == null || (widget.darkBackground && _darkFrame == null)
      ? const Center(child: CircularProgressIndicator())
      : RawImage(
          image: widget.darkBackground ? _darkFrame : _image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
}
