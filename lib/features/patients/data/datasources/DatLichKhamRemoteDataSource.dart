import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResponseDto.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:dio/dio.dart';

class DatLichKhamRemoteDataSource {
  final DioClient _dioClient;

  DatLichKhamRemoteDataSource(this._dioClient);

  // API 1: Lấy danh mục Master (Phòng khám, Tỉnh, Phường, Ngày, Giờ)
  Future<DkkListMasterDto> getListMaster() async {
    try {
      final response = await _dioClient.dio.get('/api/DatLichKham/ListMaster');
      final data = _extractData(response.data);
      if (data is Map<String, dynamic>) {
        return DkkListMasterDto.fromJson(data);
      }
      throw ApiException.validation('Dữ liệu ListMaster không hợp lệ');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // API 2: Lấy danh sách hồ sơ bệnh nhân đã liên kết
  Future<List<DkkHoSoBenhNhanDto>> getListHoSo([String maHS = '']) async {
    try {
      final queryParams = maHS.isNotEmpty ? {'maHS': maHS} : null;
      final response = await _dioClient.dio.get(
        '/api/DatLichKham/ListHoSo',
        queryParameters: queryParams,
      );
      return _extractListData<DkkHoSoBenhNhanDto>(
        response.data,
        (json) => DkkHoSoBenhNhanDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // API 3: Tìm bệnh nhân theo CCCD / Hộ chiếu
  Future<DkkTimBenhNhanResponseDto?> timBenhNhanByCccdHc(String soCcHc) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/DatLichKham/TimBenhNhan',
        data: {'MaBhytHoacMaBn': soCcHc},
      );
      final data = _extractData(response.data);
      if (data == null) return null;
      if (data is Map<String, dynamic>) {
        return DkkTimBenhNhanResponseDto.fromJson(data);
      }
      return null;
    } on BusinessException catch (e) {
      // Server trả về lỗi "không tìm thấy" → coi như null
      if (e.message.toLowerCase().contains('không tìm thấy') ||
          e.message.toLowerCase().contains('not found') ||
          e.errorCode?.toString() == 'NOT_FOUND') {
        return null;
      }
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  // API 4: Kiểm tra sai lệch thông tin bệnh nhân
  Future<DkkKiemTraBenhNhanResponseDto?> kiemTraBenhNhan(DangKyKhamRequestDto request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/DatLichKham/KiemTraBenhNhan',
        data: request.toJson(),
      );
      final data = _extractData(response.data);
      if (data is Map<String, dynamic>) {
        return DkkKiemTraBenhNhanResponseDto.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // API 5: Đăng ký đặt lịch khám
  Future<int> dangKyKham(DangKyKhamRequestDto request) async {
    try {
      final jsonBody = request.toJson();
      if (kDebugMode) {
        debugPrint('➡️ [DatLichKham] Đăng ký khám: ${request.hoTen}, Ngày: ${request.ngayKham}, Giờ: ${request.gioKham}');
      }
      final response = await _dioClient.dio.post(
        '/api/DatLichKham/DangKy',
        data: jsonBody,
      );
      if (kDebugMode) {
        debugPrint('⬅️ [DatLichKham] Đăng ký phản hồi, Status: ${response.statusCode}');
      }
      final data = _extractData(response.data);
      if (data is num) return data.toInt();
      if (data is String) return int.tryParse(data) ?? 0;
      return 0;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DatLichKham] Lỗi đăng ký khám: Status ${e.response?.statusCode} - ${e.message}');
      }
      throw ApiException.fromDioError(e);
    }
  }

  // API 6: Lấy danh sách lịch đã đặt
  Future<List<DkkSoKhamDto>> getListSoKham() async {
    try {
      final response = await _dioClient.dio.get('/api/DatLichKham/ListSoKham');
      return _extractListData<DkkSoKhamDto>(
        response.data,
        (json) => DkkSoKhamDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // API 7: Xem chi tiết 1 phiếu
  Future<DkkSoKhamDto> getPhieuSoKham(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/DatLichKham/PhieuSoKham',
        queryParameters: {'id': id},
      );
      final data = _extractData(response.data);
      if (data is Map<String, dynamic>) {
        return DkkSoKhamDto.fromJson(data);
      }
      throw ApiException.validation('Không tìm thấy phiếu số khám');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // API 8: Hủy/Xóa phiếu đã đặt
  Future<bool> xoaSoKham(int id) async {
    try {
      final response = await _dioClient.dio.delete(
        '/api/DatLichKham/XoaSoKham',
        queryParameters: {'id': id},
      );
      final data = _extractData(response.data);
      if (data is bool) return data;
      return true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // API 9: Xóa liên kết hồ sơ bệnh nhân
  Future<bool> xoaHoSo(String maHs) async {
    try {
      final response = await _dioClient.dio.delete(
        '/api/DatLichKham/XoaHoSo',
        queryParameters: {'maHs': maHs},
      );
      final data = _extractData(response.data);
      if (data is bool) return data;
      return true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  dynamic _extractData(dynamic body) {
    if (body is Map<String, dynamic>) {
      final responseDto = ApiResponseDto<dynamic>.fromJson(body, (data) => data);
      if (!responseDto.isSuccess) {
        throw BusinessException(
          responseDto.displayMessage,
          errorCode: responseDto.errorCode,
        );
      }
      // NẾU server trả về ErrorMessage kèm theo (ngay cả khi ErrorCode == 0 do ShowErrors default)
      if (responseDto.errorMessage != null && responseDto.errorMessage!.trim().isNotEmpty) {
        if (responseDto.data == null || responseDto.data == 0 || responseDto.data == '0') {
          throw BusinessException(
            responseDto.errorMessage!.trim(),
            errorCode: responseDto.errorCode,
          );
        }
      }
      return responseDto.data;
    }
    return body;
  }

  List<T> _extractListData<T>(dynamic body, T Function(Map<String, dynamic>) mapper) {
    final rawData = _extractData(body);
    if (rawData is List) {
      return rawData.map((e) => mapper(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
