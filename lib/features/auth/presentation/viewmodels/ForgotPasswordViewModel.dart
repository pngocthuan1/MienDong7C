import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';
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

  String otpKey = '';
  int adjustSeconds = 0;

  Future<ApiResult<String>> _requestOtp() async {
    _message = null;
    notifyListeners();

    final phone = phoneController.text.trim();

    // 1. Sinh khóa ngẫu nhiên
    final keyResult = await _authRepository.generateRandomKey();
    if (keyResult is ApiFailure<String>) {
      _message = keyResult.exception.message;
      notifyListeners();
      return keyResult;
    }
    final key = (keyResult as ApiSuccess<String>).data;

    // 2. Gửi mã OTP
    final otpResult = await _authRepository.sendOtp(phone, key, 'ResetPassword');
    if (otpResult is ApiFailure<SendOtpResponseModel>) {
      _message = otpResult.exception.message;
      notifyListeners();
      return ApiFailure(otpResult.exception);
    }
    final otpData = (otpResult as ApiSuccess<SendOtpResponseModel>).data;

    otpKey = key;
    adjustSeconds = otpData.adjustSeconds;

    return ApiSuccess(otpData.message ?? 'Đã gửi mã OTP thành công!');
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}
