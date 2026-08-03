import 'package:flutter/material.dart';
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
    _message = null;
    notifyListeners();

    final password = passwordController.text;

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

    return res;
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
