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
      if (dateParts.isNotEmpty && dateParts.last.trim().isNotEmpty) {
        return dateParts.last.trim();
      }
    }
    if (birthDate.length >= 4) {
      return birthDate.substring(birthDate.length - 4);
    }
    return birthDate.trim();
  }

  String get formattedBirthDate {
    final clean = birthDate.trim();
    if (clean.contains('/')) return clean;
    if (clean.length == 8 && RegExp(r'^\d{8}$').hasMatch(clean)) {
      return '${clean.substring(0, 2)}/${clean.substring(2, 4)}/${clean.substring(4)}';
    }
    return clean;
  }

  String get formattedIssueDate {
    final clean = issueDate.trim();
    if (clean.contains('/')) return clean;
    if (clean.length == 8 && RegExp(r'^\d{8}$').hasMatch(clean)) {
      return '${clean.substring(0, 2)}/${clean.substring(2, 4)}/${clean.substring(4)}';
    }
    return clean;
  }
}

class CccdParserHelper {
  // LOGIC NHẬN DIỆN & GIẢI MÃ HEX TIẾNG VIỆT
  static String decodeHexIfNeeded(String input) {
    final cleaned = input.trim();
    // Nếu chuỗi toàn chữ số (ngày sinh, số CCCD, v.v.), không bao giờ là chuỗi Hex mã hóa
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return input;
    }
    // Kiểm tra định dạng Hex hợp lệ (chữ số từ 0-9, a-f) và độ dài chẵn
    if (cleaned.length % 2 != 0 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned)) {
      return input;
    }
    // Chuỗi Hex của tiếng Việt / văn bản bắt buộc phải chứa ít nhất ký tự chữ cái a-f
    if (!RegExp(r'[a-fA-F]').hasMatch(cleaned)) {
      return input;
    }
    try {
      final List<int> bytes = [];
      for (int i = 0; i < cleaned.length; i += 2) {
        final hexChar = cleaned.substring(i, i + 2);
        bytes.add(int.parse(hexChar, radix: 16));
      }
      // allowMalformed: true giúp giải mã phần chữ hợp lệ kể cả khi chuỗi Hex bị camera quét thiếu ký tự cuối
      final decoded = utf8.decode(bytes, allowMalformed: true);
      // Nếu giải mã ra chứa các ký tự điều khiển lạ (control characters < 32 ngoại trừ tab/newline), trả về input gốc
      if (decoded.runes.any((r) => r < 32 && r != 9 && r != 10 && r != 13)) {
        return input;
      }
      return decoded;
    } catch (_) {
      return input;
    }
  }

  static bool _isGender(String text) {
    final clean = text.trim().toLowerCase();
    return clean == 'nam' ||
        clean == 'nữ' ||
        clean == 'nu' ||
        clean == '1' ||
        clean == '2' ||
        clean == 'male' ||
        clean == 'female' ||
        clean == 'm' ||
        clean == 'f';
  }

  static String _normalizeGender(String text) {
    final clean = text.trim().toLowerCase();
    if (clean == 'nữ' || clean == 'nu' || clean == '2' || clean == 'female' || clean == 'f') {
      return 'Nữ';
    }
    return 'Nam';
  }

  static bool _isDate(String text) {
    final clean = text.trim();
    return RegExp(r'^\d{8}$').hasMatch(clean) ||
        RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(clean) ||
        RegExp(r'^\d{4}$').hasMatch(clean);
  }

  // PHÂN TÍCH CHUỖI ĐỊNH DANH SAU KHI QUÉT
  static CccdData? parse(String rawData) {
    try {
      final delimiter = rawData.contains('|') ? '|' : (rawData.contains(r'$') ? r'$' : '|');
      final parts = rawData.split(delimiter);
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

      final looksLikeCccdNumber = RegExp(r'^\d{12}$').hasMatch(firstField);

      // Nếu trường đầu tiên KHÔNG PHẢI 12 số định danh CCCD -> BHYT thẻ giấy truyền thống
      if (!looksLikeCccdNumber) {
        final rawGender = parts[3].trim();
        final genderText = _normalizeGender(rawGender);
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
      }

      // THẺ CĂN CƯỚC / CCCD (12 SỐ)
      // Phân biệt Thẻ Căn cước mới (từ 01/07/2024 theo Thông tư 16/2024/TT-BCA) và Thẻ CCCD gắn chip cũ (trước 01/07/2024)
      final part1Clean = decodeHexIfNeeded(parts[1]).trim();
      final part2Clean = decodeHexIfNeeded(parts[2]).trim();

      // Ở CCCD cũ & Căn cước mới có trường CMND: parts[1] là số CMND cũ (hoặc rỗng), parts[2] là Họ và tên.
      // Ở Căn cước mới không có trường CMND: parts[1] là Họ và tên, parts[2] là Giới tính (hoặc Ngày sinh).
      final isPart1OldId = part1Clean.isEmpty || RegExp(r'^\d+$').hasMatch(part1Clean);
      final isPart2GenderOrDate = _isGender(part2Clean) || _isDate(part2Clean);
      final isNewFormat = !isPart1OldId || isPart2GenderOrDate;

      if (!isNewFormat) {
        // === ĐỊNH DẠNG CCCD CŨ (2021 - 2024) ===
        // parts[0]: Số CCCD 12 số
        // parts[1]: Số CMND 9 số cũ (hoặc rỗng)
        // parts[2]: Họ và tên
        // parts[3]: Ngày sinh (ddMMyyyy)
        // parts[4]: Giới tính (Nam/Nữ)
        // parts[5]: Địa chỉ thường trú
        // parts[6]: Ngày cấp thẻ
        return CccdData(
          cccdNumber: firstField,
          oldIdNumber: parts[1].trim(),
          fullName: part2Clean,
          birthDate: parts[3].trim(),
          gender: _normalizeGender(parts[4].trim()),
          address: decodeHexIfNeeded(parts[5]),
          issueDate: parts.length > 6 ? parts[6].trim() : '',
          isBhyt: false,
        );
      }

      // === ĐỊNH DẠNG THẺ CĂN CƯỚC MỚI (Từ 01/07/2024 - 2025 - 2026+) ===
      // Theo Thông tư 16/2024/TT-BCA:
      // parts[0]: Số định danh cá nhân (12 số)
      // parts[1]: Họ, chữ đệm và tên khai sinh
      // parts[2]: Giới tính (hoặc Ngày sinh)
      // parts[3]: Ngày sinh (hoặc Giới tính)
      // parts[4]: Nơi cư trú
      // parts[5]: Ngày, tháng, năm cấp thẻ căn cước
      // parts[6]: Số CMND 9 số cũ (nếu có)
      // parts[7]: Số ĐDCN đã hủy (nếu có)
      final fullName = part1Clean;

      String gender = 'Nam';
      String birthDate = '';
      final p3Clean = parts.length > 3 ? decodeHexIfNeeded(parts[3]).trim() : '';

      if (_isGender(part2Clean)) {
        gender = _normalizeGender(part2Clean);
        birthDate = p3Clean;
      } else if (_isGender(p3Clean)) {
        gender = _normalizeGender(p3Clean);
        birthDate = part2Clean;
      } else {
        if (_isDate(p3Clean)) {
          birthDate = p3Clean;
          gender = _normalizeGender(part2Clean);
        } else {
          birthDate = part2Clean;
          gender = _normalizeGender(p3Clean);
        }
      }

      String address = '';
      String issueDate = '';
      final p4Clean = parts.length > 4 ? decodeHexIfNeeded(parts[4]).trim() : '';
      final p5Clean = parts.length > 5 ? decodeHexIfNeeded(parts[5]).trim() : '';

      if (_isDate(p4Clean) && !_isDate(p5Clean)) {
        issueDate = p4Clean;
        address = p5Clean;
      } else {
        address = p4Clean;
        issueDate = p5Clean;
      }

      // Số CMND 9 số cũ (nếu có ở phần mở rộng)
      String oldIdNumber = '';
      if (parts.length > 6) {
        final p6Clean = parts[6].trim();
        if (RegExp(r'^\d{9}$').hasMatch(p6Clean)) {
          oldIdNumber = p6Clean;
        }
      }

      return CccdData(
        cccdNumber: firstField,
        oldIdNumber: oldIdNumber,
        fullName: fullName,
        birthDate: birthDate,
        gender: gender,
        address: address,
        issueDate: issueDate,
        isBhyt: false,
      );
    } catch (_) {
      return null;
    }
  }
}
