import 'package:flutter/material.dart';

class MedicalTicketBarcode extends StatelessWidget {
  const MedicalTicketBarcode({
    required this.seed,
    super.key,
  });

  final String seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: CustomPaint(
        painter: _MedicalTicketBarcodePainter(seed),
      ),
    );
  }
}

class _MedicalTicketBarcodePainter extends CustomPainter {
  _MedicalTicketBarcodePainter(this.seed);

  final String seed;

  // Code 128 widths lookup map (0-102, Start B: 104, Stop: 106)
  static const Map<int, String> _code128Map = {
    0: "212222", 1: "222122", 2: "222221", 3: "121223", 4: "121322",
    5: "131222", 6: "122213", 7: "122312", 8: "132212", 9: "221213",
    10: "221312", 11: "231212", 12: "112232", 13: "122132", 14: "122231",
    15: "113222", 16: "123122", 17: "123221", 18: "223211", 19: "221132",
    20: "221231", 21: "213212", 22: "223112", 23: "312131", 24: "311222",
    25: "321122", 26: "321221", 27: "312212", 28: "322112", 29: "322211",
    30: "212123", 31: "212321", 32: "232121", 33: "111323", 34: "131123",
    35: "131321", 36: "112313", 37: "132113", 38: "132311", 39: "211313",
    40: "231113", 41: "231311", 42: "112133", 43: "112331", 44: "132131",
    45: "113123", 46: "113321", 47: "133121", 48: "313121", 49: "211331",
    50: "231131", 51: "213113", 52: "213311", 53: "213131", 54: "311123",
    55: "311321", 56: "312113", 57: "312311", 58: "332111", 59: "314111",
    60: "221411", 61: "431111", 62: "111224", 63: "111422", 64: "121124",
    65: "121421", 66: "141122", 67: "141221", 68: "112214", 69: "112412",
    70: "122114", 71: "122411", 72: "142112", 73: "142211", 74: "241211",
    75: "221114", 76: "413111", 77: "241112", 78: "134111", 79: "111242",
    80: "121142", 81: "121241", 82: "114212", 83: "124112", 84: "124211",
    85: "411212", 86: "421112", 87: "421211", 88: "212141", 89: "214121",
    90: "412121", 91: "111143", 92: "111341", 93: "131141", 94: "114113",
    95: "114311", 96: "411113", 97: "411311", 98: "113141", 99: "114131",
    100: "311141", 101: "411131", 102: "211412",
    104: "211214", // Start B
    106: "2331112", // Stop
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Filter characters to valid ASCII 32 - 126
    final String cleanSeed = seed.trim().replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    if (cleanSeed.isEmpty) return;

    final List<int> symbolValues = [];
    
    // 1. Start with Start Code B (104)
    symbolValues.add(104);

    // 2. Add data characters (value is ASCII - 32)
    for (int i = 0; i < cleanSeed.length; i++) {
      symbolValues.add(cleanSeed.codeUnitAt(i) - 32);
    }

    // 3. Calculate Checksum Modulo 103
    int sum = 104; // Start B
    for (int i = 0; i < cleanSeed.length; i++) {
      final value = cleanSeed.codeUnitAt(i) - 32;
      sum += value * (i + 1);
    }
    final checksum = sum % 103;
    symbolValues.add(checksum);

    // 4. End with Stop Code (106)
    symbolValues.add(106);

    // Calculate total modules (units)
    int totalUnits = 0;
    for (final val in symbolValues) {
      final pattern = _code128Map[val] ?? '';
      for (int i = 0; i < pattern.length; i++) {
        totalUnits += int.parse(pattern[i]);
      }
    }

    if (totalUnits == 0) return;

    final double maxBarcodeWidth = 260.0;
    final double barcodeWidth = size.width > maxBarcodeWidth ? maxBarcodeWidth : size.width;
    final double unitWidth = barcodeWidth / totalUnits;
    final double startX = (size.width - barcodeWidth) / 2;
    double currentX = startX;

    for (final val in symbolValues) {
      final pattern = _code128Map[val] ?? '';
      for (int i = 0; i < pattern.length; i++) {
        final double width = int.parse(pattern[i]) * unitWidth;
        final bool isBar = (i % 2 == 0); // Alternates, starting with a Bar
        
        if (isBar) {
          canvas.drawRect(
            Rect.fromLTWH(currentX, 0, width, size.height),
            paint,
          );
        }
        currentX += width;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MedicalTicketBarcodePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
