import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TicketBarcodeScannerView extends StatefulWidget {
  const TicketBarcodeScannerView({super.key});

  @override
  State<TicketBarcodeScannerView> createState() => _TicketBarcodeScannerViewState();
}

class _TicketBarcodeScannerViewState extends State<TicketBarcodeScannerView> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.code39, BarcodeFormat.code128],
    cameraResolution: const Size(1920, 1080),
  );

  final _demoInputController = TextEditingController();
  bool _hasScanned = false;
  double _currentZoom = 0.0;

  @override
  void dispose() {
    _scannerController.dispose();
    _demoInputController.dispose();
    super.dispose();
  }

  void _handleBarcodeScanned(String rawData) {
    if (_hasScanned) return;
    _hasScanned = true;
    _scannerController.stop();
    Navigator.of(context).pop(rawData.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowWidth = MediaQuery.of(context).size.width * 0.8;
    final scanWindowHeight = 120.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        title: const Text('Quét mã vạch Phiếu khám', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentZoom == 0.0 ? '1x' : '2x',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
              ),
            ),
            tooltip: 'Thu phóng',
            onPressed: () {
              setState(() {
                _currentZoom = _currentZoom == 0.0 ? 0.35 : 0.0;
                _scannerController.setZoomScale(_currentZoom);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  debugPrint('Scanned Raw Barcode: ${barcode.rawValue}');
                  _handleBarcodeScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. Custom Overlay with laser line
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    color: Colors.transparent,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: scanWindowWidth,
                      height: scanWindowHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Target boundaries & Laser animation
          Align(
            alignment: Alignment.center,
            child: Container(
              width: scanWindowWidth,
              height: scanWindowHeight,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0D6EFD), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Laser line
                  Center(
                    child: Container(
                      width: scanWindowWidth - 10,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Help text
          Positioned(
            left: 16,
            right: 16,
            top: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đặt mã vạch nằm chính giữa khung ngắm để quét tìm phiếu khám tương ứng.',
                      style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Simulator Panel for web/emulators
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.white.withValues(alpha: 0.95),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chế độ máy ảo / Giả lập (Simulator)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _demoInputController,
                      decoration: InputDecoration(
                        hintText: 'Nhập Mã BN muốn tìm...',
                        hintStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            _demoInputController.text = '12345678';
                          },
                          child: const Text('Mẫu: 12345678', style: TextStyle(fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () {
                            _demoInputController.text = '97192187';
                          },
                          child: const Text('Mẫu: 97192187', style: TextStyle(fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () {
                            _demoInputController.text = '07641190';
                          },
                          child: const Text('Mẫu: 07641190', style: TextStyle(fontSize: 11)),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            final input = _demoInputController.text.trim();
                            if (input.isNotEmpty) {
                              _handleBarcodeScanned(input);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Giả lập quét', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
