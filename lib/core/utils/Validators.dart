class Validators {
  const Validators._();

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại hoặc tên đăng nhập';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Tên đăng nhập hoặc số điện thoại phải có ít nhất 3 ký tự';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải chứa ít nhất 6 ký tự';
    }
    return null;
  }

  static String? validateRequired(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(trimmed)) {
      return 'Số điện thoại không hợp lệ (phải bắt đầu bằng số 0 và gồm 10 chữ số)';
    }
    return null;
  }

  static bool hasMinPasswordLength(String? value) {
    if (value == null) return false;
    return value.length >= 8;
  }

  static bool hasLetter(String? value) {
    if (value == null) return false;
    return RegExp(r'[a-zA-Z]').hasMatch(value);
  }

  static bool hasNumber(String? value) {
    if (value == null) return false;
    return RegExp(r'[0-9]').hasMatch(value);
  }
}
