enum UserRole {
  customer('Khách hàng'),
  employee('Nhân viên / Bác sĩ');

  final String label;
  const UserRole(this.label);

  bool get isEmployee => this == UserRole.employee;

  String get secondMenuTitle {
    switch (this) {
      case UserRole.customer:
        return 'Đăng ký khám bệnh';
      case UserRole.employee:
        return 'Danh sách tiếp nhận';
    }
  }

  String get secondHomeCardTitle {
    switch (this) {
      case UserRole.customer:
        return 'Đăng ký\nKhám bệnh';
      case UserRole.employee:
        return 'Tiếp nhận\nHồ sơ';
    }
  }

  String get topWelcome {
    switch (this) {
      case UserRole.customer:
        return 'Chào mừng bạn đến với\nBệnh viện Miền Đông 7C';
      case UserRole.employee:
        return 'Hệ thống tiếp nhận & quản lý bệnh nhân\nBệnh viện Miền Đông 7C';
    }
  }
}
