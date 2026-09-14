import 'dart:io';

import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresRefreshTokenKey = 'expires_refresh_token';
  static const String _deviceIdKey = 'device_id';
  static const String _biometricPhoneKey = 'biometric_phone';
  static const String _biometricPasswordKey = 'biometric_password';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedPhoneKey = 'saved_phone';
  static const String _savedFullNameKey = 'saved_full_name';
  static const String _savedRoleKey = 'saved_role';

  // ==================== PII (Thông tin cá nhân bảo mật) ====================

  Future<void> saveSavedPhone(String phone) async {
    await _storage.write(key: _savedPhoneKey, value: phone);
  }

  Future<String?> getSavedPhone() async {
    try {
      return await _storage.read(key: _savedPhoneKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSavedFullName(String fullName) async {
    await _storage.write(key: _savedFullNameKey, value: fullName);
  }

  Future<String?> getSavedFullName() async {
    try {
      return await _storage.read(key: _savedFullNameKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSavedRole(String role) async {
    await _storage.write(key: _savedRoleKey, value: role);
  }

  Future<String?> getSavedRole() async {
    try {
      return await _storage.read(key: _savedRoleKey);
    } catch (_) {
      return null;
    }
  }

  static const String _fullNamePhonePrefix = 'full_name_';

  Future<void> saveFullNameForPhone(String phone, String fullName) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isNotEmpty) {
      await _storage.write(key: '$_fullNamePhonePrefix$clean', value: fullName);
    }
  }

  Future<String?> getFullNameForPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return null;
    try {
      return await _storage.read(key: '$_fullNamePhonePrefix$clean');
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFullNameForPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isNotEmpty) {
      await _storage.delete(key: '$_fullNamePhonePrefix$clean');
    }
  }

  Future<void> clearSavedPii() async {
    await Future.wait([
      _storage.delete(key: _savedPhoneKey),
      _storage.delete(key: _savedFullNameKey),
      _storage.delete(key: _savedRoleKey),
    ]);
  }

  /// Tự động di chuyển dữ liệu cá nhân (SĐT, Họ tên, Role, tên gắn với SĐT) từ SharedPreferences cũ
  /// sang FlutterSecureStorage mã hóa an toàn, sau đó xóa key cũ ở SharedPreferences.
  Future<void> migratePiiFromPreferences(SharedPreferences prefs) async {
    try {
      final existingSecurePhone = await getSavedPhone();
      final oldPhone = prefs.getString('saved_phone');
      if ((existingSecurePhone == null || existingSecurePhone.isEmpty) && oldPhone != null && oldPhone.isNotEmpty) {
        await saveSavedPhone(oldPhone);
        await prefs.remove('saved_phone');
      }

      final existingSecureName = await getSavedFullName();
      final oldName = prefs.getString('saved_full_name');
      if ((existingSecureName == null || existingSecureName.isEmpty) && oldName != null && oldName.isNotEmpty) {
        await saveSavedFullName(oldName);
        await prefs.remove('saved_full_name');
      }

      final existingSecureRole = await getSavedRole();
      final oldRole = prefs.getString('saved_role');
      if ((existingSecureRole == null || existingSecureRole.isEmpty) && oldRole != null && oldRole.isNotEmpty) {
        await saveSavedRole(oldRole);
        await prefs.remove('saved_role');
      }

      // Di chuyển các key full_name_<cleanPhone> sang SecureStorage
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_fullNamePhonePrefix)) {
          final phone = key.replaceFirst(_fullNamePhonePrefix, '');
          final val = prefs.getString(key);
          if (val != null && val.isNotEmpty) {
            final existing = await getFullNameForPhone(phone);
            if (existing == null || existing.isEmpty) {
              await saveFullNameForPhone(phone, val);
            }
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SecureStorageService] migratePiiFromPreferences error: $e');
      }
    }
  }

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
      _storage.delete(key: _savedPhoneKey),
      _storage.delete(key: _savedFullNameKey),
      _storage.delete(key: _savedRoleKey),
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
    if (expires == null || expires.isEmpty) return false;

    try {
      final ticks = int.tryParse(expires);
      if (ticks == null) {
        final parsedIso = DateTime.tryParse(expires);
        if (parsedIso == null) return false;
        return DateTime.now().isAfter(parsedIso);
      }

      DateTime expiryDate;
      if (ticks > 600000000000000000) {
        expiryDate = DateTimeConverter.fromTicks(ticks);
      } else if (ticks > 100000000000) {
        expiryDate = DateTime.fromMillisecondsSinceEpoch(ticks, isUtc: true).toLocal();
      } else {
        expiryDate = DateTime.fromMillisecondsSinceEpoch(ticks * 1000, isUtc: true).toLocal();
      }

      return DateTime.now().isAfter(expiryDate);
    } catch (_) {
      return false;
    }
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

  // ==================== Biometric Credentials ====================

  Future<void> saveBiometricCredentials(String phone, String password) async {
    await Future.wait([
      _storage.write(key: _biometricPhoneKey, value: phone),
      _storage.write(key: _biometricPasswordKey, value: password),
    ]);
  }

  Future<(String?, String?)> getBiometricCredentials() async {
    final phone = await _storage.read(key: _biometricPhoneKey);
    final password = await _storage.read(key: _biometricPasswordKey);
    return (phone, password);
  }

  Future<void> clearBiometricCredentials() async {
    await Future.wait([
      _storage.delete(key: _biometricPhoneKey),
      _storage.delete(key: _biometricPasswordKey),
    ]);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }
}
