import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service quản lý cấu hình từ xa qua Firebase Remote Config.
/// - Đảm bảo luôn có bộ mặc định cứng (hardcoded safe defaults).
/// - Không bao giờ crash hay chặn người dùng khi mất mạng hoặc lỗi Firebase.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  // Mặc định cứng an toàn trong app
  static const int defaultSoPhutKhoaCaKham = 16;
  static const String defaultMinSupportedVersion = '1.0.0';
  static const String defaultForceUpdateMessage =
      'Vui lòng cập nhật phiên bản mới nhất để tiếp tục sử dụng ứng dụng.';
  static const String defaultStoreUrlAndroid = '';
  static const String defaultStoreUrlIos = '';

  int _soPhutKhoaCaKham = defaultSoPhutKhoaCaKham;
  String _minSupportedVersion = defaultMinSupportedVersion;
  String _forceUpdateMessage = defaultForceUpdateMessage;
  String _storeUrlAndroid = defaultStoreUrlAndroid;
  String _storeUrlIos = defaultStoreUrlIos;

  int get soPhutKhoaCaKham => _soPhutKhoaCaKham;
  String get minSupportedVersion => _minSupportedVersion;
  String get forceUpdateMessage => _forceUpdateMessage;
  String get storeUrlAndroid => _storeUrlAndroid;
  String get storeUrlIos => _storeUrlIos;
  String get storeUrl => (!kIsWeb && Platform.isIOS) ? _storeUrlIos : _storeUrlAndroid;

  Future<void> initialize() async {
    if (kIsWeb) {
      // Môi trường Web sử dụng mặc định an toàn
      return;
    }

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );

      // Cài đặt bộ mặc định cứng
      await remoteConfig.setDefaults(const {
        'so_phut_khoa_ca_kham': defaultSoPhutKhoaCaKham,
        'min_supported_version': defaultMinSupportedVersion,
        'force_update_message': defaultForceUpdateMessage,
        'store_url_android': defaultStoreUrlAndroid,
        'store_url_ios': defaultStoreUrlIos,
      });

      // Lấy cấu hình từ Firebase (nếu mất mạng sẽ dùng defaults trên)
      await remoteConfig.fetchAndActivate();

      final fetchedMinutes = remoteConfig.getInt('so_phut_khoa_ca_kham');
      if (fetchedMinutes > 0 && fetchedMinutes <= 120) {
        _soPhutKhoaCaKham = fetchedMinutes;
      }

      final fetchedMinVer = remoteConfig.getString('min_supported_version').trim();
      if (fetchedMinVer.isNotEmpty) {
        _minSupportedVersion = fetchedMinVer;
      }

      final fetchedMsg = remoteConfig.getString('force_update_message').trim();
      if (fetchedMsg.isNotEmpty) {
        _forceUpdateMessage = fetchedMsg;
      }

      _storeUrlAndroid = remoteConfig.getString('store_url_android').trim();
      _storeUrlIos = remoteConfig.getString('store_url_ios').trim();
    } catch (e) {
      // Khi có lỗi mạng hoặc Firebase, dùng nguyên vẹn giá trị mặc định cứng
      debugPrint('[RemoteConfig] Không thể tải cấu hình từ xa (sử dụng mặc định an toàn): $e');
    }
  }
}
