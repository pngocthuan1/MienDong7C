import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/core/widgets/AppPasswordField.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/ResetPasswordViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCardShell.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFeedbackBanner.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFooterLink.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthGradientBackground.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/PasswordRuleBox.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/PasswordMatchIndicator.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({required this.args, super.key});

  final ResetPasswordViewArgs args;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final ResetPasswordViewModel _viewModel;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _viewModel = ResetPasswordViewModel(
      AppLocator.authRepository,
      phoneNumber: widget.args.phoneNumber,
      otpCode: widget.args.otpCode,
      key: widget.args.key,
      adjustSeconds: widget.args.adjustSeconds,
    );
    _passwordFocusNode = FocusNode()..addListener(_onPasswordFocusChanged);
    _viewModel.resetPasswordCommand.addListener(_onResetChanged);
  }

  @override
  void dispose() {
    _passwordFocusNode
      ..removeListener(_onPasswordFocusChanged)
      ..dispose();
    _viewModel.resetPasswordCommand.removeListener(_onResetChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onPasswordFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onResetChanged() {
    if (_viewModel.resetPasswordCommand.running) return;

    final result = _viewModel.resetPasswordCommand.result;
    if (result == null || !mounted) return;

    result.when(
      success: (message) {
        _viewModel.resetPasswordCommand.clearResult();
        _showSuccessDialog(message);
      },
      failure: (_) {
        _viewModel.resetPasswordCommand.clearResult();
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
                  message.isNotEmpty ? message : 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập với mật khẩu mới.',
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
      await _viewModel.resetPasswordCommand.execute();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientBackground(
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0FDF4),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFF16A34A),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tạo mật khẩu mới',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A),
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mã OTP đã được xác minh. Vui lòng nhập mật khẩu mới cho tài khoản của bạn.',
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
                    controller: _viewModel.passwordController,
                    focusNode: _passwordFocusNode,
                    label: 'Mật khẩu mới',
                    hintText: 'Mật khẩu mới',
                    validator: _viewModel.checkPassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _viewModel.onPasswordChanged(),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _passwordFocusNode.hasFocus
                        ? Padding(
                            key: const ValueKey('reset-password-rules'),
                            padding: const EdgeInsets.only(top: AppSizes.compactSpacing),
                            child: PasswordRuleBox(
                              password: _viewModel.passwordController.text,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('reset-password-rules-hidden')),
                  ),
                  const SizedBox(height: AppSizes.itemSpacing),
                  AppPasswordField(
                    controller: _viewModel.confirmPasswordController,
                    label: 'Nhập lại mật khẩu mới',
                    hintText: 'Nhập lại mật khẩu mới',
                    prefixIcon: Icons.check_circle_outline,
                    validator: _viewModel.checkConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onChanged: _viewModel.updateConfirmPasswordError,
                  ),
                  PasswordMatchIndicator(
                    password: _viewModel.passwordController.text,
                    confirmPassword: _viewModel.confirmPasswordController.text,
                  ),
                  if (_viewModel.message != null) ...[
                    const SizedBox(height: AppSizes.itemSpacing),
                    AuthFeedbackBanner(message: _viewModel.message!),
                  ],
                  const SizedBox(height: AppSizes.sectionSpacing),
                  ListenableBuilder(
                    listenable: _viewModel.resetPasswordCommand,
                    builder: (context, _) {
                      return AppButton(
                        label: 'Xác nhận & Đăng nhập',
                        icon: Icons.assignment_turned_in_outlined,
                        isLoading: _viewModel.resetPasswordCommand.running,
                        onPressed: _submit,
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.sectionSpacing),
                  AuthFooterLink(
                    label: 'Nhớ lại mật khẩu?',
                    actionLabel: 'Quay về đăng nhập',
                    onTap: () {
                      AppNavigator.resetToNamed(context, RouteNames.login);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
