import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen barcode scanner view.
///
/// Uses a forced dark scaffold with high-contrast overlays so that UI
/// elements remain visible regardless of what the camera is pointing at.
class ScannerScreen extends StatefulWidget {
  /// If true, simply pops with the barcode value (used by Add Item).
  /// If false, pops with the barcode for the caller to handle navigation.
  final bool returnBarcodeOnly;

  const ScannerScreen({super.key, this.returnBarcodeOnly = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _hasScanned = true;
    Navigator.of(context).pop(barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    // Scanner ALWAYS uses dark theme regardless of app theme
    // to ensure visibility over the camera feed.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // Flashlight toggle with scrim
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: state.torchState == TorchState.on
                        ? Colors.amber
                        : Colors.white,
                  );
                },
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
          // Camera switch with scrim
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.cameraswitch_rounded,
                  color: Colors.white),
              onPressed: () => _controller.switchCamera(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark scrim around the scan area
          _buildScanOverlay(),

          // Bottom instruction pill
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Point camera at barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a dark transparent scrim around the scan window
  /// so that text/icons remain readable against any camera background.
  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const scanSize = 280.0;
        final left = (constraints.maxWidth - scanSize) / 2;
        final top = (constraints.maxHeight - scanSize) / 2;

        return Stack(
          children: [
            // Top scrim
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: top,
              child: Container(
                  color: Colors.black.withValues(alpha: 0.5)),
            ),
            // Bottom scrim
            Positioned(
              top: top + scanSize,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  color: Colors.black.withValues(alpha: 0.5)),
            ),
            // Left scrim
            Positioned(
              top: top,
              left: 0,
              width: left,
              height: scanSize,
              child: Container(
                  color: Colors.black.withValues(alpha: 0.5)),
            ),
            // Right scrim
            Positioned(
              top: top,
              right: 0,
              width: left,
              height: scanSize,
              child: Container(
                  color: Colors.black.withValues(alpha: 0.5)),
            ),
            // Scan border
            Center(
              child: Container(
                width: scanSize,
                height: scanSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF6366F1),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
