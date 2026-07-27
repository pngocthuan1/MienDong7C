import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiValidator.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/features/auth/data/models/AuthResponseModel.dart';
import 'package:benhvien7c/features/auth/data/models/LoginHisRequestModel.dart';
import 'package:benhvien7c/features/auth/data/models/LoginRequestModel.dart';
import 'package:benhvien7c/features/auth/data/models/UserProfileModel.dart';
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  // Gọi API của máy chủ lấy token
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/Token/Login',
        data: request.toJson(),
      );

      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            AuthResponseModel.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }

    // Lưu ý: BusinessException ném ra từ ApiValidator sẽ tự bay lên,
    // không cần catch riêng vì nó đã là ApiException hợp lệ.
  }

  /// Gọi API login HIS để lấy thông tin hồ sơ bác sĩ/nhân viên
  Future<UserProfileModel> loginHis(LoginHisRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/DangNhapHis/LoginHis',
        data: request.toJson(),
      );

      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            UserProfileModel.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }
}
