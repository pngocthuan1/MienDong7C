import 'package:flutter/material.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';

bool isPhoneAlreadyExistsMessage(String msg) {
  return msg.contains('tồn tại') ||
      msg.contains('đã được') ||
      msg.contains('đã sử dụng') ||
      msg.contains('đã đăng ký') ||
      msg.contains('104') ||
      msg.contains('Exist');
}


class OtpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final String phoneNumber;
  final OtpPurpose purpose;
  final String fullName;
  String? password;
  String key;
  int adjustSeconds;

  final otpController = TextEditingController();
  String? _message;

  late final Command<String> verifyOtpCommand;
  late final Command<String> resendOtpCommand;

  OtpViewModel(
    this._authRepository, {
    required this.phoneNumber,
    required this.purpose,
    this.fullName = '',
    this.password = '',
    this.key = '',
    this.adjustSeconds = 0,
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
      notifyListeners();
    }
  }

  Future<ApiResult<String>> _verifyOtp() async {
    _message = null;
    notifyListeners();

    final otp = otpController.text.trim();

    if (purpose == OtpPurpose.registration) {
      final currentPassword = password ?? '';
      final res = await _authRepository.signUp(
        fullName,
        phoneNumber,
        currentPassword,
        otp,
        key,
        adjustSeconds,
      );
      if (res is ApiFailure<String>) {
        final msg = res.exception.message;
        if (isPhoneAlreadyExistsMessage(msg)) {
          _message = 'Số điện thoại này đã được đăng ký tài khoản. Vui lòng đăng nhập hoặc dùng tính năng Quên mật khẩu.';
        } else {
          _message = msg;
        }
        notifyListeners();
        return ApiFailure(ApiException.validation(_message!));
        // Không xóa password ở đây — người dùng có thể sửa OTP và thử lại với password đã nhập
      }

      final data = (res as ApiSuccess<String>).data;
      if (data == 'Invalid') {
        _message = 'Mã OTP không hợp lệ hoặc đăng ký thất bại';
        notifyListeners();
        return ApiFailure(ApiException.validation(_message!));
        // Tương tự, chưa xóa password vì người dùng có thể nhập lại OTP
      }

      // Đến đây signUp() ĐÃ THÀNH CÔNG: Mật khẩu không còn cần dùng nữa, an toàn để giải phóng khỏi RAM
      password = null;

      final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (fullName.trim().isNotEmpty) {
        try {
          await AppLocator.secureStorage.saveSavedFullName(fullName.trim());
          await AppLocator.secureStorage.saveSavedPhone(phoneNumber);
          if (clean.isNotEmpty) {
            await AppLocator.secureStorage.saveFullNameForPhone(clean, fullName.trim());
          }
        } catch (_) {}
      }

      return res;
    } else {
      if (otp.length != 6) {
        _message = 'Vui lòng nhập đủ 6 chữ số OTP';
        notifyListeners();
        return ApiFailure(ApiException.validation(_message!));
      }

      return const ApiSuccess('Xác thực OTP thành công!');
    }
  }

  int resendCount = 0;
  DateTime? _lockUntil;

  static const int maxResendAttempts = 3;
  static const int resendLockoutMinutes = 5;

  bool get isResendLocked {
    if (_lockUntil == null) return false;
    return DateTime.now().isBefore(_lockUntil!);
  }

  int get remainingLockoutSeconds {
    if (_lockUntil == null) return 0;
    final diff = _lockUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Future<ApiResult<String>> _resendOtp() async {
    _message = null;
    notifyListeners();
    if(_lockUntil != null && !isResendLocked) {
      _lockUntil = null;
      resendCount = 0;
    }

    // 0. Kiểm tra khóa nếu đã yêu cầu quá 3 lần
    if (isResendLocked) {
      final minutes = (remainingLockoutSeconds / 60).ceil();
      _message = 'Bạn đã gửi lại mã OTP quá 3 lần. Vui lòng chờ $minutes phút để thử lại!';
      notifyListeners();
      return ApiFailure(ApiException.validation(_message!));
    }

    if (resendCount >= maxResendAttempts) {
      _lockUntil = DateTime.now().add(const Duration(minutes: resendLockoutMinutes));
      _message = 'Bạn đã yêu cầu gửi lại OTP quá 3 lần. Vui lòng tạm dừng 5 phút để bảo vệ hệ thống!';
      notifyListeners();
      return ApiFailure(ApiException.validation(_message!));
    }

    // 1. Sinh khóa mới
    final keyResult = await _authRepository.generateRandomKey();
    if (keyResult is ApiFailure<String>) {
      _message = keyResult.exception.message;
      notifyListeners();
      return keyResult;
    }
    final newKey = (keyResult as ApiSuccess<String>).data;

    // 2. Gửi OTP mới
    final sendType = purpose == OtpPurpose.registration ? 'SignUp' : 'ResetPassword';
    final otpResult = await _authRepository.sendOtp(phoneNumber, newKey, sendType);
    if (otpResult is ApiFailure<SendOtpResponseModel>) {
      _message = otpResult.exception.message;
      notifyListeners();
      return ApiFailure(otpResult.exception);
    }
    final otpData = (otpResult as ApiSuccess<SendOtpResponseModel>).data;

    resendCount++;
    if (resendCount >= maxResendAttempts) {
      _lockUntil = DateTime.now().add(const Duration(minutes: resendLockoutMinutes));
    }

    key = newKey;
    adjustSeconds = otpData.adjustSeconds;

    return ApiSuccess(otpData.message ?? 'Đã gửi lại mã OTP thành công!');
  }

  @override
  void dispose() {
    password = null;
    otpController.dispose();
    super.dispose();
  }
}
