class LoginRequestModel {
  final String tenDangNhapHis;
  final String matKhauHis;
  final String device;
  final bool isMobile;
  final String platform;
  final String version;
  final String username;
  final String password;
  final String? captchaToken;

  LoginRequestModel({
    required this.tenDangNhapHis,
    required this.matKhauHis,
    required this.device,
    this.isMobile = true,
    required this.platform,
    required this.version,
    required this.username,
    required this.password,
    this.captchaToken,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'TenDangNhapHis': tenDangNhapHis,
      'MatKhauHis': matKhauHis,
      'Device': device,
      'IsMobile': isMobile,
      'Platform': platform,
      'Version': version,
      'Username': username,
      'Password': password,
    };
    if (captchaToken != null && captchaToken!.isNotEmpty) {
      data['CaptchaToken'] = captchaToken;
    }
    return data;
  }

  @override
  String toString() {
    return 'LoginRequestModel(tenDangNhapHis: $tenDangNhapHis, matKhauHis: ***, '
        'device: $device, isMobile: $isMobile, platform: $platform, '
        'version: $version, username: $username, password: ***, captchaToken: $captchaToken)';
  }
}
