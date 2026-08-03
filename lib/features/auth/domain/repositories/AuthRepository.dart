import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/LoginParams.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserProfileEntity.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';

abstract class AuthRepository {
  // Hàm thực thi nghiệp vụ đăng nhập lấy token
  Future<ApiResult<AuthSessionEntity>> login(LoginParams params);

  // Hàm thực thi nghiệp vụ lấy thông tin hồ sơ bác sĩ HIS
  Future<ApiResult<UserProfileEntity>> loginHis(
    String tenDangNhap,
    String matKhau,
  );

  // Hàm đăng xuất dọn dẹp phiên làm việc
  Future<void> logout();

  // --- Offline Demo Mode ---
  bool get isOfflineDemo;
  void setOfflineDemo(bool val);

  // --- OTP & Account APIs ---
  Future<ApiResult<String>> generateRandomKey();
  Future<ApiResult<SendOtpResponseModel>> sendOtp(String phone, String key, String sendType);
  Future<ApiResult<int>> verifyOtp(String phone, String otp, String key, int adjustSeconds);
  Future<ApiResult<String>> signUp(String fullName, String phone, String password, String otp, String key, int adjustSeconds);
  Future<ApiResult<String>> resetPassword(String phone, String password, String otp, String key, int adjustSeconds);
  Future<ApiResult<bool>> changePassword(String oldPassword, String newPassword, String confirmNewPassword);
}
