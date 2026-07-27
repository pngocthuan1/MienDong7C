import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/LoginParams.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserProfileEntity.dart';

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
}
