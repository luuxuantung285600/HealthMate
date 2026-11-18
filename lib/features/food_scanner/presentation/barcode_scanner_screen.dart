import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/barcode_scanner_service.dart';
import '../data/barcode_product_service.dart';
import '../models/barcode_product_models.dart';
import 'barcode_product_detail_sheet.dart';

final barcodeMealScannerProvider =
    Provider<Future<BarcodeMealSelection?> Function(BuildContext)>(
      (ref) =>
          (context) => Navigator.push<BarcodeMealSelection>(
            context,
            MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
          ),
    );

/// Màn hình quét barcode full-screen
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _scannerService = BarcodeScannerService();
  final _productService = BarcodeProductService();
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    _controller = _scannerService.getController();
  }

  @override
  void dispose() {
    _scannerService.dispose();
    _productService.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    // Tránh scan lặp cùng một mã
    if (_lastScanned == barcode) return;

    setState(() {
      _isProcessing = true;
      _lastScanned = barcode;
    });

    try {
      // Pause camera khi đang tra cứu
      await _controller.stop();

      // Tra cứu thông tin sản phẩm
      final product = await _productService.lookupBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        // Hiển thị thông tin sản phẩm
        final result = await showModalBottomSheet<BarcodeMealSelection>(
          context: context,
          isScrollControlled: true,
          builder: (_) => BarcodeProductDetailSheet(product: product),
        );

        if (result != null && mounted) {
          // Người dùng chọn "Thêm vào bữa ăn"
          Navigator.pop(context, result);
          return;
        }
      } else {
        // Không tìm thấy sản phẩm
        if (!mounted) return;
        final enterManually = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Không tìm thấy sản phẩm'),
            content: Text(
              'Mã vạch "$barcode" không có trong cơ sở dữ liệu.\n\n'
              'Bạn có thể nhập thông tin món ăn thủ công.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Nhập thủ công'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quét lại'),
              ),
            ],
          ),
        );
        if (enterManually == true) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      // Resume camera để quét tiếp
      if (mounted) {
        await _controller.start();
        setState(() {
          _isProcessing = false;
          _lastScanned = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Lỗi tra cứu'),
          content: Text(
            e is BarcodeLookupFailure
                ? e.message
                : 'Chưa thể quét mã. Hãy thử lại hoặc nhập thủ công.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );

      if (mounted) {
        await _controller.start();
        setState(() {
          _isProcessing = false;
          _lastScanned = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        title: const Text('Quét mã vạch'),
        actions: [
          IconButton(
            onPressed: _isProcessing ? null : _scannerService.toggleTorch,
            icon: Icon(
              _scannerService.hasTorch ? AppIcons.zap : AppIcons.zapOff,
            ),
            tooltip: 'Đèn flash',
          ),
          IconButton(
            onPressed: _isProcessing ? null : _scannerService.switchCamera,
            icon: const Icon(AppIcons.switchCamera),
            tooltip: 'Đổi camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Scan guide overlay
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.grey : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang tra cứu sản phẩm...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions
          if (!_isProcessing)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đặt mã vạch vào giữa khung để quét',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
