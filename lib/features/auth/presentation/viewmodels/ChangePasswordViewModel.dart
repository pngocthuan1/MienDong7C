import 'package:flutter/material.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  String? _message;
  String? _currentPasswordServerError;
  late final Command<String> changePasswordCommand;

  ChangePasswordViewModel(this._authRepository) {
    changePasswordCommand = Command<String>(_changePassword);
  }

  String? get message => _message;
  String? get currentPasswordServerError => _currentPasswordServerError;

  String? checkCurrentPassword(String? value) {
    if (_currentPasswordServerError != null) {
      return _currentPasswordServerError;
    }
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    if (value.trim().length < 6) {
      return 'Mật khẩu hiện tại phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? checkNewPassword(String? value) {
    final clean = value ?? '';
    if (clean.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    final validation = Validators.validatePassword(clean);
    if (validation != null) return validation;

    if (currentPasswordController.text.isNotEmpty && clean == currentPasswordController.text) {
      return 'Mật khẩu mới không được trùng với mật khẩu hiện tại';
    }
    return null;
  }

  String? checkConfirmNewPassword(String? value) {
    final clean = value ?? '';
    if (clean.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu mới';
    }
    if (clean != newPasswordController.text) {
      return 'Mật khẩu nhập lại chưa trùng khớp với mật khẩu mới';
    }
    return null;
  }

  void onPasswordChanged() {
    if (_currentPasswordServerError != null) {
      _currentPasswordServerError = null;
    }
    notifyListeners();
  }

  void updateCurrentPasswordError(String? val) {
    if (_currentPasswordServerError != null) {
      _currentPasswordServerError = null;
    }
    if (_message != null) {
      _message = null;
    }
    notifyListeners();
  }

  void updateConfirmNewPasswordError(String? val) {
    if (_message != null) {
      _message = null;
    }
    notifyListeners();
  }

  Future<ApiResult<String>> _changePassword() async {
    _message = null;
    _currentPasswordServerError = null;
    notifyListeners();

    final currentPw = currentPasswordController.text;
    final newPw = newPasswordController.text;
    final confirmNewPw = confirmNewPasswordController.text;

    final errCurrent = checkCurrentPassword(currentPw);
    if (errCurrent != null) {
      _message = errCurrent;
      notifyListeners();
      return ApiFailure(ApiException.validation(errCurrent));
    }

    final errNew = checkNewPassword(newPw);
    if (errNew != null) {
      _message = errNew;
      notifyListeners();
      return ApiFailure(ApiException.validation(errNew));
    }

    final errConfirm = checkConfirmNewPassword(confirmNewPw);
    if (errConfirm != null) {
      _message = errConfirm;
      notifyListeners();
      return ApiFailure(ApiException.validation(errConfirm));
    }

    final res = await _authRepository.changePassword(currentPw, newPw, confirmNewPw);
    if (res is ApiFailure<bool>) {
      final errMsg = res.exception.message;
      if (errMsg.toLowerCase().contains('hiện tại') || errMsg.toLowerCase().contains('không đúng') || errMsg.toLowerCase().contains('mật khẩu cũ')) {
        _currentPasswordServerError = 'Mật khẩu hiện tại không đúng. Vui lòng kiểm tra lại';
      } else {
        _message = errMsg;
      }
      notifyListeners();
      return ApiFailure(res.exception);
    }

    final isSuccess = (res as ApiSuccess<bool>).data;
    if (!isSuccess) {
      _message = 'Đổi mật khẩu không thành công. Vui lòng kiểm tra lại mật khẩu hiện tại';
      notifyListeners();
      return ApiFailure(ApiException.validation(_message!));
    }

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
