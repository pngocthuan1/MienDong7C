/// Tiện ích làm sạch, ẩn (mask) và tóm tắt dữ liệu nhạy cảm trước khi log.
/// Đảm bảo không bao giờ rò rỉ Token, Mật khẩu, OTP, CCCD, Số điện thoại ra Console.
class LogSanitizer {
  /// Che số điện thoại: giữ 3 số đầu và 4 số cuối (ví dụ "082***8431", "090***7251")
  static String maskPhone(dynamic phone) {
    if (phone == null) return '';
    final str = phone.toString().trim();
    if (str.isEmpty) return '';
    if (str.length >= 7) {
      final prefix = str.substring(0, 3);
      final suffix = str.substring(str.length - 4);
      return '$prefix***$suffix';
    }
    return '***';
  }

  /// Che CCCD / CMND / Mã bệnh nhân / Số định danh: giữ 3 ký tự đầu và 4 ký tự cuối (ví dụ "079***6789")
  static String maskIdentifier(dynamic id) {
    if (id == null) return '';
    final str = id.toString().trim();
    if (str.isEmpty) return '';
    if (str.length >= 7) {
      final prefix = str.substring(0, 3);
      final suffix = str.substring(str.length - 4);
      return '$prefix***$suffix';
    }
    return '***';
  }

  /// Ẩn hoàn toàn Access Token / Refresh Token / Captcha Token
  static String maskToken(dynamic token) {
    if (token == null) return 'null';
    final str = token.toString().trim();
    if (str.isEmpty) return '';
    return '[REDACTED: len=${str.length}]';
  }

  /// Làm sạch Authorization header (ví dụ "Bearer eyJhbGci...") -> "Bearer [REDACTED]"
  static String maskAuthorizationHeader(String? authHeader) {
    if (authHeader == null || authHeader.isEmpty) return '[NONE]';
    if (authHeader.toLowerCase().startsWith('bearer ')) {
      return 'Bearer [REDACTED]';
    }
    return '[REDACTED]';
  }

  static const _sensitiveExactKeys = {
    'password',
    'matkhau',
    'oldpassword',
    'newpassword',
    'confirmpassword',
    'otp',
    'maotp',
    'token',
    'accesstoken',
    'refreshtoken',
    'captchatoken',
    'fcmtoken',
  };

  static const _phoneKeys = {
    'sdt',
    'sodienthoai',
    'phone',
    'phonenumber',
    'sdtdangnhap',
  };

  static const _identifierKeys = {
    'cccd',
    'socccd',
    'cmnd',
    'identifier',
    'mathe',
    'mabhyt',
    'mabn',
    'maso',
    'mahs',
    'mabhyt_hoac_mabn',
    'mabythoacmabn',
  };

  /// Đệ quy làm sạch Map/List JSON data
  static dynamic sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in data.entries) {
        final keyStr = entry.key.toString();
        final lowerKey = keyStr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

        if (_sensitiveExactKeys.contains(lowerKey)) {
          sanitized[keyStr] = '[REDACTED]';
        } else if (_phoneKeys.contains(lowerKey)) {
          sanitized[keyStr] = maskPhone(entry.value);
        } else if (_identifierKeys.contains(lowerKey)) {
          sanitized[keyStr] = maskIdentifier(entry.value);
        } else {
          sanitized[keyStr] = sanitizeData(entry.value);
        }
      }
      return sanitized;
    }

    if (data is List) {
      return data.map((item) => sanitizeData(item)).toList();
    }

    return data;
  }

  /// Tóm tắt các phản hồi có dung lượng lớn (như /api/DatLichKham/ListMaster)
  static String summarizeResponse(String path, int? statusCode, dynamic data) {
    final lowerPath = path.toLowerCase();

    // 1. Tóm tắt ListMaster
    if (lowerPath.contains('listmaster')) {
      int tinhCount = 0;
      int phuongCount = 0;
      int gioCount = 0;
      int ngayCount = 0;
      int errorCode = 0;

      if (data is Map) {
        final rawData = data['Data'] ?? data['data'] ?? data;
        errorCode = (data['ErrorCode'] ?? data['errorCode'] ?? 0) as int;
        if (rawData is Map) {
          final listTinh = rawData['ListTinh'] ?? rawData['listTinh'];
          if (listTinh is List) tinhCount = listTinh.length;

          final dicPhuong = rawData['DicPhuong'] ?? rawData['dicPhuong'];
          if (dicPhuong is Map) phuongCount = dicPhuong.length;

          final listGio = rawData['ListGioKham'] ?? rawData['listGioKham'];
          if (listGio is List) gioCount = listGio.length;

          final listNgay = rawData['ListNgayKham'] ?? rawData['listNgayKham'];
          if (listNgay is List) ngayCount = listNgay.length;
        }
      }
      return 'ListMaster: nhận OK, $tinhCount tỉnh, $phuongCount nhóm phường, $gioCount khung giờ, $ngayCount ngày khám (ErrorCode=$errorCode)';
    }

    // 2. Tóm tắt ListHoSo hoặc ListSoKham
    if (lowerPath.contains('listhoso') || lowerPath.contains('listsokham')) {
      if (data is Map) {
        final list = data['Data'] ?? data['data'];
        if (list is List) {
          return '${path.split('/').last}: nhận OK, ${list.length} mục';
        }
      } else if (data is List) {
        return '${path.split('/').last}: nhận OK, ${data.length} mục';
      }
    }

    // 3. Tóm tắt các phản hồi Auth (Login, RefreshToken)
    if (lowerPath.contains('/api/token/')) {
      final sanitized = sanitizeData(data);
      return 'AuthResponse: Status $statusCode -> $sanitized';
    }

    // 4. Các phản hồi khác: Làm sạch & giới hạn độ dài hiển thị tối đa 500 ký tự
    final sanitized = sanitizeData(data);
    final str = sanitized.toString();
    if (str.length > 500) {
      return '${str.substring(0, 500)}... [đã cắt ngắn, tổng độ dài: ${str.length} ký tự]';
    }
    return str;
  }

  /// Định dạng an toàn cho Request data
  static String formatRequestData(dynamic data) {
    if (data == null) return 'null';
    final sanitized = sanitizeData(data);
    final str = sanitized.toString();
    if (str.length > 500) {
      return '${str.substring(0, 500)}... [đã cắt ngắn, tổng độ dài: ${str.length} ký tự]';
    }
    return str;
  }
}
