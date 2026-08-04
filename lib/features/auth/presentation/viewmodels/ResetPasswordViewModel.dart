import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final String phoneNumber;
  final String otpCode;
  final String key;
  final int adjustSeconds;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? _message;

  late final Command<String> resetPasswordCommand;

  ResetPasswordViewModel(
    this._authRepository, {
    required this.phoneNumber,
    required this.otpCode,
    this.key = '',
    this.adjustSeconds = 0,
  }) {
    resetPasswordCommand = Command<String>(_resetPassword);
  }

  String? get message => _message;

  String? checkPassword(String? value) {
    final clean = value ?? '';
    if (clean.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    return Validators.validatePassword(clean);
  }

  String? checkConfirmPassword(String? value) {
    final clean = value ?? '';
    if (clean.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu mới';
    }
    if (clean != passwordController.text) {
      return 'Mật khẩu nhập lại chưa trùng khớp với mật khẩu mới';
    }
    return null;
  }

  void onPasswordChanged() {
    if (_message != null) {
      _message = null;
    }
    notifyListeners();
  }

  void updateConfirmPasswordError(String? val) {
    if (_message != null) {
      _message = null;
    }
    notifyListeners();
  }

  Future<ApiResult<String>> _resetPassword() async {
    _message = null;
    notifyListeners();

    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    final errPw = checkPassword(password);
    if (errPw != null) {
      _message = errPw;
      notifyListeners();
      return ApiFailure(ApiException.validation(errPw));
    }

    final errConfirm = checkConfirmPassword(confirmPassword);
    if (errConfirm != null) {
      _message = errConfirm;
      notifyListeners();
      return ApiFailure(ApiException.validation(errConfirm));
    }

    final res = await _authRepository.resetPassword(
      phoneNumber,
      password,
      otpCode,
      key,
      adjustSeconds,
    );

    if (res is ApiFailure<String>) {
      _message = res.exception.message;
      notifyListeners();
      return res;
    }

    return const ApiSuccess('Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại với mật khẩu mới.');
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
