import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseTokenService {
  FirebaseTokenService._();
  static final FirebaseTokenService instance = FirebaseTokenService._();

  String? _fcmToken;
  String? _deviceInfoString;

  String get fcmToken => _fcmToken ?? 'fcm_token_local_dev';
  String get deviceInfoString => _deviceInfoString ?? 'Xiaomi Device (Android)';

  void loadCachedToken(SharedPreferences prefs) {
    final cached = prefs.getString('saved_firebase_token');
    if (cached != null && cached.isNotEmpty) {
      _fcmToken = cached;
    }
  }

  Future<void> initialize({
    String? predefinedDeviceInfo,
    SharedPreferences? prefs,
  }) async {
    try {
      // 1. Tự động lấy thông tin thiết bị thực tế (nếu chưa truyền từ main)
      if (predefinedDeviceInfo != null && predefinedDeviceInfo.isNotEmpty) {
        _deviceInfoString = predefinedDeviceInfo;
      } else {
        await _fetchDeviceInfo();
      }

      // Nạp ngay token đã lưu từ SharedPreferences (nếu có) để có giá trị tức thì
      if (prefs != null) {
        loadCachedToken(prefs);
      }

      if (kIsWeb) {
        _fcmToken ??= 'fcm_token_web_dev';
        return;
      }

      // 2. Khởi tạo Firebase dựa trên file google-services.json & GoogleService-Info.plist
      await Firebase.initializeApp();

      // 3. Xin quyền hiển thị Thông Báo Đẩy từ người dùng (chạy nền, không chặn giao diện)
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Lấy Firebase Token thực tế cấp bởi Google
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
      }
      if (kDebugMode) {
        print('🔥 [FirebaseTokenService] Token thực tế: $_fcmToken');
        print('📱 [FirebaseTokenService] Thiết bị: $_deviceInfoString');
      }

      // Lưu Token vào bộ nhớ tạm SharedPreferences
      if (_fcmToken != null) {
        final p = prefs ?? await SharedPreferences.getInstance();
        await p.setString('saved_firebase_token', _fcmToken!);
      }

      // Lắng nghe nếu Token thay đổi tự động
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        final p = prefs ?? await SharedPreferences.getInstance();
        await p.setString('saved_firebase_token', newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FirebaseTokenService] Khởi tạo Firebase: $e');
      }
    }
  }

  Future<void> _fetchDeviceInfo() async {
    try {
      if (kIsWeb) {
        _deviceInfoString = 'Flutter Web App (Chrome)';
        return;
      }
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceInfoString = '${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfoString = '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      } else {
        _deviceInfoString = 'Flutter Web App';
      }
    } catch (_) {
      _deviceInfoString = 'Mobile Device';
    }
  }

  /// Hàm dựng sẵn Payload JSON API chuẩn 100% theo mẫu của Backend
  Map<String, dynamic> buildNotificationRequestPayload({
    required String userId,
    String? fromDateStr,
    String? toDateStr,
    int countLocal = 10,
  }) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return {
      "tenDangNhapHis": userId,
      "tuNgay": fromDateStr ?? todayStr,
      "denNgay": toDateStr ?? todayStr,
      "countLocalNewThongBao": countLocal,
      "deviceInfo": deviceInfoString,
      "firebaseToken": fcmToken,
      "userId": userId,
    };
  }
}
