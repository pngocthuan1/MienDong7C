import 'dart:io';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý thời gian đồng bộ với server (qua HTTP Date Header).
class TimeService {
  static Duration _serverOffset = Duration.zero;
  static bool _hasSynced = false;

  /// Đã đồng bộ với server hay chưa
  static bool get hasSynced => _hasSynced;

  /// Độ lệch giữa server và client
  static Duration get serverOffset => _serverOffset;

  /// Cập nhật thời gian server từ header "Date" của HTTP response (RFC 1123, e.g. "Fri, 02 Oct 2026 02:00:00 GMT")
  static void updateFromDateHeader(String? dateHeader) {
    if (dateHeader == null || dateHeader.trim().isEmpty) return;
    try {
      final serverUtc = HttpDate.parse(dateHeader.trim());
      final localNow = DateTime.now();
      _serverOffset = serverUtc.toLocal().difference(localNow);
      _hasSynced = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TimeService] Không thể parse Date header "$dateHeader": $e');
      }
    }
  }

  /// Cập nhật thời gian server trực tiếp từ DateTime
  static void updateServerTime(DateTime serverTime) {
    _serverOffset = serverTime.toLocal().difference(DateTime.now());
    _hasSynced = true;
  }

  /// Reset độ lệch về 0
  static void reset() {
    _serverOffset = Duration.zero;
    _hasSynced = false;
  }

  /// Trả về thời gian hiện tại chuẩn theo server
  static DateTime now() {
    return DateTime.now().add(_serverOffset);
  }
}
