import 'package:flutter/material.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/LoginParams.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/core/constants/AppStrings.dart';
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

  LoginViewModel(this._authRepository, this._secureStorage);

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

  bool _isOfflineDemo = false;
  bool get isOfflineDemo => _isOfflineDemo;

  void setOfflineDemo(bool val) {
    if (_isOfflineDemo == val) return;
    _isOfflineDemo = val;
    notifyListeners();
  }

  late final loginCommand = Command<AuthSessionEntity>(() async {
    _message = null;
    notifyListeners();

    final phoneVal = phoneController.text.trim();
    final passwordVal = passwordController.text;

    if (_isOfflineDemo) {
      // Chế độ Offline Demo -> Tạo session giả lập để test UI mượt mà không cần server
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final mockSession = AuthSessionEntity(
        accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
      );

      final role = phoneVal == AppStrings.demoEmployeePhone ? UserRole.employee : UserRole.customer;
      final fullName = role == UserRole.employee ? 'BS. Nguyễn Văn Nam (Demo)' : 'Nguyễn Văn Nam (Khách)';

      await _secureStorage.saveTokensRecord(mockSession.accessToken, mockSession.refreshToken);
      await _secureStorage.saveExpiresRefreshToken(mockSession.refreshTokenExpiry.millisecondsSinceEpoch.toString());

      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('saved_phone', phoneVal);
      });

      AppSessionStore.instance.setSession(
        mockSession,
        UserProfileSession(
          fullName: fullName,
          phoneNumber: phoneVal.isNotEmpty ? phoneVal : '0902377251',
          role: role,
        ),
      );

      _message = null;
      notifyListeners();
      return ApiSuccess(mockSession);
    }

    // Chế độ Server Thật -> Gọi API backend
    final deviceId = await _secureStorage.getOrCreateDeviceId();

    final params = LoginParams(
      tenDangNhapHis: phoneVal,
      matKhauHis: passwordVal,
      username: 'mobile',
      password: '1@QWEqaz23456',
      device: deviceId,
      platform: Environment.platform,
      version: Environment.appVersion,
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

    // Bước 2: Thử lấy thông tin hồ sơ HIS (nếu là tài khoản Bác sĩ / Nhân viên như 'hunglng')
    final hisResult = await _authRepository.loginHis(phoneVal, passwordVal);

    String userFullName = 'Khách Hàng';
    UserRole userRole = UserRole.customer;

    if (hisResult is ApiSuccess<UserProfileEntity>) {
      final profile = hisResult.data;
      userFullName = profile.hoTenHis.isNotEmpty
          ? profile.hoTenHis
          : (profile.tenDangNhapHis.isNotEmpty
              ? profile.tenDangNhapHis
              : 'Bác sĩ / Nhân viên');
      userRole = UserRole.employee;
    } else {
      // Nếu đăng nhập bằng SĐT bệnh nhân (không phải tài khoản HIS nhân viên)
      userFullName = phoneVal.isNotEmpty ? phoneVal : 'Khách Hàng';
      userRole = UserRole.customer;
    }

    _message = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('saved_phone', phoneVal);
    });
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
