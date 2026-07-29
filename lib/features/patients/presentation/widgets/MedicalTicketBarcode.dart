import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

class MedicalTicketBarcode extends StatelessWidget {
  const MedicalTicketBarcode({
    required this.seed,
    super.key,
  });

  final String seed;

  @override
  Widget build(BuildContext context) {
    final cleanSeed = seed.trim();
    if (cleanSeed.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: BarcodeWidget(
          barcode: Barcode.code128(), // BẮT BUỘC dùng Barcode.code128() theo chuẩn máy quét Bệnh viện
          data: cleanSeed,
          width: 260,
          height: 75,
          drawText: false, // Ẩn chữ bên dưới vạch để không gây nhiễu nhận diện
        ),
      ),
    );
  }
}
