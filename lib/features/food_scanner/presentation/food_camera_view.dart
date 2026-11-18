import '../../../core/theme/app_icons.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/food_camera_service.dart';
import '../data/food_image_picker.dart';
import '../data/food_scanner_service.dart';

class FoodCameraView extends ConsumerStatefulWidget {
  const FoodCameraView({
    required this.active,
    required this.onImage,
    required this.onGallery,
    required this.onBarcode,
    this.errorMessage,
    super.key,
  });
  final bool active;
  final ValueChanged<FoodImage> onImage;
  final VoidCallback onGallery, onBarcode;
  final String? errorMessage;
  @override
  ConsumerState<FoodCameraView> createState() => _FoodCameraViewState();
}

class _FoodCameraViewState extends ConsumerState<FoodCameraView>
    with WidgetsBindingObserver {
  late final FoodCameraService _camera;
  FoodCameraSession? _session;
  int _generation = 0;
  bool _starting = false, _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(foodCameraServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _start();
  }

  Future<void> _start() async {
    final generation = ++_generation;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final session = await _camera.open();
      if (!mounted || generation != _generation || !widget.active) {
        await _camera.release(session);
        return;
      }
      setState(() {
        _session = session;
        _starting = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _starting = false;
        _error = error is FoodScannerFailure
            ? error.message
            : 'Chưa mở được camera. Kiểm tra quyền camera, thử lại hoặc chọn ảnh.';
      });
    }
  }

  void _stop() {
    _generation++;
    _session = null;
    unawaited(_camera.release().catchError((Object _, StackTrace _) {}));
  }

  @override
  void didUpdateWidget(covariant FoodCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (widget.active) {
      _start();
    } else {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _stop();
    } else if (widget.active) {
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  Future<void> _capture() async {
    final session = _session;
    if (session == null || _capturing || !widget.active) return;
    final generation = _generation;
    setState(() => _capturing = true);
    try {
      final image = await _camera.capture(session);
      await _camera.release(session);
      if (mounted && widget.active && generation == _generation) {
        widget.onImage(image);
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = error is FoodScannerFailure
              ? error.message
              : 'Chưa chụp được ảnh. Hãy thử lại hoặc chọn ảnh.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final error = _error ?? widget.errorMessage;
      return ColoredBox(
        color: Colors.black,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Chip(
                    avatar: Icon(AppIcons.nutrition),
                    label: Text('Ảnh món ăn'),
                  ),
                  ActionChip(
                    key: const ValueKey('camera-barcode'),
                    avatar: const Icon(AppIcons.scanBarcode),
                    label: const Text('Mã vạch'),
                    onPressed: _capturing ? null : widget.onBarcode,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_session?.controller case final controller?)
                        CameraPreview(controller),
                      IgnorePointer(
                        child: CustomPaint(painter: _ScanFramePainter()),
                      ),
                      Center(
                        child: _starting && widget.active
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : error == null
                            ? const SizedBox.shrink()
                            : SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        AppIcons.cameraOff,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        error,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: widget.active
                                            ? _start
                                            : null,
                                        child: const Text('Thử mở lại camera'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const Positioned(
                        top: 20,
                        left: 24,
                        right: 24,
                        child: Text(
                          'Đặt toàn bộ món ăn trong khung',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    key: const ValueKey('camera-gallery'),
                    onPressed: _capturing ? null : widget.onGallery,
                    tooltip: 'Chọn ảnh',
                    iconSize: 32,
                    color: Colors.white,
                    icon: const Icon(AppIcons.images),
                  ),
                  Semantics(
                    button: true,
                    label: 'Chụp ảnh món ăn',
                    child: SizedBox.square(
                      dimension: 82,
                      child: OutlinedButton(
                        key: const ValueKey('camera-shutter'),
                        onPressed:
                            _session == null || _capturing || !widget.active
                            ? null
                            : _capture,
                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(5),
                          side: const BorderSide(color: Colors.white, width: 3),
                        ),
                        child: _capturing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.expand(),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path();
    const inset = 3.0, radius = 26.0, corner = 52.0;
    final right = rect.right - inset, bottom = rect.bottom - inset;
    path.moveTo(inset, inset + corner);
    path.lineTo(inset, inset + radius);
    path.quadraticBezierTo(inset, inset, inset + radius, inset);
    path.lineTo(inset + corner, inset);
    path.moveTo(right - corner, inset);
    path.lineTo(right - radius, inset);
    path.quadraticBezierTo(right, inset, right, inset + radius);
    path.lineTo(right, inset + corner);
    path.moveTo(inset, bottom - corner);
    path.lineTo(inset, bottom - radius);
    path.quadraticBezierTo(inset, bottom, inset + radius, bottom);
    path.lineTo(inset + corner, bottom);
    path.moveTo(right - corner, bottom);
    path.lineTo(right - radius, bottom);
    path.quadraticBezierTo(right, bottom, right, bottom - radius);
    path.lineTo(right, bottom - corner);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
