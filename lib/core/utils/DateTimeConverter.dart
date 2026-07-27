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
}
