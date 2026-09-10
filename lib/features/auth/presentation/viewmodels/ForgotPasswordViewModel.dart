import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';

bool isPhoneNotRegisteredMessage(String msg) {
  return msg.contains('chưa') ||
      msg.contains('không tồn tại') ||
      msg.contains('chưa được') ||
      msg.contains('NotExist') ||
      msg.contains('103') ||
      msg.contains('Not Exist');
}


class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  final phoneController = TextEditingController();
  String? _message;
  String? phoneError;

  late final Command<String> requestOtpCommand;

  ForgotPasswordViewModel(this._authRepository) {
    requestOtpCommand = Command<String>(_requestOtp);
  }

  String? get message => _message;

  String? checkPhone(String? value) {
    if (phoneError != null) return phoneError;
    return Validators.validatePhone(value);
  }

  void updatePhoneError(String? val) {
    if (phoneError != null || _message != null) {
      phoneError = null;
      _message = null;
      notifyListeners();
    }
  }

  String otpKey = '';
  int adjustSeconds = 0;
  int remainingSeconds = 60;

  Future<ApiResult<String>> _requestOtp() async {
    _message = null;
    final phone = phoneController.text.trim();

    // 1. Kiểm tra trên Server C# xem Số điện thoại đã có tài khoản hay chưa -> CHẶN NGAY TẠI MÀN HÌNH QUÊN MẬT KHẨU
    final checkResult = await _authRepository.checkExistAccount(phone);

    if (checkResult is ApiFailure<bool>) {
      _message = checkResult.exception.message;
      notifyListeners();
      return ApiFailure(checkResult.exception);
    }

    if (checkResult is ApiSuccess<bool> && checkResult.data == false) {
      phoneError = 'Số điện thoại này chưa được đăng ký tài khoản. Vui lòng kiểm tra lại hoặc chọn Đăng ký.';
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

    // 3. Gửi mã OTP
    final otpResult = await _authRepository.sendOtp(phone, key, 'ResetPassword');
    if (otpResult is ApiFailure<SendOtpResponseModel>) {
      final msg = otpResult.exception.message;
      if (isPhoneNotRegisteredMessage(msg)) {
        phoneError = 'Số điện thoại này chưa được đăng ký tài khoản. Vui lòng kiểm tra lại hoặc chọn Đăng ký.';
      } else {
        _message = msg;
      }
      notifyListeners();
      return ApiFailure(otpResult.exception);
    }
    final otpData = (otpResult as ApiSuccess<SendOtpResponseModel>).data;
    final serverMsg = otpData.message ?? '';

    // Nếu Server trả về 200 OK nhưng nội dung message thông báo số chưa đăng ký / không tồn tại
    if (isPhoneNotRegisteredMessage(serverMsg)) {
      phoneError = 'Số điện thoại này chưa được đăng ký tài khoản. Vui lòng kiểm tra lại hoặc chọn Đăng ký.';
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
    phoneController.dispose();
    super.dispose();
  }
}
