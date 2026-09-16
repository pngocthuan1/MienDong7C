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
    formats: const [
      BarcodeFormat.code39,
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
    ], // Hỗ trợ cả Barcode dẹt chuẩn bệnh viện và QR Code
    cameraResolution: const Size(1920, 1080),
  );

  bool _hasScanned = false;
  double _currentZoom = 0.0;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcodeScanned(String rawData) {
    if (_hasScanned) return;
    _hasScanned = true;
    _scannerController.stop();
    Navigator.of(context).pop(rawData.trim()); // Trả về mã số bệnh nhân quét được
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowWidth = MediaQuery.of(context).size.width * 0.8;
    const scanWindowHeight = 120.0;

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
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _handleBarcodeScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Lớp phủ tối xung quanh khe quét mã vạch dẹt
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(color: Colors.transparent),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: scanWindowWidth,
                      height: scanWindowHeight,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Khung ngắm định vị và Dải tia Laser căn chỉnh màu đỏ ở giữa
          Align(
            alignment: Alignment.center,
            child: Container(
              width: scanWindowWidth,
              height: scanWindowHeight,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0D6EFD), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  width: scanWindowWidth - 10,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
