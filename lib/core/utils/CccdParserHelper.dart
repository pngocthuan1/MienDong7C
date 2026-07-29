import 'dart:convert';

class CccdData {
  final String cccdNumber;
  final String oldIdNumber;
  final String fullName;
  final String birthDate;
  final String gender;
  final String address;
  final String issueDate;
  final bool isBhyt;

  CccdData({
    required this.cccdNumber,
    required this.oldIdNumber,
    required this.fullName,
    required this.birthDate,
    required this.gender,
    required this.address,
    required this.issueDate,
    this.isBhyt = false,
  });

  String get birthYear {
    if (birthDate.contains('/')) {
      final dateParts = birthDate.split('/');
      if (dateParts.isNotEmpty) {
        return dateParts.last.trim();
      }
    }
    if (birthDate.length >= 4) {
      return birthDate.substring(birthDate.length - 4);
    }
    return birthDate.isNotEmpty ? birthDate.trim() : '1997';
  }
}

class CccdParserHelper {
  // LOGIC NHẬN DIỆN & GIẢI MÃ HEX TIẾNG VIỆT
  static String decodeHexIfNeeded(String input) {
    final cleaned = input.trim();
    // Kiểm tra định dạng Hex hợp lệ (chữ số từ 0-9, a-f)
    if (cleaned.length % 2 != 0 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned)) {
      return input;
    }
    try {
      final List<int> bytes = [];
      for (int i = 0; i < cleaned.length; i += 2) {
        final hexChar = cleaned.substring(i, i + 2);
        bytes.add(int.parse(hexChar, radix: 16));
      }
      // allowMalformed: true giúp giải mã phần chữ hợp lệ kể cả khi chuỗi Hex bị camera quét thiếu ký tự cuối
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return input;
    }
  }

  // PHÂN TÍCH CHUỖI ĐỊNH DANH SAU KHI QUÉT
  static CccdData? parse(String rawData) {
    try {
      final parts = rawData.split('|');
      if (parts.isEmpty) return null;

      final firstField = parts[0].trim();

      // Định dạng 1: QR BHYT trên ứng dụng VssID mới (chỉ có 2 trường)
      if (parts.length == 2) {
        return CccdData(
          cccdNumber: firstField,
          oldIdNumber: '',
          fullName: decodeHexIfNeeded(parts[1]),
          birthDate: '', // VssID không chứa ngày sinh
          gender: 'Nam',
          address: '',
          issueDate: '',
          isBhyt: true,
        );
      }

      if (parts.length < 5) return null;

      // Kiểm tra xem là BHYT truyền thống hay CCCD
      final isBhyt = firstField.length != 12 || !RegExp(r'^\d{12}$').hasMatch(firstField);

      if (isBhyt) {
        // Định dạng 2: BHYT giấy truyền thống (5+ trường)
        final rawGender = parts[3].trim();
        final genderText = (rawGender == '2' || rawGender == 'Nữ') ? 'Nữ' : 'Nam';
        return CccdData(
          cccdNumber: firstField,
          oldIdNumber: '',
          fullName: decodeHexIfNeeded(parts[1]),
          birthDate: parts[2].trim(),
          gender: genderText,
          address: decodeHexIfNeeded(parts[4]),
          issueDate: parts.length > 8 ? parts[8].trim() : '',
          isBhyt: true,
        );
      } else {
        // Định dạng 3: Thẻ Căn cước công dân (CCCD) Việt Nam
        return CccdData(
          cccdNumber: firstField,
          oldIdNumber: parts[1].trim(),
          fullName: decodeHexIfNeeded(parts[2]),
          birthDate: parts[3].trim(),
          gender: parts[4].trim(),
          address: decodeHexIfNeeded(parts[5]),
          issueDate: parts.length > 6 ? parts[6].trim() : '',
          isBhyt: false,
        );
      }
    } catch (_) {
      return null;
    }
  }
}
