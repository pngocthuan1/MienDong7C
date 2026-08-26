import 'package:flutter/material.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/LoginParams.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';

import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/services/TurnstileVerifyService.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserProfileEntity.dart';

/// Lớp phụ trợ Command hỗ trợ quản lý trạng thái tải (loading) và kết quả thực thi
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
    } catch (_) {
      // ApiResult đã bọc sẵn lỗi trong repository
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

class LoginState {
  // Giữ lớp này để tránh lỗi tương thích nếu có import/tham chiếu ngoài dự kiến
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
}

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  String? _message;
  UserRole _selectedRole = UserRole.customer;
  UserRole get selectedRole => _selectedRole;

  LoginViewModel(this._authRepository, this._secureStorage);

  void updateRole(UserRole role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    _message = null;
    notifyListeners();
  }

  String? get message => _message;

  String? checkPhone(String? value) {
    return Validators.validatePhone(value);
  }

  String? checkPassword(String? value) {
    return Validators.validatePassword(value);
  }

  void updatePhoneError(String? value) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  void updatePasswordError(String? value) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  String? captchaToken;

  late final loginCommand = Command<AuthSessionEntity>(() async {
    _message = null;
    notifyListeners();

    final phoneVal = phoneController.text.trim();
    final passwordVal = passwordController.text;

    // Chế độ Server Thật -> Kiểm tra CAPTCHA nếu có trước khi gọi Backend API
    if (captchaToken != null && captchaToken!.isNotEmpty) {
      final verifyRes = await AppLocator.turnstileService.verifyToken(captchaToken!);
      if (verifyRes is ApiFailure<TurnstileVerifyResult>) {
        _message = 'Xác thực CAPTCHA thất bại hoặc nghi ngờ Spam Bot.';
        notifyListeners();
        return ApiFailure(verifyRes.exception);
      }
    }

    final deviceId = await _secureStorage.getOrCreateDeviceId();

    final params = LoginParams(
      tenDangNhapHis: phoneVal,
      matKhauHis: passwordVal,
      username: 'mobile',
      password: '1@QWEqaz23456',
      device: deviceId,
      platform: Environment.platform,
      version: Environment.appVersion,
      captchaToken: captchaToken,
    );

    // Bước 1: Lấy Token xác thực thiết bị & ứng dụng từ /api/Token/Login
    final tokenResult = await _authRepository.login(params);

    if (tokenResult is ApiFailure<AuthSessionEntity>) {
      final exc = tokenResult.exception;
      _message = exc.message;
      notifyListeners();
      return tokenResult;
    }

    final session = (tokenResult as ApiSuccess<AuthSessionEntity>).data;

    String userFullName = 'Khách Hàng';
    UserRole userRole = UserRole.customer;

    final prefs = await SharedPreferences.getInstance();
    final cleanPhone = phoneVal.replaceAll(RegExp(r'\D'), '');
    var savedName = prefs.getString('full_name_$cleanPhone') ?? prefs.getString('saved_full_name');

    final boundRoleKey = cleanPhone.isNotEmpty ? cleanPhone : phoneVal.trim().toLowerCase();
    final registeredPhones = (prefs.getStringList('registered_phone_numbers') ?? ['0822380103', '0902377251', '0987654321'])
        .map((e) => e.replaceAll(RegExp(r'\D'), '')).toSet();

    final isRegisteredMobileCustomer = (cleanPhone.isNotEmpty && registeredPhones.contains(cleanPhone)) ||
        prefs.getString('account_role_$boundRoleKey') == 'customer';

    if (_selectedRole == UserRole.employee) {
      if (isRegisteredMobileCustomer) {
        _message = 'Tài khoản "$phoneVal" là tài khoản Bệnh nhân / Khách hàng đăng ký trên app. Không thể đăng nhập vai trò Bác sĩ / Nhân viên!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException(
            'Tài khoản Khách hàng không có quyền đăng nhập vai trò Bác sĩ / Nhân viên.',
            statusCode: 403,
          ),
        );
      }

      final hisResult = await _authRepository.loginHis(phoneVal, passwordVal);
      if (hisResult is ApiSuccess<UserProfileEntity>) {
        final profile = hisResult.data;
        if (profile.tenDangNhapHis.isNotEmpty || profile.hoTenHis.isNotEmpty) {
          userFullName = profile.hoTenHis.isNotEmpty
              ? profile.hoTenHis
              : profile.tenDangNhapHis;
          userRole = UserRole.employee;
          await prefs.setString('account_role_$boundRoleKey', 'employee');
        } else {
          _message = 'Tài khoản không có quyền đăng nhập với vai trò Bác sĩ / Nhân viên. Vui lòng chọn vai trò Bệnh nhân / Khách hàng!';
          notifyListeners();
          return ApiFailure(
            ForbiddenException(
              'Tài khoản không có quyền đăng nhập với vai trò Bác sĩ / Nhân viên.',
              statusCode: 403,
            ),
          );
        }
      } else {
        _message = 'Tài khoản hoặc mật khẩu Bác sĩ / Nhân viên không chính xác!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException(
            'Đăng nhập Bác sĩ / Nhân viên thất bại.',
            statusCode: 403,
          ),
        );
      }
    } else {
      // Đăng nhập vai trò Bệnh nhân / Khách hàng (UserRole.customer)
      final isEmployeeUsername = RegExp(r'[a-zA-Z]').hasMatch(phoneVal.trim()) ||
          prefs.getString('account_role_$boundRoleKey') == 'employee';

      if (isEmployeeUsername) {
        final hisCheck = await _authRepository.loginHis(phoneVal, passwordVal);
        if (hisCheck is ApiSuccess<UserProfileEntity>) {
          await prefs.setString('account_role_$boundRoleKey', 'employee');
          _message = 'Tài khoản "$phoneVal" là tài khoản Bác sĩ / Nhân viên cấp sẵn. Vui lòng chuyển sang vai trò Bác sĩ / Nhân viên để đăng nhập!';
          notifyListeners();
          return ApiFailure(
            ForbiddenException(
              'Tài khoản Bác sĩ / Nhân viên phải chọn vai trò Bác sĩ / Nhân viên.',
              statusCode: 403,
            ),
          );
        }
      }

      // 1. Ưu tiên lấy Họ và tên chính thức từ Server HIS (ví dụ: Phạm Ngọc Thuân cho 0707587641)
      try {
        final hisCheck = await _authRepository.loginHis(phoneVal, passwordVal);
        if (hisCheck is ApiSuccess<UserProfileEntity> && hisCheck.data.hoTenHis.trim().isNotEmpty) {
          userFullName = hisCheck.data.hoTenHis.trim();
        }
      } catch (_) {}

      // 2. Nếu server không trả về HoTenHis, lấy tên đã đăng ký riêng của SĐT này (không dùng chung saved_full_name toàn cục)
      if (userFullName == 'Khách Hàng' || userFullName.isEmpty) {
        final perAccountName = cleanPhone.isNotEmpty ? prefs.getString('full_name_$cleanPhone') : null;
        if (perAccountName != null && perAccountName.trim().isNotEmpty && perAccountName.trim() != phoneVal.trim()) {
          userFullName = perAccountName.trim();
        } else {
          userFullName = phoneVal.trim().isNotEmpty ? 'Tài khoản ${phoneVal.trim()}' : 'Khách hàng';
        }
      }

      userRole = UserRole.customer;
      await prefs.setString('account_role_$boundRoleKey', 'customer');
    }

    _message = null;
    await _secureStorage.saveTokensRecord(session.accessToken, session.refreshToken);
    await _secureStorage.saveExpiresRefreshToken(session.refreshTokenExpiry.millisecondsSinceEpoch.toString());

    final prefsObj = await SharedPreferences.getInstance();
    prefsObj.setString('saved_phone', phoneVal);
    prefsObj.setString('saved_role', userRole == UserRole.employee ? 'employee' : 'customer');
    prefsObj.setString('saved_full_name', userFullName);
    if (cleanPhone.isNotEmpty) {
      prefsObj.setString('full_name_$cleanPhone', userFullName);
    }

    AppSessionStore.instance.setSession(
      session,
      UserProfileSession(
        fullName: userFullName,
        phoneNumber: phoneVal,
        role: userRole,
      ),
    );
    notifyListeners();
    return tokenResult;
  });

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    loginCommand.dispose();
    super.dispose();
  }
}
