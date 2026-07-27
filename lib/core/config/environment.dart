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

  /// Gọi 1 lần duy nhất tại app_bootstrap.dart lúc khởi động app,
  /// dùng package_info_plus / device_info_plus để lấy giá trị thật.
  /// Có guard _initialized để tránh gọi lại nhiều lần làm sai lệch dữ liệu.

  static void init({
    required String appPackageName,
    required String appVersion,
    required String deviceId,
    required String platform,
  }) {
    if (_initialized) return;
    _appPackageName = appPackageName;
    _appVersion = appVersion;
    _deviceId = deviceId;
    _platform = platform;
    _initialized = true;
  }

  // ==================== Base URL theo môi trường ====================

  /// LƯU Ý: Hiện dự án chỉ có server test chạy local (https://localhost:7185).
  /// Chưa có server staging/production thật. Khi backend deploy lên server
  /// thật, chỉ cần điền domain vào 2 chỗ TODO bên dưới, không cần sửa gì
  /// ở DioClient hay bất kỳ nơi nào khác đang gọi Environment.baseUrl.
  static String get baseUrl {
    switch (current) {
      case AppEnv.production:
        // TODO: điền domain server production thật khi backend deploy xong
        // Ví dụ: return 'https://api.benhvien7c.com';
        return _localDevBaseUrl;
      case AppEnv.staging:
        // TODO: điền domain server staging thật khi backend deploy xong
        // Ví dụ: return 'https://staging-api.benhvien7c.com';
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
      // 10.0.2.2 là địa chỉ đặc biệt Android Emulator dùng để trỏ về máy host
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
}
