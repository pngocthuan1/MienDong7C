class Validators {
  const Validators._();

  static String? validateVietnamesePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final trimmed = value.trim();
    var clean = trimmed.replaceAll(RegExp(r'\D'), '');

    if (clean.startsWith('84') && clean.length == 11) {
      clean = '0${clean.substring(2)}';
    }

    if (clean.length != 10) {
      return 'Số điện thoại Việt Nam phải bao gồm 10 chữ số';
    }

    if (!RegExp(r'^(03|05|07|08|09)\d{8}$').hasMatch(clean)) {
      return 'Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam (gồm 10 số, bắt đầu bằng 03, 05, 07, 08, 09)';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại hoặc tên đăng nhập';
    }
    final trimmed = value.trim();
    final clean = trimmed.replaceAll(RegExp(r'\D'), '');

    final looksLikePhone = clean.length >= 9 && RegExp(r'^\d+$').hasMatch(clean);
    if (looksLikePhone) {
      return validateVietnamesePhoneNumber(trimmed);
    }

    if (trimmed.length < 3) {
      return 'Tên đăng nhập hoặc số điện thoại phải có ít nhất 3 ký tự';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    return validateVietnamesePhoneNumber(value);
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 8) {
      return 'Mật khẩu tối thiểu 8 ký tự';
    }
    if (!startsWithUppercase(value)) {
      return 'Mật khẩu phải bắt đầu bằng 1 chữ hoa';
    }
    if (!hasNumber(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số';
    }
    if (!hasSpecialChar(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt';
    }
    return null;
  }

  static String? validateRequired(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  static bool hasMinPasswordLength(String? value) {
    if (value == null) return false;
    return value.length >= 8;
  }

  static bool startsWithUppercase(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(r'^[A-ZÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ]').hasMatch(value);
  }

  static bool hasLetter(String? value) {
    if (value == null) return false;
    return RegExp(r'[a-zA-Z]').hasMatch(value);
  }

  static bool hasNumber(String? value) {
    if (value == null) return false;
    return RegExp(r'[0-9]').hasMatch(value);
  }

  static bool hasSpecialChar(String? value) {
    if (value == null) return false;
    return RegExp(r'[!@#$%^&*(),.?":{}|<>\-_+=\[\]\\\/~`]').hasMatch(value);
  }
}
