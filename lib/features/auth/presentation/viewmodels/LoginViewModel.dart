
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
import 'package:benhvien7c/features/auth/domain/entities/UserProfileEntity.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:benhvien7c/core/network/NetworkInfoService.dart';
import 'package:benhvien7c/features/auth/presentation/services/NetworkAuthService.dart';

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
    } catch (e, stackTrace) {
      debugPrint('[Command] Unhandled error during execute(): $e');
      debugPrintStack(stackTrace: stackTrace);
      _result = ApiFailure(
        UnknownException('Đã xảy ra lỗi không xác định. Vui lòng thử lại.'),
      );
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

  bool isCheckingNetwork = false;
  bool allowEmployeeRole = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void startListeningNetworkChanges() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      debugPrint('[LoginViewModel] Network connectivity changed: $results -> Auto re-checking network!');
      initNetworkCheck();
    });
  }
  final NetworkInfoService _networkInfoService = NetworkInfoService();
  late final NetworkAuthService _networkAuthService = NetworkAuthService(AppLocator.dioClient);

  LoginViewModel(this._authRepository, this._secureStorage);

  Future<void> initNetworkCheck() async {
    isCheckingNetwork = true;
    notifyListeners();
    try {
      final info = await _networkInfoService.collectNetworkInfo();
      debugPrint('[LoginViewModel] Wi-Fi SSID fetched: "${info.ssid}"');
      final authResult = await _networkAuthService.checkInternalNetwork(info);
      debugPrint('[LoginViewModel] CheckInternalNetwork allowEmployeeRole: ${authResult.allowEmployeeRole}');
      allowEmployeeRole = authResult.allowEmployeeRole;
      if (!allowEmployeeRole) {
        _selectedRole = UserRole.customer;
      }
    } catch (e) {
      debugPrint('[LoginViewModel] Error in initNetworkCheck: $e');
      allowEmployeeRole = false;
      _selectedRole = UserRole.customer;
    } finally {
      isCheckingNetwork = false;
      notifyListeners();
    }
  }

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
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    return null;
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

    // Nếu chọn vai trò Nhân viên -> Re-check mạng ngay thời điểm bấm Đăng nhập!
    if (_selectedRole == UserRole.employee) {
      final info = await _networkInfoService.collectNetworkInfo();
      final authResult = await _networkAuthService.checkInternalNetwork(info);
      if (!authResult.allowEmployeeRole) {
        allowEmployeeRole = false;
        _selectedRole = UserRole.customer;
        _message = 'Tài khoản Nhân viên chỉ được phép đăng nhập khi kết nối Mạng Nội bộ Bệnh viện hoặc VPN!';
        notifyListeners();
        return ApiFailure(ForbiddenException('Chỉ được phép đăng nhập tài khoản Nhân viên từ Mạng Nội bộ Bệnh viện hoặc VPN.'));
      }
    }

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
    final isRegisteredMobileCustomer = prefs.getString('account_role_$boundRoleKey') == 'customer';

    if (_selectedRole == UserRole.employee) {
      if (isRegisteredMobileCustomer) {
        _message = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException(
            'Đăng nhập thất bại.',
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
          _message = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
          notifyListeners();
          return ApiFailure(
            ForbiddenException('Đăng nhập thất bại.', statusCode: 403),
          );
        }
      } else {
        _message = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException('Đăng nhập thất bại.', statusCode: 403),
        );
      }
    } else {
      // Đăng nhập vai trò Bệnh nhân / Khách hàng (UserRole.customer)
      // inconsistency nếu server trả về khác nhau giữa các lần gọi).
      final looksLikeEmployeeUsername = RegExp(r'[a-zA-Z]').hasMatch(phoneVal.trim()) ||
          prefs.getString('account_role_$boundRoleKey') == 'employee';

      UserProfileEntity? hisProfile;
      try {
        final hisCheck = await _authRepository.loginHis(phoneVal, passwordVal);
        if (hisCheck is ApiSuccess<UserProfileEntity>) {
          hisProfile = hisCheck.data;
        }
      } catch (e) {
        // Không chặn luồng login customer nếu server HIS lỗi/không phản hồi,
        // nhưng vẫn log lại để theo dõi thay vì nuốt im lặng.
        debugPrint('[LoginViewModel] loginHis lookup failed: $e');
      }

      // Nếu username có dạng chữ (giống tài khoản nhân viên) và server HIS
      // xác nhận đăng nhập thành công -> đây thực chất là tài khoản nhân viên,
      // không cho đăng nhập với vai trò Khách hàng.
      if (looksLikeEmployeeUsername && hisProfile != null) {
        await prefs.setString('account_role_$boundRoleKey', 'employee');
        _message = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException('Đăng nhập thất bại.', statusCode: 403),
        );
      }

      // Ưu tiên lấy Họ và tên chính thức từ Server HIS (ví dụ: Phạm Ngọc Thuân cho 0707587641)
      if (hisProfile != null && hisProfile.hoTenHis.trim().isNotEmpty) {
        userFullName = hisProfile.hoTenHis.trim();
      }

      // Nếu server không trả về HoTenHis, lấy tên đã đăng ký riêng của SĐT này
      // (không dùng chung saved_full_name toàn cục)
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
    _connectivitySubscription?.cancel();
    phoneController.dispose();
    passwordController.dispose();
    loginCommand.dispose();
    super.dispose();
  }
}
