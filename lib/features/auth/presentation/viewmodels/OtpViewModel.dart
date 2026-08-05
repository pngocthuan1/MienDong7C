import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/data/models/DkkAuthModels.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';

class OtpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final String phoneNumber;
  final OtpPurpose purpose;
  final String fullName;
  final String password;
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
    }
    notifyListeners();
  }

  Future<ApiResult<String>> _verifyOtp() async {
    _message = null;
    notifyListeners();

    final otp = otpController.text.trim();

    if (purpose == OtpPurpose.registration) {
      final res = await _authRepository.signUp(
        fullName,
        phoneNumber,
        password,
        otp,
        key,
        adjustSeconds,
      );
      if (res is ApiFailure<String>) {
        _message = res.exception.message;
        notifyListeners();
        return res;
      }
      final data = (res as ApiSuccess<String>).data;
      if (data == 'Invalid') {
        _message = 'Mã OTP không hợp lệ hoặc đăng ký thất bại';
        notifyListeners();
        return ApiFailure(ApiException.validation(_message!));
      }
      SharedPreferences.getInstance().then((prefs) {
        final list = (prefs.getStringList('registered_phone_numbers') ?? ['0822380103', '0902377251', '0987654321']).toSet();
        final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
        if (clean.isNotEmpty) {
          list.add(clean);
          if (fullName.trim().isNotEmpty) {
            prefs.setString('full_name_$clean', fullName.trim());
            prefs.setString('saved_full_name', fullName.trim());
          }
        }
        prefs.setStringList('registered_phone_numbers', list.toList());
      });
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

  Future<ApiResult<String>> _resendOtp() async {
    _message = null;
    notifyListeners();

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

    key = newKey;
    adjustSeconds = otpData.adjustSeconds;

    return ApiSuccess(otpData.message ?? 'Đã gửi lại mã OTP thành công!');
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
