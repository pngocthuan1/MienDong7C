import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';

class Command<T> extends ChangeNotifier {
  final Future<ApiResult<T>> Function() _action;
  bool _running = false;
  ApiResult<T>? _result;

  Command(this._action);

  bool get running => _running;
  ApiResult<T>? get result => _result;

  Future<void> execute() async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await _action();
    } catch (e,stackTrace) {
      debugPrint('[Command] Unhandled error during execute(): $e');
      debugPrintStack(stackTrace: stackTrace);
       _result = ApiFailure(
        UnknownException('Đã xảy ra lỗi không xác định. Vui lòng thử lại.'),
      );
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  String? _message;

  late final Command<String> registerCommand;

  RegisterViewModel(this._authRepository) {
    registerCommand = Command<String>(_register);
  }

  UserRole get selectedRole => _selectedRole;
  String? get message => _message;

  void updateRole(UserRole role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  String? checkFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    return null;
  }

  String? phoneError;

  String? checkPhone(String? value) {
    if (phoneError != null) return phoneError;
    return Validators.validatePhone(value);
  }

  String? checkEmail(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!value.contains('@')) return 'Email không đúng định dạng';
    }
    return null;
  }

  String? checkPassword(String? value) {
    return Validators.validatePassword(value);
  }

  String? checkConfirmPassword(String? value) {
    if (value != passwordController.text) {
      return 'Mật khẩu nhập lại không khớp';
    }
    return null;
  }

  void updateFullNameError(String? val) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  void updatePhoneError(String? val) {
    if (phoneError != null || _message != null) {
      phoneError = null;
      _message = null;
      notifyListeners();
    }
  }

  void updateEmailError(String? val) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  void onPasswordChanged() {
    notifyListeners();
  }

  void updateConfirmPasswordError(String? val) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  String otpKey = '';
  int adjustSeconds = 0;
  int remainingSeconds = 60;

  bool _isPhoneAlreadyExistsMessage(String msg) {
    return msg.contains('tồn tại') ||
        msg.contains('đã được') ||
        msg.contains('đã sử dụng') ||
        msg.contains('đã đăng ký') ||
        msg.contains('104') ||
        msg.contains('Exist');
  }

  Future<ApiResult<String>> _register() async {
    _message = null;
    final phone = phoneController.text.trim();

    // 1. Kiểm tra trên Server C# xem Số điện thoại đã có tài khoản hay chưa -> CHẶN NGAY TẠI MÀN HÌNH ĐĂNG KÝ
    final checkResult = await _authRepository.checkExistAccount(phone);
    if (checkResult is ApiSuccess<bool> && checkResult.data == true) {
      phoneError = 'Số điện thoại này đã được đăng ký tài khoản. Vui lòng đăng nhập hoặc dùng tính năng Quên mật khẩu.';
      notifyListeners();
      return ApiFailure(ApiException.validation(phoneError!));
    }

    // 2. Sinh khóa ngẫu nhiên từ Server C#
    final keyResult = await _authRepository.generateRandomKey();
    if (keyResult is ApiFailure<String>) {
      _message = keyResult.exception.message;
      notifyListeners();
      return keyResult;
    }
    final key = (keyResult as ApiSuccess<String>).data;

    // 3. Gửi mã OTP thực tế (nếu SĐT chưa từng đăng ký)
    final otpResult = await _authRepository.sendOtp(phone, key, 'SignUp');
    if (otpResult is ApiFailure<SendOtpResponseModel>) {
      final msg = otpResult.exception.message;
      if (_isPhoneAlreadyExistsMessage(msg)) {
        phoneError = 'Số điện thoại này đã được đăng ký tài khoản. Vui lòng đăng nhập hoặc dùng tính năng Quên mật khẩu.';
      } else {
        _message = msg;
      }
      notifyListeners();
      return ApiFailure(otpResult.exception);
    }

    final otpData = (otpResult as ApiSuccess<SendOtpResponseModel>).data;
    final serverMsg = otpData.message ?? '';

    // Nếu Server trả về 200 OK nhưng nội dung message thông báo số đã tồn tại / đã đăng ký
    if (_isPhoneAlreadyExistsMessage(serverMsg)) {
      phoneError = 'Số điện thoại này đã được đăng ký tài khoản. Vui lòng đăng nhập hoặc dùng tính năng Quên mật khẩu.';
      notifyListeners();
      return ApiFailure(ApiException.validation(phoneError!));
    }

    otpKey = key;
    adjustSeconds = otpData.adjustSeconds;
    remainingSeconds = otpData.remainingSeconds;

    return ApiSuccess(otpData.message ?? 'Đã gửi mã OTP thành công!');
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
