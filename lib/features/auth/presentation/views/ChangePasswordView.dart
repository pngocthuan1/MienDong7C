import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/core/widgets/AppPasswordField.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/ChangePasswordViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCardShell.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFeedbackBanner.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthGradientBackground.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/PasswordRuleBox.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/PasswordMatchIndicator.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final ChangePasswordViewModel _viewModel;
  late final FocusNode _newPasswordFocusNode;

  @override
  void initState() {
    super.initState();
    _viewModel = ChangePasswordViewModel(AppLocator.authRepository);
    _newPasswordFocusNode = FocusNode()..addListener(_onNewPasswordFocusChanged);
    _viewModel.changePasswordCommand.addListener(_onChangePasswordResult);
  }

  @override
  void dispose() {
    _newPasswordFocusNode
      ..removeListener(_onNewPasswordFocusChanged)
      ..dispose();
    _viewModel.changePasswordCommand.removeListener(_onChangePasswordResult);
    _viewModel.dispose();
    super.dispose();
  }

  void _onNewPasswordFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onChangePasswordResult() {
    if (_viewModel.changePasswordCommand.running) return;

    final result = _viewModel.changePasswordCommand.result;
    if (result == null || !mounted) return;

    result.when(
      success: (message) {
        _viewModel.changePasswordCommand.clearResult();
        _showSuccessDialog(message);
      },
      failure: (_) {
        _viewModel.changePasswordCommand.clearResult();
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Thành công',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.isNotEmpty ? message : 'Mật khẩu của bạn đã được đổi thành công! Vui lòng đăng nhập lại.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      AppNavigator.resetToNamed(context, RouteNames.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Về trang đăng nhập',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) return;
      await _viewModel.changePasswordCommand.execute();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4B90E2),
        foregroundColor: Colors.white,
      ),
      body: AuthGradientBackground(
        child: AuthCardShell(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPasswordField(
                      controller: _viewModel.currentPasswordController,
                      label: 'Mật khẩu hiện tại',
                      hintText: 'Mật khẩu hiện tại',
                      validator: _viewModel.checkCurrentPassword,
                      textInputAction: TextInputAction.next,
                      onChanged: _viewModel.updateCurrentPasswordError,
                    ),
                    const SizedBox(height: AppSizes.itemSpacing),
                    AppPasswordField(
                      controller: _viewModel.newPasswordController,
                      focusNode: _newPasswordFocusNode,
                      label: 'Mật khẩu mới',
                      hintText: 'Mật khẩu mới',
                      validator: _viewModel.checkNewPassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _viewModel.onPasswordChanged(),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _newPasswordFocusNode.hasFocus
                          ? Padding(
                              key: const ValueKey('change-password-rules'),
                              padding: const EdgeInsets.only(top: AppSizes.compactSpacing),
                              child: PasswordRuleBox(
                                password: _viewModel.newPasswordController.text,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('change-password-rules-hidden')),
                    ),
                    const SizedBox(height: AppSizes.itemSpacing),
                    AppPasswordField(
                      controller: _viewModel.confirmNewPasswordController,
                      label: 'Nhập lại mật khẩu mới',
                      hintText: 'Nhập lại mật khẩu mới',
                      prefixIcon: Icons.check_circle_outline,
                      validator: _viewModel.checkConfirmNewPassword,
                      textInputAction: TextInputAction.done,
                      onChanged: _viewModel.updateConfirmNewPasswordError,
                    ),
                    PasswordMatchIndicator(
                      password: _viewModel.newPasswordController.text,
                      confirmPassword: _viewModel.confirmNewPasswordController.text,
                    ),
                    if (_viewModel.message != null) ...[
                      const SizedBox(height: AppSizes.itemSpacing),
                      AuthFeedbackBanner(message: _viewModel.message!),
                    ],
                    const SizedBox(height: AppSizes.sectionSpacing),
                    ListenableBuilder(
                      listenable: _viewModel.changePasswordCommand,
                      builder: (context, _) {
                        return AppButton(
                          label: 'Xác nhận & Đổi mật khẩu',
                          icon: Icons.assignment_turned_in_outlined,
                          isLoading: _viewModel.changePasswordCommand.running,
                          onPressed: _submit,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
