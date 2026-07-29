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
        UnauthorizedException('Đã xảy ra lỗi khi lấy hồ sơ HIS: $e'),
      );
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearSession();
  }
}
