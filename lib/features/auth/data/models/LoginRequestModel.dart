class LoginRequestModel {
  final String tenDangNhapHis;
  final String matKhauHis;
  final String device;
  final bool isMobile;
  final String platform;
  final String version;
  final String username;
  final String password;

  LoginRequestModel({
    required this.tenDangNhapHis,
    required this.matKhauHis,
    required this.device,
    this.isMobile = true,
    required this.platform,
    required this.version,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'TenDangNhapHis': tenDangNhapHis,
      'MatKhauHis': matKhauHis,
      'Device': device,
      'IsMobile': isMobile,
      'Platform': platform,
      'Version': version,
      'Username': username,
      'Password': password,
    };
  }

  /// Che các trường mật khẩu khi in ra log/console, tránh lộ dữ liệu
  /// nhạy cảm nếu lỡ debug print hoặc log interceptor bật nhầm ở production.
  @override
  String toString() {
    return 'LoginRequestModel(tenDangNhapHis: $tenDangNhapHis, matKhauHis: ***, '
        'device: $device, isMobile: $isMobile, platform: $platform, '
        'version: $version, username: $username, password: ***)';
  }
}
