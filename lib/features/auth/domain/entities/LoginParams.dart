class LoginParams {
  final String tenDangNhapHis;
  final String matKhauHis;
  final String username;
  final String password;
  final String device;
  final String platform;
  final String version;
  final String? captchaToken;

  const LoginParams({
    required this.tenDangNhapHis,
    required this.matKhauHis,
    required this.username,
    required this.password,
    required this.device,
    required this.platform,
    required this.version,
    this.captchaToken,
  });
}
