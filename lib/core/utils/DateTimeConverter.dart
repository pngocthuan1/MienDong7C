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

  /// Chuyển chuỗi ngày (dd/MM/yyyy hoặc chuỗi DateTime parseable) sang chuẩn ISO của server: "yyyy-MM-ddT00:00:00"
  static String? toServerIsoString(dynamic date) {
    if (date == null) return null;
    final clean = date.toString().trim();
    if (clean.isEmpty || clean.toLowerCase() == 'null') return null;

    // Nếu chứa dấu gạch chéo dd/MM/yyyy
    if (clean.contains('/')) {
      final parts = clean.split('/');
      if (parts.length >= 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final yearPart = parts[2].split(' ')[0].split('T')[0];
        final y = int.tryParse(yearPart);
        if (d != null && m != null && y != null) {
          return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}T00:00:00';
        }
      }
    }

    // Nếu đã là hoặc có thể parse sang DateTime ISO
    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}T00:00:00';
    }

    return null;
  }

  /// Chuyển đổi chuỗi ngày giờ bất kỳ sang định dạng dd/MM/yyyy HH:mm:ss hoặc dd/MM/yyyy HH:mm của Việt Nam.
  static String? toVnDateTime(dynamic date, {bool includeSeconds = true}) {
    if (date == null) return null;
    final str = date.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;

    // Chuẩn hóa T thành khoảng trắng
    final clean = str.replaceAll('T', ' ');

    // Nếu đã có ngày dd/MM/yyyy ở đầu: ví dụ "01/10/2026 06:00" hoặc "28/09/2026 12:33:05"
    if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(clean)) {
      final parts = clean.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0];
        final timePart = parts[1];
        final tUnits = timePart.split(':');
        if (tUnits.length >= 2) {
          final hh = tUnits[0].padLeft(2, '0');
          final mm = tUnits[1].padLeft(2, '0');
          if (includeSeconds && tUnits.length >= 3) {
            final ss = tUnits[2].split('.').first.padLeft(2, '0');
            return '$datePart $hh:$mm:$ss';
          }
          return '$datePart $hh:$mm';
        }
      }
      return clean;
    }

    // Thử parse bằng DateTime.tryParse (ISO, standard formats)
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      final dd = parsed.day.toString().padLeft(2, '0');
      final mm = parsed.month.toString().padLeft(2, '0');
      final yyyy = parsed.year.toString().padLeft(4, '0');
      final hh = parsed.hour.toString().padLeft(2, '0');
      final min = parsed.minute.toString().padLeft(2, '0');
      if (includeSeconds) {
        final ss = parsed.second.toString().padLeft(2, '0');
        return '$dd/$mm/$yyyy $hh:$min:$ss';
      }
      return '$dd/$mm/$yyyy $hh:$min';
    }

    // Thử tách phần ngày và phần giờ nếu có space
    if (clean.contains(' ')) {
      final parts = clean.split(' ');
      final datePart = toVnDate(parts[0]);
      if (datePart != null) {
        return '$datePart ${parts.sublist(1).join(' ')}';
      }
    }

    return toVnDate(str) ?? str;
  }

  /// Đổi định dạng hiển thị giờ khám trên UI từ Id "10:00-10:30" thành "10:00 - 10:30".
  /// Tách theo dấu '-' thành 2 phần và thêm khoảng trắng quanh dấu '-'.
  /// Không dùng regex, không phụ thuộc vào trường "Display" của server.
  /// Tuyệt đối KHÔNG dùng chuỗi này gửi lên server; chỉ dùng để hiển thị trên UI.
  static String formatGioKhamForDisplay(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    final parts = trimmed.split('-');
    if (parts.length >= 2) {
      final start = parts[0].trim();
      final end = parts[1].trim();
      if (start.isNotEmpty && end.isNotEmpty) {
        return '$start - $end';
      }
    }
    return trimmed;
  }

  /// Format chuỗi lịch khám "Thứ X, dd/MM/yyyy HH:mm" hoặc "dd/MM/yyyy 10:00 - 10:30" cho UI hiển thị đẹp
  static String formatScheduleForDisplay(String rawSchedule) {
    if (rawSchedule.trim().isEmpty) return rawSchedule;
    final formattedTime = formatGioKhamForDisplay(rawSchedule);
    return toVnDateTime(formattedTime, includeSeconds: false) ?? formattedTime;
  }
}
