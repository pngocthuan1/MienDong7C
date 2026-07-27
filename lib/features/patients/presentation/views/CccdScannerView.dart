import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:benhvien7c/core/utils/CccdParserHelper.dart';

class CccdScannerView extends StatefulWidget {
  const CccdScannerView({super.key});

  @override
  State<CccdScannerView> createState() => _CccdScannerViewState();
}

class _CccdScannerViewState extends State<CccdScannerView> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
    cameraResolution: const Size(1920, 1080), // Yêu cầu độ phân giải Full HD để quét 1x cực nhanh và nét
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

  void _handleQrScanned(String rawData) {
    if (_hasScanned) return;
    final parsedData = CccdParserHelper.parse(rawData);
    if (parsedData != null) {
      _hasScanned = true;
      _scannerController.stop();
      Navigator.of(context).pop(parsedData);
    } else {
      // Show snackbar if scanned code is not a valid CCCD QR code format
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã QR không đúng định dạng thẻ CCCD Việt Nam.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define scan window target area size (smaller so users naturally keep distance)
    final scanWindowSize = MediaQuery.of(context).size.width * 0.45;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        title: const Text('Quét thẻ CCCD / BHYT', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  debugPrint('Scanned Raw QR: ${barcode.rawValue}');
                  _handleQrScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Floating tips for laminated / glossy cards
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MẸO QUÉT THẺ ÉP DẺO / ÉP PLASTIC (BỊ BÓNG):',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '• Nghiêng nhẹ thẻ 10 - 15 độ để chuyển hướng vệt lóa sáng.\n• KHÔNG bật đèn Flash (đèn flash sẽ gây lóa trắng xóa mã QR).\n• Giữ khoảng cách 15-20cm và dùng nút [2x] ở trên nếu mã quá nhỏ.',
                          style: TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Custom Overlay for Scan Area (Khoanh vùng)
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1),
                      width: scanWindowSize,
                      height: scanWindowSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Scan Frame Border & Instructions
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
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Giữ khoảng cách 15 - 20 cm để ảnh rõ nét\nBấm nút [1x/2x] ở góc trên nếu mã quá nhỏ\nMẹo: Nếu thẻ bị bóng/lóa sáng, hãy nghiêng nhẹ thẻ',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Demo Simulator / Input at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.white.withOpacity(0.95),
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
                        hintText: 'Nhập chuỗi QR CCCD hoặc bấm dùng mẫu thử...',
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
                            _demoInputController.text =
                                '038097012345||Nguyễn Văn Nam|15081997|Nam|Số 12 Đường Láng, Hà Nội|25122021';
                          },
                          child: const Text('Mẫu CCCD', style: TextStyle(fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () {
                            _demoInputController.text =
                                'GD4979624567890|Nguyễn Văn Nam|15/08/1997|1|Số 12 Đường Láng, Hà Nội|01001|01/01/2020|31/12/2025|';
                          },
                          child: const Text('Mẫu BHYT', style: TextStyle(fontSize: 11)),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            final input = _demoInputController.text.trim();
                            if (input.isNotEmpty) {
                              _handleQrScanned(input);
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
