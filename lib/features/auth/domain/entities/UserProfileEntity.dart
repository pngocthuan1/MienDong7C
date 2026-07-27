// lib/features/auth/domain/entities/user_profile_entity.dart
class UserProfileEntity {
  final int idHis;
  final String tenDangNhapHis;
  final String hoTenHis;
  final String ma;
  final String? email;
  final String? soDienThoai;
  final String? gioiTinh;
  final String? ngaySinh;
  final int serverMode;
  final int capHis;
  final int idBacSi;
  final String tenBacSi;
  final int nhom;
  final String cchn;

  const UserProfileEntity({
    required this.idHis,
    required this.tenDangNhapHis,
    required this.hoTenHis,
    required this.ma,
    this.email,
    this.soDienThoai,
    this.gioiTinh,
    this.ngaySinh,
    required this.serverMode,
    required this.capHis,
    required this.idBacSi,
    required this.tenBacSi,
    required this.nhom,
    required this.cchn,
  });
}
