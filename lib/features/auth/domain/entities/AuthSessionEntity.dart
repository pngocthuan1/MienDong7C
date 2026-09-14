import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';

class AuthSessionEntity {
  final String accessToken;
  final String refreshToken;
  final DateTime? refreshTokenExpiry;
  final UserProfileSession user;

  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    this.refreshTokenExpiry,
    this.user = const UserProfileSession(
      fullName: 'Người dùng Bệnh viện 7C',
      phoneNumber: '',
      role: UserRole.customer,
    ),
  });

  bool get isEmployee => user.role == UserRole.employee;

  bool get isExpired {
    if (refreshTokenExpiry == null) return false;
    return DateTime.now().isAfter(refreshTokenExpiry!);
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'refreshTokenExpiry': refreshTokenExpiry?.toIso8601String(),
    };
  }

  factory AuthSessionEntity.fromJson(Map<String, dynamic> json) {
    return AuthSessionEntity(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      refreshTokenExpiry: json['refreshTokenExpiry'] != null
          ? DateTime.tryParse(json['refreshTokenExpiry'] as String)
          : null,
    );
  }
}
