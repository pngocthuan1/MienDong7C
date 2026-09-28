import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResponseDto.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:dio/dio.dart';

class DatLichKhamRemoteDataSource {
  final DioClient _dioClient;

  DatLichKhamRemoteDataSource(this._dioClient);

  Future<List<DkkHoSoBenhNhanDto>> getListHoSo(String maHS) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/DatLichKham/ListHoSo',
        queryParameters: {'maHS': maHS},
      );
      return _extractListData<DkkHoSoBenhNhanDto>(
        response.data,
        (json) => DkkHoSoBenhNhanDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<DkkThongTinKhamListMasterDto> getListNgayGioKham() async {
    try {
      final response = await _dioClient.dio.get('/api/DatLichKham/ListNgayGioKham');
      final data = _extractData(response.data);
      if (data is Map<String, dynamic>) {
        return DkkThongTinKhamListMasterDto.fromJson(data);
      }
      throw ApiException.validation('Dữ liệu ngày giờ khám không hợp lệ');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> dangKyKham(DangKyKhamRequestDto request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/DatLichKham/DangKy',
        data: request.toJson(),
      );
      final data = _extractData(response.data);
      if (data is num) {
        return data.toInt();
      }
      if (data is String) {
        return int.tryParse(data) ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

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
      throw ApiException.validation('Không tìm thấy phiếu sổ khám');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

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

  // ---------------------------------------------------------------------------
  // Tìm bệnh nhân theo CCCD / Hộ chiếu (Luồng 1)
  // ---------------------------------------------------------------------------
  // TODO(endpoint): Thay [TBD_ENDPOINT] bằng tên path thực tế khi có API.
  // Ví dụ: '/api/DatLichKham/TimBenhNhan'
  // Tham số: soCcHc (String) — số CCCD (12 ký tự) hoặc Hộ chiếu (8 ký tự)
  //
  // Trả về:
  //   DkkTimBenhNhanResponseDto  — nếu tìm thấy
  //   null                        — nếu không tìm thấy (server 404 hoặc data rỗng)
  //   throw ApiException          — nếu lỗi mạng / server 5xx
  // ---------------------------------------------------------------------------
  Future<DkkTimBenhNhanResponseDto?> timBenhNhanByCccdHc(String soCcHc) async {
    // TODO(endpoint): BỎ COMMENT NÀY VÀ ĐIỀN ENDPOINT KHI CÓ API THẬT.
    // Ví dụ implement thực tế:
    //
    // try {
    //   final response = await _dioClient.dio.get(
    //     '/api/DatLichKham/TimBenhNhan',          // <-- thay đổi tên path
    //     queryParameters: {'soCcHc': soCcHc},     // <-- thay đổi tên param
    //   );
    //   final data = _extractData(response.data);
    //   if (data == null) return null;
    //   if (data is Map<String, dynamic>) {
    //     return DkkTimBenhNhanResponseDto.fromJson(data);
    //   }
    //   return null;
    // } on BusinessException catch (e) {
    //   if (e.errorCode == 'NOT_FOUND' || e.message.contains('không tìm thấy')) return null;
    //   rethrow;
    // } on DioException catch (e) {
    //   if (e.response?.statusCode == 404) return null;
    //   throw ApiException.fromDioError(e);
    // }

    // --- MOCK PLACEHOLDER: giả lập chưa có API ---
    // Luôn trả về null (chưa tìm thấy) để luồng không bị block.
    // Thay bằng code thật ở trên khi có endpoint.
    await Future.delayed(const Duration(milliseconds: 800)); // Giả lập network delay
    return null;
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
