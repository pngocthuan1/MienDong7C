/// Chuyển đổi giữa C# Ticks (dùng bởi backend .NET) và DateTime của Dart.
class DateTimeConverter {
  static const int _epochTicks = 621355968000000000;

  /// Đổi C# Ticks (100-nanoseconds kể từ 01/01/0001 UTC) thành DateTime (Local)
  static DateTime fromTicks(int ticks) {
    final ticksSinceEpoch = ticks - _epochTicks;
    final microseconds = ticksSinceEpoch ~/ 10;
    return DateTime.fromMicrosecondsSinceEpoch(
      microseconds,
      isUtc: true,
    ).toLocal();
  }

  /// Kiểm tra xem C# Ticks đã hết hạn chưa so với thời gian hiện tại
  static bool isExpired(int ticks) {
    try {
      final expiryTime = fromTicks(ticks);
      return DateTime.now().isAfter(expiryTime);
    } catch (_) {
      return true;
    }
  }

  /// Chuyển đổi chuỗi ngày bất kỳ (ISO, C# DateTime, dd/MM/yyyy) sang định dạng dd/MM/yyyy của Việt Nam.
  /// Trả về null nếu không thể parse hoặc giá trị rỗng / "null".
  static String? toVnDate(dynamic date) {
    if (date == null) return null;
    final str = date.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;

    // Nếu đã là định dạng dd/MM/yyyy chuẩn
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(str)) {
      return str;
    }

    // Nếu chứa dấu gạch chéo / (ví dụ d/M/yyyy hoặc dd/MM/yyyy HH:mm:ss)
    if (str.contains('/')) {
      final parts = str.split('/');
      if (parts.length >= 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final yearPart = parts[2].split(' ')[0].split('T')[0];
        final y = int.tryParse(yearPart);
        if (d != null && m != null && y != null && y > 1000) {
          return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
        }
      }
    }

    // Parse ISO hoặc standard DateTime string (yyyy-MM-dd, yyyy-MM-ddTHH:mm:ss...)
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year.toString().padLeft(4, '0')}';
    }

    return null;
  }
}
