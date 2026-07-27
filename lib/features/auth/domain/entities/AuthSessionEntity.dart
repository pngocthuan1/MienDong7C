import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';

class AuthSessionEntity {
  final String accessToken;
  final String refreshToken;
  final DateTime refreshTokenExpiry;

  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenExpiry,
  });

  bool get isRefreshTokenExpired => DateTime.now().isAfter(refreshTokenExpiry);

  bool get isEmployee => user.role == UserRole.employee;

  UserProfileSession get user {
    return AppSessionStore.instance.currentUser ?? const UserProfileSession(
      fullName: 'Khách Hàng Demo',
      phoneNumber: '0902377251',
      role: UserRole.customer,
    );
  }
}
