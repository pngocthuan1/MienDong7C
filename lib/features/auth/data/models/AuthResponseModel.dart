import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';

/// Model đại diện cho phần "Data" trong response đăng nhập,
/// KHÔNG chứa ErrorCode/ErrorId/ErrorMessage vì các field đó
/// đã được ApiValidator xử lý và throw exception trước khi model
/// này được tạo ra. Nếu code chạy tới fromJson() nghĩa là response
/// đã chắc chắn thành công.

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final int expiresRefreshTokenTicks;

  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresRefreshTokenTicks,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final rawExpires = json['ExpiresRefreshToken'];
    final expiresTicks = rawExpires is int
        ? rawExpires
        : int.tryParse(rawExpires?.toString() ?? '') ?? 0;

    return AuthResponseModel(
      accessToken: json['AccessToken'] as String? ?? '',
      refreshToken: json['RefreshToken'] as String? ?? '',
      expiresRefreshTokenTicks: expiresTicks,
    );
  }

  AuthSessionEntity toEntity() {
    return AuthSessionEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      refreshTokenExpiry: DateTimeConverter.fromTicks(expiresRefreshTokenTicks),
    );
  }
}
