import 'dart:io';

import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresRefreshTokenKey = 'expires_refresh_token';
  static const String _deviceIdKey = 'device_id';

  // ---------------------------------------------------------------------
  // Access Token
  // ---------------------------------------------------------------------

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  // ==================== Refresh Token ====================

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> saveExpiresRefreshToken(String expires) async {
    await _storage.write(key: _expiresRefreshTokenKey, value: expires);
  }

  Future<String?> getExpiresRefreshToken() async {
    try {
      return await _storage.read(key: _expiresRefreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteExpiresRefreshToken() async {
    await _storage.delete(key: _expiresRefreshTokenKey);
  }

  // ==================== Session ====================

  /// Xóa toàn bộ session (access/refresh token, thời hạn).
  /// Không xóa deviceId — deviceId là định danh vĩnh viễn của máy,
  /// phải giữ nguyên qua các lần đăng nhập/đăng xuất khác nhau.
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresRefreshTokenKey),
    ]);
  }

  /// Đọc cặp token dưới dạng Record: (String? accessToken, String? refreshToken)
  Future<(String?, String?)> getTokensRecord() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return (accessToken, refreshToken);
  }

  /// Lưu cặp token cùng lúc
  Future<void> saveTokensRecord(String accessToken, String refreshToken) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Kiểm tra xem Refresh Token có hết hạn hay chưa dựa trên Ticks lưu trữ.
  /// Nếu không đọc được thời hạn (chưa lưu, lỗi parse...), coi như đã hết hạn
  /// để bắt đăng nhập lại — an toàn hơn là mặc định "chưa hết hạn"

  Future<bool> isRefreshTokenExpired() async {
    final expires = await getExpiresRefreshToken();
    if (expires == null || expires.isEmpty) return true;

    final ticks = int.tryParse(expires);
    if (ticks == null) return true;
    return DateTimeConverter.isExpired(ticks);
  }

  // ==================== Device ID ====================

  // Lấy hoặc tự động sinh Device ID duy nhất vĩnh viễn cho máy
  Future<String> getOrCreateDeviceId() async {
    String? deviceId;
    try {
      deviceId = await _storage.read(key: _deviceIdKey);
    } catch (_) {
      deviceId = null;
    }

    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        deviceId = const Uuid().v4();
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id.isNotEmpty
            ? androidInfo.id
            : const Uuid().v4();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? const Uuid().v4();
      } else {
        deviceId = const Uuid().v4();
      }
    } catch (_) {
      // Bất kỳ lỗi nào xảy ra cũng sẽ tự động sinh UUID dự phòng
      deviceId = const Uuid().v4();
    }

    await _storage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }
}
