import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/core/services/FirebaseTokenService.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationReadStatusEntity.dart';

/// Class gọi trực tiếp các API REST thật của Hệ thống Bệnh Viện 7C (/api/ThongBao & /api/Firebase)
class ThongBaoRemoteDataSource {
  final DioClient _dioClient;

  ThongBaoRemoteDataSource(this._dioClient);

  /// 1. POST /api/ThongBao/List - Lấy danh sách thông báo & Badge & ListDelete
  Future<Map<String, dynamic>> fetchNotificationList({
    required String hisUsername,
    String? fromDateStr,
    String? toDateStr,
    int countLocal = 0,
  }) async {
    final now = DateTime.now();
    final defaultToDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 23:59:59';
    // Lấy từ ngày 01 của tháng trước (tự động bao phủ trọn vẹn cả tháng 28, 29, 30 và 31 ngày)
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final defaultFromDate = '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}-01 00:00:00';

    final payload = {
      "tenDangNhapHis": hisUsername,
      "tuNgay": fromDateStr ?? defaultFromDate,
      "denNgay": toDateStr ?? defaultToDate,
      "countLocalNewThongBao": countLocal,
      "deviceInfo": FirebaseTokenService.instance.deviceInfoString,
      "firebaseToken": FirebaseTokenService.instance.fcmToken,
    };

    final response = await _dioClient.dio.post(
      '/api/ThongBao/List',
      data: payload,
    );

    final data = _unwrapApiResult(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  /// 2. POST /api/ThongBao/CountNew - Đếm số lượng thông báo chưa đọc
  Future<int> fetchUnreadCount(String hisUsername) async {
    final response = await _dioClient.dio.post(
      '/api/ThongBao/CountNew',
      data: {"tenDangNhapHis": hisUsername},
    );
    final data = _unwrapApiResult(response.data);
    return (data as num?)?.toInt() ?? 0;
  }

  /// 3. POST /api/ThongBao/MarkStatus - Đánh dấu đã đọc
  Future<bool> markNotificationStatus({
    required String username,
    required dynamic notificationId,
    int trangThai = 1,
    String schema = "hospi_2608",
  }) async {
    final payload = {
      "tenNguoiDung": username,
      "id_thongbao": notificationId,
      "trangThai": trangThai,
      "ngayNhan": DateTime.now().toIso8601String(),
      "schema": schema,
    };

    final response = await _dioClient.dio.post(
      '/api/ThongBao/MarkStatus',
      data: payload,
    );
    final res = _unwrapApiResult(response.data);
    if (res is Map && res.containsKey('IsOk')) {
      return res['IsOk'] == true;
    }
    return true;
  }

  /// 4. GET /api/ThongBao/ListMaster - Lấy danh mục Nơi nhận, Nơi gửi, Nhóm
  Future<Map<String, dynamic>> fetchListMaster() async {
    final response = await _dioClient.dio.get('/api/ThongBao/ListMaster');
    final data = _unwrapApiResult(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  /// 5. POST /api/ThongBao/Post - Đăng thông báo mới (Chuẩn ThongBaoNoiBoCreateInput C#)
  Future<Map<String, dynamic>> createNotification({
    required String title,
    required String content,
    required dynamic noiGuiId,
    required List<dynamic> noiNhanList,
    required String hisUserId,
    List<Map<String, dynamic>>? listFile,
  }) async {
    final int parsedNoiGui = (noiGuiId is int)
        ? noiGuiId
        : (int.tryParse(noiGuiId?.toString() ?? '') ?? 1);

    final payload = {
      "TieuDe": title.isNotEmpty ? title : "THÔNG BÁO NỘI BỘ",
      "NoiDung": content,
      "NoiGui": parsedNoiGui,
      "NoiNhan": noiNhanList,
      "HisUserId": hisUserId,
      "LinkCongVan": "",
      "ListFile": listFile ?? [],
    };

    if (kDebugMode) {
      print('🚀 Calling /api/ThongBao/Post with payload: $payload');
    }

    final response = await _dioClient.dio.post(
      '/api/ThongBao/Post',
      data: payload,
    );
    final data = _unwrapApiResult(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  /// Upload file đính kèm lên C# Server
  Future<String?> uploadFile(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'fileName': fileName,
      });

      final response = await _dioClient.dio.post('/api/File/Upload', data: formData);
      final data = _unwrapApiResult(response.data);
      if (data is Map<String, dynamic> && data.containsKey('fileUrl')) {
        return data['fileUrl']?.toString();
      } else if (data is String) {
        return data;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Upload file error: $e');
      }
    }
    return null;
  }

  /// 6. POST /api/ThongBao/ThuHoiThongBao - Thu hồi / Xóa thông báo
  Future<bool> thuHoiThongBao(String notificationId, {String schema = "hospi_2608"}) async {
    final response = await _dioClient.dio.post(
      '/api/ThongBao/ThuHoiThongBao',
      data: {
        "IdThongBao": notificationId,
        "Schema": schema,
      },
    );
    final res = _unwrapApiResult(response.data);
    return res == true;
  }

  /// 7. GET /api/ThongBao/CheckReadUser - Kiểm tra danh sách người dùng đã đọc
  Future<List<NotificationReadStatusEntity>> checkReadUser(String notificationId, {String? schema}) async {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final dynamicSchema = schema ?? 'hospi$mm$yy';

    try {
      final response = await _dioClient.dio.get(
        '/api/ThongBao/CheckReadUser',
        queryParameters: {
          "id": notificationId,
          "schema": dynamicSchema,
        },
      );
      final rawData = _unwrapApiResult(response.data);
      if (rawData is List) {
        return rawData.map((e) {
          final m = e as Map<String, dynamic>;
          final userId = m['UserId']?.toString() ?? m['userId']?.toString() ?? '';
          final userName = m['MaVaTen']?.toString() ?? m['Ten']?.toString() ?? m['ten']?.toString() ?? m['UserId']?.toString() ?? 'Nhân viên';
          final readDateStr = m['NgayNhan']?.toString() ?? m['ngayNhan']?.toString();
          final trangThaiVal = m['TrangThai'] as int? ?? m['trangThai'] as int? ?? 0;
          final isRead = trangThaiVal != 1 || (readDateStr != null && readDateStr.isNotEmpty);

          return NotificationReadStatusEntity(
            userId: userId,
            userName: userName,
            userRole: m['KhoaPhong']?.toString() ?? m['khoaPhong']?.toString() ?? 'Phòng ban',
            isRead: isRead,
            readAt: readDateStr != null ? DateTime.tryParse(readDateStr) : null,
          );
        }).toList();
      }
    } catch (_) {}

    if (schema == null || schema != 'hospi_${yy}${mm}') {
      try {
        final fallbackSchema = 'hospi_${yy}${mm}';
        final response = await _dioClient.dio.get(
          '/api/ThongBao/CheckReadUser',
          queryParameters: {
            "id": notificationId,
            "schema": fallbackSchema,
          },
        );
        final rawData = _unwrapApiResult(response.data);
        if (rawData is List) {
          return rawData.map((e) {
            final m = e as Map<String, dynamic>;
            final userId = m['UserId']?.toString() ?? m['userId']?.toString() ?? '';
            final userName = m['MaVaTen']?.toString() ?? m['Ten']?.toString() ?? m['ten']?.toString() ?? m['UserId']?.toString() ?? 'Nhân viên';
            final readDateStr = m['NgayNhan']?.toString() ?? m['ngayNhan']?.toString();
            final trangThaiVal = m['TrangThai'] as int? ?? m['trangThai'] as int? ?? 0;
            final isRead = trangThaiVal != 1 || (readDateStr != null && readDateStr.isNotEmpty);

            return NotificationReadStatusEntity(
              userId: userId,
              userName: userName,
              userRole: m['KhoaPhong']?.toString() ?? m['khoaPhong']?.toString() ?? 'Phòng ban',
              isRead: isRead,
              readAt: readDateStr != null ? DateTime.tryParse(readDateStr) : null,
            );
          }).toList();
        }
      } catch (_) {}
    }

    return [];
  }

  /// 8. POST /api/Firebase/Add - Đăng ký / Cập nhật FCM Token
  Future<bool> registerFirebaseToken({
    required String userId,
    required String fcmToken,
    required String deviceInfo,
    String platform = "Android",
    int badgeNumber = 0,
  }) async {
    final payload = {
      "UserId": userId,
      "DeviceInfo": deviceInfo,
      "FirebaseToken": fcmToken,
      "Platform": platform,
      "BadgeNumber": badgeNumber,
    };

    final response = await _dioClient.dio.post(
      '/api/Firebase/Add',
      data: payload,
    );
    final res = _unwrapApiResult(response.data);
    return res == true;
  }

  /// 9. POST /api/Firebase/Remove - Hủy đăng ký Token khi Đăng xuất
  Future<bool> removeFirebaseToken({
    required String userId,
    required String deviceInfo,
  }) async {
    final payload = {
      "UserId": userId,
      "DeviceInfo": deviceInfo,
    };

    final response = await _dioClient.dio.post(
      '/api/Firebase/Remove',
      data: payload,
    );
    final res = _unwrapApiResult(response.data);
    return res == true;
  }

  /// 10. POST /api/Firebase/SetBadge - Đồng bộ số Badge ngoài Icon App
  Future<bool> setFirebaseBadge({
    required String userId,
    required String fcmToken,
    required String deviceInfo,
    required int badgeNumber,
    String platform = "Android",
  }) async {
    final payload = {
      "UserId": userId,
      "DeviceInfo": deviceInfo,
      "FirebaseToken": fcmToken,
      "Platform": platform,
      "BadgeNumber": badgeNumber,
    };

    final response = await _dioClient.dio.post(
      '/api/Firebase/SetBadge',
      data: payload,
    );
    final res = _unwrapApiResult(response.data);
    return res == true;
  }

  /// Helper giải bọc kết quả ApiResultDto<T>
  dynamic _unwrapApiResult(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final errorCode = responseData['errorCode'] as int? ?? responseData['ErrorCode'] as int? ?? 0;
      if (errorCode != 0) {
        final msg = responseData['errorMessage'] as String? ?? responseData['ErrorMessage'] as String? ?? 'Thao tác không thành công (Mã lỗi $errorCode)';
        throw Exception(msg);
      }
      return responseData['data'] ?? responseData['Data'];
    }
    return responseData;
  }
}
