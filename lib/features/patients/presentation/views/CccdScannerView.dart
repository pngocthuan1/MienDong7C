import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:benhvien7c/core/utils/CccdParserHelper.dart';

class CccdScannerView extends StatefulWidget {
  const CccdScannerView({super.key});

  @override
  State<CccdScannerView> createState() => _CccdScannerViewState();
}

class _CccdScannerViewState extends State<CccdScannerView> {
  // CẤU HÌNH CAMERA QUÉT NHANH
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // Chống quét trùng lặp gây đơ đúp dữ liệu
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode], // Giới hạn chỉ quét mã QR Code để bắt nét nhanh hơn
    cameraResolution: const Size(1920, 1080), // Yêu cầu luồng Full HD để nhìn rõ mã QR nhỏ của CCCD
  );
  
  bool _hasScanned = false;
  double _currentZoom = 0.0;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleQrScanned(String rawData) {
    if (_hasScanned) return;
    final parsedData = CccdParserHelper.parse(rawData);
    if (parsedData != null) {
      _hasScanned = true;
      _scannerController.stop(); // Tắt camera ngay khi quét thành công
      Navigator.of(context).pop(parsedData); // Trả dữ liệu sạch về Form nhập liệu
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã QR không đúng định dạng thẻ CCCD / BHYT.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.45;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        title: const Text('Quét thẻ CCCD / BHYT', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Nút chuyển chế độ thu phóng 1x / 2x
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
          // Bật/tắt đèn pin Flash
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
                  _handleQrScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Lớp phủ làm tối màn hình xung quanh vùng quét (Khoanh vùng focus)
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1),
                      width: scanWindowSize,
                      height: scanWindowSize,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Khung viền màu xanh lá cây định vị vùng quét
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: scanWindowSize,
                    height: scanWindowSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00FF66), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(20)),
                    child: const Text(
                      'Đặt mã QR nằm gọn vào khung ngắm để quét',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
