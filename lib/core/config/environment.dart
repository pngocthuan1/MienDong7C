import 'package:flutter/foundation.dart';

enum AppEnv { development, staging, production }

class Environment {
  Environment._();

  // =============== Môi trường =========================

  // Môi trường hiện tại, truyền vào lúc build:
  // flutter bulid apk --dart-define=ENV=production

  static const String _envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static AppEnv get current {
    switch (_envName) {
      case 'production':
        return AppEnv.production;
      case 'staging':
        return AppEnv.staging;
      default:
        return AppEnv.development;
    }
  }

  static bool get isDevelopment => current == AppEnv.development;
  static bool get isStaging => current == AppEnv.staging;
  static bool get isProduction => current == AppEnv.production;

  // ==================== Thông tin app (cập nhật động lúc khởi động) ==================== //

  static String _appPackageName = 'com.hospisoft.benhvien7c';
  static String _appVersion = '1.0.30';
  static String _deviceId = 'unknown_device';
  static String _platform = 'unknown';
  static bool _initialized = false;

  static String get appPackageName => _appPackageName;
  static String get appVersion => _appVersion;
  static String get deviceId => _deviceId;
  static String get platform {
    if (kIsWeb) return 'android';
    return _platform;
  }
  static bool _isPhysicalDevice = false;
  static bool get isPhysicalDevice => _isPhysicalDevice;

  static void init({
    required String appPackageName,
    required String appVersion,
    required String deviceId,
    required String platform,
    bool isPhysicalDevice = false,
  }) {
    if (_initialized) return;
    _appPackageName = appPackageName;
    _appVersion = appVersion;
    _deviceId = deviceId;
    _platform = platform;
    _isPhysicalDevice = isPhysicalDevice;
    _initialized = true;
  }

  // ==================== Base URL theo môi trường ====================

  static const String _customBaseUrl = String.fromEnvironment('BASE_URL');
  static String? _overriddenBaseUrl;

  static void setCustomBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _overriddenBaseUrl = null;
    } else {
      var clean = url.trim();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'https://$clean';
      }
      if (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      _overriddenBaseUrl = clean;
    }
  }

  static String get baseUrl {
    if (_overriddenBaseUrl != null && _overriddenBaseUrl!.isNotEmpty) {
      return _overriddenBaseUrl!;
    }
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    switch (current) {
      case AppEnv.production:
        return _localDevBaseUrl;
      case AppEnv.staging:
        return _localDevBaseUrl;
      case AppEnv.development:
        return _localDevBaseUrl;
    }
  }

  static String get _localDevBaseUrl {
    if (kIsWeb) {
      return 'https://localhost:7185';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_isPhysicalDevice) {
        // Điện thoại/máy tính bảng thật kết nối USB (sử dụng 127.0.0.1 qua adb reverse)
        return 'https://127.0.0.1:7185';
      }
      // Máy ảo Android Emulator dùng 10.0.2.2 để trỏ về máy host
      return 'https://10.0.2.2:7185';
    }
    // iOS Simulator, macOS, Windows... hoặc thiết bị thật cùng mạng LAN
    return 'https://localhost:7185';
  }

  // ==================== Cấu hình khác ====================

  /// Timeout mặc định cho mọi request Dio (connect/receive/send).
  /// DioClient nên dùng giá trị này thay vì hardcode, để chỉnh 1 nơi
  /// là áp dụng toàn app.
  static Duration get apiTimeout => const Duration(seconds: 20);

  // Cloudflare Turnstile Configuration
  static const String turnstileSiteKey = '0x4AAAAAADvG0YDfYPtUpuix';
  static const String turnstileSecretKey = '0x4AAAAAADvG0dUTX_o58eUFpR14_5NXTYw';

  // Đường dẫn Điều khoản dịch vụ & Chính sách bảo mật (Có thể gán link tùy chỉnh tại đây)
  static String termsOfServiceUrl = 'https://quandanymiendong.vn/dieu-khoan-su-dung';
  static String privacyPolicyUrl = 'https://quandanymiendong.vn/chinh-sach-bao-mat';
}
