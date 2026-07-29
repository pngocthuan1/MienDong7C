import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  String? _message;
  late final Command<String> changePasswordCommand;

  ChangePasswordViewModel(this._authRepository) {
    changePasswordCommand = Command<String>(_changePassword);
  }

  String? get message => _message;

  String? checkCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    return null;
  }

  String? checkNewPassword(String? value) {
    final validation = Validators.validatePassword(value);
    if (validation != null) return validation;
    if (value == currentPasswordController.text) {
      return 'Mật khẩu mới không được trùng với mật khẩu hiện tại';
    }
    return null;
  }

  String? checkConfirmNewPassword(String? value) {
    if (value != newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp với mật khẩu mới';
    }
    return null;
  }

  void onPasswordChanged() {
    notifyListeners();
  }

  void updateCurrentPasswordError(String? val) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  void updateConfirmNewPasswordError(String? val) {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  Future<ApiResult<String>> _changePassword() async {
    // ignore: unused_local_variable
    final repo = _authRepository;
    await Future.delayed(const Duration(seconds: 1));
    return const ApiSuccess('Đổi mật khẩu thành công! Vui lòng đăng nhập lại với mật khẩu mới.');
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }
}
