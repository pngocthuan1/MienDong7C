import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';

class OtpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final String phoneNumber;
  final OtpPurpose purpose;

  final otpController = TextEditingController();
  String? _message;

  late final Command<String> verifyOtpCommand;
  late final Command<String> resendOtpCommand;

  OtpViewModel(
    this._authRepository, {
    required this.phoneNumber,
    required this.purpose,
  }) {
    verifyOtpCommand = Command<String>(_verifyOtp);
    resendOtpCommand = Command<String>(_resendOtp);
  }

  String? get message => _message;

  bool get isOtpComplete => otpController.text.trim().length == 6;

  String? checkOtp(String? value) {
    if (value == null || value.trim().length < 6) {
      return 'Vui lòng nhập đủ 6 chữ số OTP';
    }
    return null;
  }

  void updateOtpError(String? val) {
    if (_message != null) {
      _message = null;
    }
    notifyListeners();
  }

  Future<ApiResult<String>> _verifyOtp() async {
    await Future.delayed(const Duration(seconds: 1));
    return const ApiSuccess('Xác thực OTP thành công!');
  }

  Future<ApiResult<String>> _resendOtp() async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiSuccess('Đã gửi lại mã OTP đến số điện thoại $phoneNumber');
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
