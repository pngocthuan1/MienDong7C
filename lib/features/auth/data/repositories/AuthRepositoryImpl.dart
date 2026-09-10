import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/features/auth/data/datasources/AuthRemoteDataSource.dart';
import 'package:benhvien7c/features/auth/data/models/LoginHisRequestModel.dart';
import 'package:benhvien7c/features/auth/data/models/LoginRequestModel.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/LoginParams.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserProfileEntity.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  AuthRepositoryImpl(this._remoteDataSource, this._secureStorage);

  @override
  Future<ApiResult<AuthSessionEntity>> login(LoginParams params) async {
    try {
      final request = LoginRequestModel(
        tenDangNhapHis: params.tenDangNhapHis,
        matKhauHis: params.matKhauHis,
        device: params.device,
        isMobile: true,
        platform: params.platform,
        version: params.version,
        username: params.username,
        password: params.password,
        captchaToken: params.captchaToken,
      );

      // DataSource đã tự gọi ApiValidator và trả về Model sạch (đã validate).
      final model = await _remoteDataSource.login(request);

      // Lưu trữ token sau khi đăng nhập thành công
      await _secureStorage.saveTokensRecord(
        model.accessToken,
        model.refreshToken,
      );
      await _secureStorage.saveExpiresRefreshToken(
        model.expiresRefreshTokenTicks.toString(),
      );

      return ApiSuccess(model.toEntity());
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi không xác định: $e'));
    }
  }

  @override
  Future<ApiResult<UserProfileEntity>> loginHis(
    String tenDangNhap,
    String matKhau,
  ) async {
    try {
      final request = LoginHisRequestModel(
        tenDangNhap: tenDangNhap,
        matKhau: matKhau,
      );
      final model = await _remoteDataSource.loginHis(request);

      return ApiSuccess(model.toEntity());
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(
       UnknownException('Đã xảy ra lỗi khi lấy hồ sơ HIS: $e'),
      );
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearSession();
    AppSessionStore.instance.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_phone');
      await prefs.remove('saved_his_username');
      await prefs.remove('saved_role');
      await prefs.remove('saved_full_name');
      await prefs.remove('saved_session');
    } catch (_) {}
  }

  // --- OTP & Account APIs Implementation ---

  @override
  Future<ApiResult<bool>> checkExistAccount(String phone) async {
    try {
      final exists = await _remoteDataSource.checkExistAccount(phone);
      return ApiSuccess(exists);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Lỗi kiểm tra tài khoản tồn tại: $e'));
    }
  }

  @override
  Future<ApiResult<String>> generateRandomKey() async {
    try {
      final key = await _remoteDataSource.generateRandomKey();
      return ApiSuccess(key);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi sinh khóa: $e'));
    }
  }

  @override
  Future<ApiResult<SendOtpResponseModel>> sendOtp(String phone, String key, String sendType) async {
    try {
      final input = OtpSendInputModel(
        soDienThoai: phone,
        key: key,
        sendType: sendType,
      );
      final res = await _remoteDataSource.sendOtp(input);
      return ApiSuccess(res);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi gửi OTP: $e'));
    }
  }

  @override
  Future<ApiResult<int>> verifyOtp(String phone, String otp, String key, int adjustSeconds) async {
    try {
      final input = OtpVerifyInputModel(
        soDienThoai: phone,
        otp: otp,
        key: key,
        adjustSeconds: adjustSeconds,
      );
      final res = await _remoteDataSource.verifyOtp(input);
      return ApiSuccess(res);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi xác thực OTP: $e'));
    }
  }

  @override
  Future<ApiResult<String>> signUp(
    String fullName,
    String phone,
    String password,
    String otp,
    String key,
    int adjustSeconds,
  ) async {
    try {
      final input = DkkSignUpRequestModel(
        soDienThoai: phone,
        matKhau: password,
        hoTen: fullName,
        otp: otp,
        key: key,
        adjustSeconds: adjustSeconds,
      );
      final res = await _remoteDataSource.signUp(input);
      return ApiSuccess(res);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi đăng ký tài khoản: $e'));
    }
  }

  @override
  Future<ApiResult<String>> resetPassword(
    String phone,
    String password,
    String otp,
    String key,
    int adjustSeconds,
  ) async {
    try {
      final input = DkkResetPasswordRequestModel(
        soDienThoai: phone,
        matKhau: password,
        otp: otp,
        key: key,
        adjustSeconds: adjustSeconds,
      );
      final res = await _remoteDataSource.resetPassword(input);
      return ApiSuccess(res);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi đặt lại mật khẩu: $e'));
    }
  }

  @override
  Future<ApiResult<bool>> changePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final input = ChangePasswordRequestModel(
        matKhauCu: oldPassword,
        matKhauMoi: newPassword,
        nhapLaiMatKhauMoi: confirmPassword,
      );
      final res = await _remoteDataSource.changePassword(input);
      return ApiSuccess(res);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi đổi mật khẩu: $e'));
    }
  }

  @override
  Future<ApiResult<String>> deleteAccount(
    String phone,
    String password,
    String otp,
    String key,
    int adjustSeconds,
  ) async {
    try {
      final input = DkkResetPasswordRequestModel(
        soDienThoai: phone,
        matKhau: password,
        otp: otp,
        key: key,
        adjustSeconds: adjustSeconds,
      );
      final res = await _remoteDataSource.deleteAccount(input);
      return ApiSuccess(res);
    } on ApiException catch (e) {
      return ApiFailure(e);
    } catch (e) {
      return ApiFailure(UnknownException('Đã xảy ra lỗi xóa tài khoản: $e'));
    }
  }
}
