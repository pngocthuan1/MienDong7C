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
