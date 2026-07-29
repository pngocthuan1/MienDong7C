import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  final phoneController = TextEditingController();
  String? _message;

  late final Command<String> requestOtpCommand;

  ForgotPasswordViewModel(this._authRepository) {
    requestOtpCommand = Command<String>(_requestOtp);
  }

  String? get message => _message;

  String? checkPhone(String? value) {
    return Validators.validatePhone(value);
  }

  void updatePhoneError(String? val) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  Future<ApiResult<String>> _requestOtp() async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiSuccess('Mã OTP 123456 đã được gửi tới số điện thoại ${phoneController.text.trim()}');
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}
