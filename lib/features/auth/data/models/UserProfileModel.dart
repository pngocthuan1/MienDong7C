import 'package:benhvien7c/features/auth/domain/entities/UserProfileEntity.dart';

/// Model đại diện cho phần "Data" trong response lấy hồ sơ bác sĩ/nhân viên HIS.
/// KHÔNG chứa ErrorCode/ErrorId/ErrorMessage vì các field đó đã được
/// ApiValidator xử lý trước khi model này được tạo ra.
class UserProfileModel {
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

  UserProfileModel({
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

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      // Cố tình KHÔNG đọc field 'pass' từ backend — không đưa mật khẩu
      // đi xa hơn tầng parse JSON này, tránh lộ dữ liệu nhạy cảm về sau.
      idHis: json['IdHis'] as int? ?? 0,
      tenDangNhapHis: json['TenDangNhapHis'] as String? ?? '',
      hoTenHis: json['HoTenHis'] as String? ?? '',
      ma: json['Ma'] as String? ?? '',
      email: json['Email'] as String?,
      soDienThoai: json['SoDienThoai'] as String?,
      gioiTinh: json['GioiTinh'] as String?,
      ngaySinh: json['NgaySinh'] as String?,
      serverMode: json['ServerMode'] as int? ?? 0,
      capHis: json['CapHis'] as int? ?? 0,
      idBacSi: json['IdBacSi'] as int? ?? 0,
      tenBacSi: json['TenBacSi'] as String? ?? '',
      nhom: json['Nhom'] as int? ?? 0,
      cchn: json['Cchn'] as String? ?? '',
    );
  }

  /// Convert Model (JSON layer) -> Entity (domain layer).
  /// Entity không có field mật khẩu, đảm bảo dữ liệu nhạy cảm dừng lại
  /// ở tầng data, không lan ra ViewModel/UI.
  UserProfileEntity toEntity() {
    return UserProfileEntity(
      idHis: idHis,
      tenDangNhapHis: tenDangNhapHis,
      hoTenHis: hoTenHis,
      ma: ma,
      email: email,
      soDienThoai: soDienThoai,
      gioiTinh: gioiTinh,
      ngaySinh: ngaySinh,
      serverMode: serverMode,
      capHis: capHis,
      idBacSi: idBacSi,
      tenBacSi: tenBacSi,
      nhom: nhom,
      cchn: cchn,
    );
  }
}
