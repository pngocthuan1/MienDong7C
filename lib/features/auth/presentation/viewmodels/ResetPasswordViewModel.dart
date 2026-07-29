import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final String phoneNumber;
  final String otpCode;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? _message;

  late final Command<String> resetPasswordCommand;

  ResetPasswordViewModel(
    this._authRepository, {
    required this.phoneNumber,
    required this.otpCode,
  }) {
    resetPasswordCommand = Command<String>(_resetPassword);
  }

  String? get message => _message;

  String? checkPassword(String? value) {
    return Validators.validatePassword(value);
  }

  String? checkConfirmPassword(String? value) {
    if (value != passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
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

  Future<ApiResult<String>> _resetPassword() async {
    await Future.delayed(const Duration(seconds: 1));
    return const ApiSuccess('Đặt lại mật khẩu thành công! Vui lòng đăng nhập.');
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
