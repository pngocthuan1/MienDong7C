import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/network/NetworkInfoResult.dart';
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
  Timer? _connectivityDebounceTimer;

  // Cache kiểm tra mạng nội bộ thông minh:
  // Chỉ dùng lại kết quả nếu chưa quá 10 giây VÀ giữ nguyên Wi-Fi SSID.
  // Khi người dùng đổi mạng (onConnectivityChanged), cache bị hủy lập tức!
  NetworkAuthResult? _cachedAuthResult;
  DateTime? _lastCheckTime;
  String? _cachedSsid;

  void startListeningNetworkChanges() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (kDebugMode) {
        debugPrint(
          '[LoginViewModel] Connectivity changed: $results -> HỦY CACHE mạng & debounce re-check',
        );
      }
      // HỦY CACHE LẬP TỨC: Đảm bảo không dùng lại quyền truy cập mạng cũ khi đã ngắt/đổi mạng
      _cachedAuthResult = null;
      _lastCheckTime = null;
      _cachedSsid = null;

      _connectivityDebounceTimer?.cancel();
      _connectivityDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        initNetworkCheck(force: true);
      });
    });
  }

  final NetworkInfoService _networkInfoService = NetworkInfoService();
  late final NetworkAuthService _networkAuthService = NetworkAuthService(
    AppLocator.dioClient,
  );

  LoginViewModel(this._authRepository, this._secureStorage);

  Future<NetworkAuthResult> checkOrGetNetworkAuth({bool force = false}) async {
    final info = await _networkInfoService.collectNetworkInfo();
    final currentSsid = info.ssid;
    final now = DateTime.now();

    final isCacheValid =
        !force &&
        _cachedAuthResult != null &&
        _lastCheckTime != null &&
        now.difference(_lastCheckTime!) < const Duration(seconds: 10) &&
        _cachedSsid == currentSsid;

    if (isCacheValid) {
      if (kDebugMode) {
        debugPrint(
          '[LoginViewModel] Sử dụng cache kiểm tra mạng (SSID: "$currentSsid")',
        );
      }
      return _cachedAuthResult!;
    }

    if (kDebugMode) {
      debugPrint(
        '[LoginViewModel] Gọi checkInternalNetwork mới (SSID: "$currentSsid")...',
      );
    }

    final authResult = await _networkAuthService.checkInternalNetwork(info);
    _cachedAuthResult = authResult;
    _lastCheckTime = now;
    _cachedSsid = currentSsid;

    if (kDebugMode) {
      debugPrint(
        '[LoginViewModel] CheckInternalNetwork allowEmployeeRole: ${authResult.allowEmployeeRole}',
      );
    }

    return authResult;
  }

  Future<void> initNetworkCheck({bool force = true}) async {
    isCheckingNetwork = true;
    notifyListeners();
    try {
      final authResult = await checkOrGetNetworkAuth(force: force);
      allowEmployeeRole = authResult.allowEmployeeRole;
      if (!allowEmployeeRole) {
        _selectedRole = UserRole.customer;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoginViewModel] Error in initNetworkCheck: $e');
      }
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

    // Nếu chọn vai trò Nhân viên -> Re-check mạng (khớp SSID và <10s thì dùng cache, khác SSID thì check mới)
    if (_selectedRole == UserRole.employee) {
      final authResult = await checkOrGetNetworkAuth(force: false);
      if (!authResult.allowEmployeeRole) {
        allowEmployeeRole = false;
        _selectedRole = UserRole.customer;
        _message =
            'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException(
            'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!',
          ),
        );
      }
    }

    final phoneVal = phoneController.text.trim();
    final passwordVal = passwordController.text;

    // Chế độ Server Thật -> Kiểm tra CAPTCHA nếu có trước khi gọi Backend API
    if (captchaToken != null && captchaToken!.isNotEmpty) {
      final verifyRes = await AppLocator.turnstileService.verifyToken(
        captchaToken!,
      );
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
      password: Environment.appClientSecret,
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

    final boundRoleKey = cleanPhone.isNotEmpty
        ? cleanPhone
        : phoneVal.trim().toLowerCase();
    final isRegisteredMobileCustomer =
        prefs.getString('account_role_$boundRoleKey') == 'customer';

    if (_selectedRole == UserRole.employee) {
      if (isRegisteredMobileCustomer) {
        _message =
            'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException('Đăng nhập thất bại.', statusCode: 403),
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
          _message =
              'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
          notifyListeners();
          return ApiFailure(
            ForbiddenException('Đăng nhập thất bại.', statusCode: 403),
          );
        }
      } else {
        _message =
            'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
        notifyListeners();
        return ApiFailure(
          ForbiddenException('Đăng nhập thất bại.', statusCode: 403),
        );
      }
    } else {
      // Đăng nhập vai trò Bệnh nhân / Khách hàng (UserRole.customer)
      // inconsistency nếu server trả về khác nhau giữa các lần gọi).
      final looksLikeEmployeeUsername =
          RegExp(r'[a-zA-Z]').hasMatch(phoneVal.trim()) ||
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
        _message =
            'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập!';
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
        String? perAccountName;
        if (cleanPhone.isNotEmpty) {
          perAccountName =
              await _secureStorage.getFullNameForPhone(cleanPhone) ??
              prefs.getString('full_name_$cleanPhone');
        }
        if (perAccountName != null &&
            perAccountName.trim().isNotEmpty &&
            perAccountName.trim() != phoneVal.trim()) {
          userFullName = perAccountName.trim();
        } else {
          final jsonStr = prefs.getString(
            'saved_my_personal_profile_$phoneVal',
          );
          String? profileName;
          if (jsonStr != null && jsonStr.isNotEmpty) {
            try {
              final draftMap = jsonDecode(jsonStr) as Map<String, dynamic>;
              profileName = draftMap['fullName'] as String?;
            } catch (_) {}
          }
          if (profileName != null && profileName.trim().isNotEmpty) {
            userFullName = profileName.trim();
          } else {
            userFullName = phoneVal.trim().isNotEmpty
                ? 'Tài khoản ${phoneVal.trim()}'
                : 'Khách hàng';
          }
        }
      }

      userRole = UserRole.customer;
      await prefs.setString('account_role_$boundRoleKey', 'customer');
    }

    _message = null;
    await _secureStorage.saveTokensRecord(
      session.accessToken,
      session.refreshToken,
    );
    await _secureStorage.saveExpiresRefreshToken(
      (session.refreshTokenExpiry?.millisecondsSinceEpoch ?? 0).toString(),
    );

    await _secureStorage.saveSavedPhone(phoneVal);
    await _secureStorage.saveSavedRole(
      userRole == UserRole.employee ? 'employee' : 'customer',
    );
    await _secureStorage.saveSavedFullName(userFullName);

    if (cleanPhone.isNotEmpty) {
      await _secureStorage.saveFullNameForPhone(cleanPhone, userFullName);
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
    _connectivityDebounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    phoneController.dispose();
    passwordController.dispose();
    loginCommand.dispose();
    super.dispose();
  }
}
