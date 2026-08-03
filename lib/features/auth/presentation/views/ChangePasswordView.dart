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
import 'package:benhvien7c/features/auth/presentation/widgets/AuthHeader.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/PasswordRuleBox.dart';

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
      success: (message) async {
        _viewModel.changePasswordCommand.clearResult();
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Đổi mật khẩu thành công'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    AppNavigator.resetToNamed(context, RouteNames.login);
                  },
                  child: const Text('Về đăng nhập'),
                ),
              ],
            );
          },
        );
      },
      failure: (_) {
        _viewModel.changePasswordCommand.clearResult();
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
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Đổi mật khẩu tài khoản',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vui lòng nhập mật khẩu hiện tại và thiết lập mật khẩu mới cho tài khoản của bạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.sectionSpacing),
                    AppPasswordField(
                      controller: _viewModel.currentPasswordController,
                      label: 'Mật khẩu hiện tại',
                      hintText: 'Nhập mật khẩu hiện tại',
                      validator: _viewModel.checkCurrentPassword,
                      textInputAction: TextInputAction.next,
                      onChanged: _viewModel.updateCurrentPasswordError,
                    ),
                    const SizedBox(height: AppSizes.itemSpacing),
                    AppPasswordField(
                      controller: _viewModel.newPasswordController,
                      focusNode: _newPasswordFocusNode,
                      label: 'Mật khẩu mới',
                      hintText: 'Tạo mật khẩu mới',
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
                      hintText: 'Nhập lại mật khẩu mới để xác nhận',
                      validator: _viewModel.checkConfirmNewPassword,
                      textInputAction: TextInputAction.done,
                      onChanged: _viewModel.updateConfirmNewPasswordError,
                    ),
                    if (_viewModel.message != null) ...[
                      const SizedBox(height: AppSizes.itemSpacing),
                      AuthFeedbackBanner(message: _viewModel.message!),
                    ],
                    const SizedBox(height: AppSizes.sectionSpacing),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: ListenableBuilder(
                          listenable: _viewModel.changePasswordCommand,
                          builder: (context, _) {
                            return AppButton(
                              label: 'Cập nhật mật khẩu',
                              icon: Icons.check_circle_outline,
                              isLoading: _viewModel.changePasswordCommand.running,
                              onPressed: _submit,
                            );
                          },
                        ),
                      ),
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
