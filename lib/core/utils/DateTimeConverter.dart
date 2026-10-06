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

    // Tự động bóc tách ngày dd/MM/yyyy kể cả khi có tiền tố như "Thứ 2, 05/10/2026"
    final slashMatch = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(str);
    if (slashMatch != null) {
      final d = int.tryParse(slashMatch.group(1)!);
      final m = int.tryParse(slashMatch.group(2)!);
      final y = int.tryParse(slashMatch.group(3)!);
      if (d != null && m != null && y != null && y > 1000) {
        return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
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
  /// Chuẩn hóa phân cách ngày và giờ bằng dấu " • "
  static String formatScheduleForDisplay(String rawSchedule) {
    final clean = rawSchedule.trim();
    if (clean.isEmpty || clean == '--') return '--';

    if (clean.contains(' • ')) return clean;
    if (clean.contains('•')) {
      final p = clean.split('•');
      return '${p[0].trim()} • ${p[1].trim()}';
    }

    // Tách theo chữ 'T' nếu là ISO: 2026-10-05T10:30:00
    if (clean.contains('T')) {
      final parts = clean.split('T');
      final datePart = toVnDate(parts[0]);
      if (datePart != null && parts.length > 1) {
        final tUnits = parts[1].split(':');
        if (tUnits.length >= 2) {
          final timePart = '${tUnits[0].padLeft(2, '0')}:${tUnits[1].padLeft(2, '0')}';
          return '$datePart • $timePart';
        }
      }
    }

    // Bóc tách ngày dd/MM/yyyy và phần giờ (kể cả khi chuỗi có tiền tố "Thứ 2, 05/10/2026 18:30-19:00")
    final slashMatch = RegExp(r'(\d{1,2}/\d{1,2}/\d{4})').firstMatch(clean);
    if (slashMatch != null) {
      final datePart = toVnDate(slashMatch.group(1)!);
      final afterDate = clean.substring(slashMatch.end).trim();
      final beforeDate = clean.substring(0, slashMatch.start).trim();
      final timeCandidate = afterDate.isNotEmpty ? afterDate : beforeDate;
      if (timeCandidate.isNotEmpty && RegExp(r'\d').hasMatch(timeCandidate)) {
        final cleanTime = timeCandidate.replaceAll(RegExp(r'^[•\-\s,]+|[•\-\s,]+$'), '');
        final timePart = formatGioKhamForDisplay(cleanTime);
        if (timePart.isNotEmpty && datePart != null) {
          return '$datePart • $timePart';
        }
      }
      if (datePart != null) return datePart;
    }

    final dateOnly = toVnDate(clean);
    if (dateOnly != null) return dateOnly;

    return clean;
  }

  /// Ghép ngày khám và giờ khám theo định dạng thống nhất toàn app: "dd/MM/yyyy • `giờ`"
  /// Dùng dấu "•" (bullet point) làm phân cách giữa ngày và giờ, có khoảng trắng 2 bên.
  /// Ví dụ:
  /// - "05/10/2026 • 10:30" (khi chỉ có giờ bắt đầu)
  /// - "05/10/2026 • 09:30 - 10:00" (khi có khoảng giờ đầy đủ)
  /// - Nếu chỉ có ngày: "05/10/2026"
  /// - Nếu chỉ có giờ: "10:30"
  /// - Nếu cả hai rỗng: fallback sang rawSchedule hoặc "--"
  static String formatNgayGioKhamBullet({
    String? ngayKham,
    String? gioKham,
    String? rawSchedule,
  }) {
    String cleanNgay = (ngayKham != null && ngayKham.trim().isNotEmpty && ngayKham.trim() != '--')
        ? (toVnDate(ngayKham.trim()) ?? ngayKham.trim())
        : '';
    String cleanGio = (gioKham != null && gioKham.trim().isNotEmpty && gioKham.trim() != '--' && gioKham.trim().toLowerCase() != 'null')
        ? formatGioKhamForDisplay(gioKham.trim())
        : '';

    // Nếu thiếu ngày hoặc giờ, thử bóc tách từ rawSchedule
    if ((cleanNgay.isEmpty || cleanGio.isEmpty) && rawSchedule != null && rawSchedule.trim().isNotEmpty && rawSchedule.trim() != '--') {
      final parsed = formatScheduleForDisplay(rawSchedule.trim());
      if (parsed != '--') {
        if (parsed.contains(' • ')) {
          final p = parsed.split(' • ');
          if (cleanNgay.isEmpty && p.isNotEmpty) cleanNgay = p[0].trim();
          if (cleanGio.isEmpty && p.length > 1) cleanGio = p[1].trim();
        } else if (cleanNgay.isEmpty) {
          cleanNgay = parsed;
        }
      }
    }

    if (cleanNgay.isNotEmpty && cleanGio.isNotEmpty) {
      return '$cleanNgay • $cleanGio';
    } else if (cleanNgay.isNotEmpty) {
      return cleanNgay;
    } else if (cleanGio.isNotEmpty) {
      return cleanGio;
    }
    return '--';
  }

  /// Trích xuất giờ và phút kết thúc của ca khám từ [selectedTime] hoặc [scheduleText].
  /// - Trả về `({int hour, int minute})` kết thúc của ca khám.
  /// - Nếu là khoảng giờ dạng "14:30 - 15:00" hoặc "14g30 - 15g00": lấy mốc kết thúc (15:00).
  /// - Nếu chỉ có 1 mốc giờ (ví dụ "14:30" hoặc "14g30"): tự động cộng thêm 30 phút thành 15:00.
  /// - Trả về null nếu không tìm thấy thông tin giờ hợp lệ.
  static ({int hour, int minute})? extractTicketEndTime({
    String? selectedTime,
    String? scheduleText,
  }) {
    String rawTime = '';

    if (selectedTime != null &&
        selectedTime.trim().isNotEmpty &&
        selectedTime.trim() != '--' &&
        selectedTime.trim().toLowerCase() != 'null') {
      rawTime = selectedTime.trim();
    } else if (scheduleText != null &&
        scheduleText.trim().isNotEmpty &&
        scheduleText.trim() != '--') {
      final clean = scheduleText.trim();
      if (clean.contains('•')) {
        final p = clean.split('•');
        if (p.length > 1) {
          rawTime = p[1].trim();
        }
      } else if (clean.contains('T')) {
        final p = clean.split('T');
        if (p.length > 1) {
          rawTime = p[1].trim();
        }
      } else if (clean.contains(' ')) {
        final parts = clean.split(RegExp(r'\s+'));
        final timeIdx = parts.indexWhere((p) =>
            p.contains(':') ||
            p.toLowerCase().contains('g') ||
            p.toLowerCase().contains('h'));
        if (timeIdx != -1) {
          rawTime = parts.sublist(timeIdx).join(' ').trim();
        }
      }
    }

    if (rawTime.isEmpty) return null;

    // Chuẩn hóa nếu có dấu '-' (khoảng giờ khám)
    if (rawTime.contains('-')) {
      final parts = rawTime.split('-');
      if (parts.length >= 2) {
        final endPart = parts.last.trim();
        final parsedEnd = _parseHourMinute(endPart);
        if (parsedEnd != null) return parsedEnd;
      }
    }

    // Nếu không có dấu '-' hoặc không parse được phần sau, parse phần đầu rồi cộng 30 phút
    final startPart = rawTime.contains('-') ? rawTime.split('-').first.trim() : rawTime;
    final parsedStart = _parseHourMinute(startPart);
    if (parsedStart != null) {
      int totalMinutes = parsedStart.hour * 60 + parsedStart.minute + 30;
      int endHour = totalMinutes ~/ 60;
      int endMin = totalMinutes % 60;
      if (endHour >= 24) {
        endHour = 23;
        endMin = 59;
      }
      return (hour: endHour, minute: endMin);
    }

    return null;
  }

  static ({int hour, int minute})? _parseHourMinute(String raw) {
    if (raw.isEmpty) return null;
    final clean = raw.toLowerCase().replaceAll('g', ':').replaceAll('h', ':').trim();
    final parts = clean.split(':');
    if (parts.isNotEmpty) {
      final hour = int.tryParse(parts[0].trim());
      if (hour == null || hour < 0 || hour > 23) return null;
      int minute = 0;
      if (parts.length >= 2) {
        final minStr = parts[1].trim();
        final firstPart = minStr.split('.').first;
        minute = int.tryParse(firstPart) ?? 0;
        if (minute < 0 || minute > 59) minute = 0;
      }
      return (hour: hour, minute: minute);
    }
    return null;
  }

  /// Kiểm tra xem một phiếu khám đã diễn ra xong (ĐÃ QUA) hay chưa dựa vào GIỜ KẾT THÚC của ca khám.
  /// - [now]: Thời điểm so sánh (mặc định DateTime.now()).
  /// - Quy tắc phân loại:
  ///   + Ngày khám < hôm nay: ĐÃ QUA (true).
  ///   + Ngày khám > hôm nay: SẮP TỚI (false).
  ///   + Ngày khám == hôm nay:
  ///       So sánh `now` với GIỜ KẾT THÚC ca khám.
  ///       Nếu `now > giờ kết thúc`: ĐÃ QUA (true).
  ///       Nếu `now <= giờ kết thúc`: SẮP TỚI (false) (kể cả khi ca khám đang diễn ra).
  ///       Nếu không có thông tin giờ: mặc định sau 16:30 (hết giờ làm việc bệnh viện) mới coi là ĐÃ QUA.
  static bool isTicketPast({
    DateTime? ticketDate,
    String? selectedDate,
    String? selectedTime,
    String? scheduleText,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    DateTime? date = ticketDate;
    if (date == null) {
      if (selectedDate != null && selectedDate.trim().isNotEmpty) {
        date = _parseDateHelper(selectedDate);
      }
      date ??= _parseDateHelper(scheduleText);
    }

    if (date == null) {
      return false;
    }

    final tDateOnly = DateTime(date.year, date.month, date.day);

    if (tDateOnly.isBefore(today)) {
      return true;
    }

    if (tDateOnly.isAfter(today)) {
      return false;
    }

    // Ngày khám chính là hôm nay:
    final endTime = extractTicketEndTime(
      selectedTime: selectedTime,
      scheduleText: scheduleText,
    );

    if (endTime != null) {
      final ticketEndDateTime = DateTime(
        tDateOnly.year,
        tDateOnly.month,
        tDateOnly.day,
        endTime.hour,
        endTime.minute,
      );
      return current.isAfter(ticketEndDateTime);
    }

    // Nếu không có giờ cụ thể: sau 16:30 (hết giờ làm việc ngoại trú) mới là đã qua
    final defaultEndOfDay = DateTime(tDateOnly.year, tDateOnly.month, tDateOnly.day, 16, 30);
    return current.isAfter(defaultEndOfDay);
  }

  static DateTime? _parseDateHelper(dynamic raw) {
    if (raw == null) return null;
    final vnStr = toVnDate(raw);
    if (vnStr != null) {
      final parts = vnStr.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return null;
  }
}
