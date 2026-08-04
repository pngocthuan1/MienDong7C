import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiValidator.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/features/auth/data/models/AuthResponseModel.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';
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

  // --- OTP & Account APIs ---

  Future<String> generateRandomKey() async {
    try {
      final response = await _dioClient.dio.get('/api/Otp/GenerateRandomKey');
      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) => data as String,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }

  Future<SendOtpResponseModel> sendOtp(OtpSendInputModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/Otp/SendOtp',
        data: request.toJson(),
      );
      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            SendOtpResponseModel.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }

  Future<int> verifyOtp(OtpVerifyInputModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/Otp/VerifyOtp',
        data: request.toJson(),
      );
      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) => (data as num).toInt(),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }

  Future<String> signUp(DkkSignUpRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/TaiKhoan/SignUp',
        data: request.toJson(),
      );
      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) => data as String,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }

  Future<String> resetPassword(DkkResetPasswordRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/TaiKhoan/ResetPassword',
        data: request.toJson(),
      );
      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) => data as String,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }

  Future<bool> changePassword(ChangePasswordRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/TaiKhoan/ChangePassword',
        data: request.toJson(),
      );
      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) => data as bool,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }

  Future<String> deleteAccount(DkkResetPasswordRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/TaiKhoan/DeleteAccount',
        data: request.toJson(),
      );
      return ApiValidator.validateResponse(
        json: response.data as Map<String, dynamic>,
        fromJsonT: (data) => data as String,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioError(e);
    }
  }
}
