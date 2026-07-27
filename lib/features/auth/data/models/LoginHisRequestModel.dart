class LoginHisRequestModel {
  final String tenDangNhap;
  final String matKhau;

  LoginHisRequestModel({required this.tenDangNhap, required this.matKhau});

  Map<String, dynamic> toJson() {
    return {'tenDangNhap': tenDangNhap, 'matKhau': matKhau};
  }

  /// Che mật khẩu khi in ra log/console, tránh lộ dữ liệu nhạy cảm
  /// nếu lỡ debug print hoặc log interceptor bật nhầm ở production.
  @override
  String toString() =>
      'LoginHisRequestModel(tenDangNhap: $tenDangNhap, matKhau: ***)';
}
