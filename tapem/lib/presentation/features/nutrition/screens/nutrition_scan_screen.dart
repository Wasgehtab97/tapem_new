import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_product.dart';
import '../providers/nutrition_providers.dart';

class NutritionScanScreen extends ConsumerStatefulWidget {
  const NutritionScanScreen({super.key, required this.extra});

  final Map<String, dynamic> extra;

  @override
  ConsumerState<NutritionScanScreen> createState() =>
      _NutritionScanScreenState();
}

class _NutritionScanScreenState extends ConsumerState<NutritionScanScreen> {
  final _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;
  String? _lastFailedBarcode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;
    if (barcode == _lastFailedBarcode) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final service = ref.read(nutritionProductServiceProvider);
    final product = await service.getByBarcode(barcode);

    if (!mounted) return;

    final returnProduct = widget.extra['returnProduct'] as bool? ?? false;

    if (product != null) {
      _lastFailedBarcode = null;
      if (returnProduct) {
        context.pop<NutritionProduct>(product);
      } else {
        context.pushReplacement('/nutrition/entry', extra: {
          ...widget.extra,
          'product': product,
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface700,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Produkt nicht gefunden. Manuell eingeben?',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
            ),
            action: SnackBarAction(
              label: 'MANUELL',
              textColor: AppColors.neonCyan,
              onPressed: () {
                if (returnProduct) {
                  context.pop();
                } else {
                  context.pushReplacement(
                    '/nutrition/entry',
                    extra: widget.extra,
                  );
                }
              },
            ),
          ),
        );
        setState(() => _isProcessing = false);
        _lastFailedBarcode = barcode;
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('BARCODE SCANNEN', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? AppColors.neonCyan : Colors.white70,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white70),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Dark overlay with cutout
          _ScanOverlay(),

          // Cyan scan frame
          Center(
            child: Container(
              width: 280,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neonCyan, width: 2.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // Corner accents
                  Positioned(
                    top: -1,
                    left: -1,
                    child: _CornerDot(),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: _CornerDot(),
                  ),
                  Positioned(
                    bottom: -1,
                    left: -1,
                    child: _CornerDot(),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: _CornerDot(),
                  ),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan),
              ),
            ),

          // Hint text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Barcode in den Rahmen halten',
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan frame overlay ───────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cutoutWidth = 280.0;
    final cutoutHeight = 140.0;
    final left = (size.width - cutoutWidth) / 2;
    final top = (size.height - cutoutHeight) / 2;

    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Top rect
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    // Bottom rect
    canvas.drawRect(
        Rect.fromLTWH(0, top + cutoutHeight, size.width, size.height - top - cutoutHeight),
        paint);
    // Left rect
    canvas.drawRect(Rect.fromLTWH(0, top, left, cutoutHeight), paint);
    // Right rect
    canvas.drawRect(
        Rect.fromLTWH(left + cutoutWidth, top, size.width - left - cutoutWidth, cutoutHeight),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.neonCyan,
        shape: BoxShape.circle,
      ),
    );
  }
}
