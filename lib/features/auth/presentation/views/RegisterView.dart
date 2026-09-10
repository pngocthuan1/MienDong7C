import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/utils/AppInputFormatters.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/core/widgets/AppPasswordField.dart';
import 'package:benhvien7c/core/widgets/AppTextField.dart';
import 'package:benhvien7c/core/widgets/CloudflareTurnstile.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/RegisterViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCardShell.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFeedbackBanner.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFooterLink.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthGradientBackground.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/PasswordRuleBox.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  late final RegisterViewModel _viewModel;
  late final FocusNode _passwordFocusNode;
  String? _captchaToken;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel(AppLocator.authRepository);
    _passwordFocusNode = FocusNode()..addListener(_onPasswordFocusChanged);
    _viewModel.registerCommand.addListener(_onRegisterChanged);
  }

  @override
  void dispose() {
    _passwordFocusNode
      ..removeListener(_onPasswordFocusChanged)
      ..dispose();
    _viewModel.registerCommand.removeListener(_onRegisterChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onPasswordFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _onRegisterChanged() {
    if (_viewModel.registerCommand.running) {
      return;
    }

    final result = _viewModel.registerCommand.result;
    if (result == null || !mounted) {
      return;
    }

    result.when(
      success: (message) async {
        _viewModel.registerCommand.clearResult();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        AppNavigator.pushNamed(
          context,
          RouteNames.verifyOtp,
          arguments: OtpViewArgs(
            phoneNumber: _viewModel.phoneController.text.trim(),
            purpose: OtpPurpose.registration,
            fullName: _viewModel.fullNameController.text.trim(),
            password: _viewModel.passwordController.text,
            key: _viewModel.otpKey,
            adjustSeconds: _viewModel.adjustSeconds,
            remainingSeconds: _viewModel.remainingSeconds,
          ),
        );
      },
      failure: (_) {
        _viewModel.registerCommand.clearResult();
      },
    );
  }

  Future<void> _submit() async {
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) {
        return;
      }
      await _viewModel.registerCommand.execute();
      if (_viewModel.phoneError != null) {
        _formKey.currentState!.validate();
      }
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
                  // 1. Số điện thoại (Đứng đầu tiên)
                  AppTextField(
                    controller: _viewModel.phoneController,
                    label: 'Số điện thoại',
                    hintText: 'Số điện thoại đăng ký',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    inputFormatters: AppInputFormatters.phoneNumber,
                    validator: _viewModel.checkPhone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textInputAction: TextInputAction.next,
                    onChanged: _viewModel.updatePhoneError,
                  ),
                  const SizedBox(height: AppSizes.itemSpacing),

                  // 2. Mật khẩu
                  AppPasswordField(
                    controller: _viewModel.passwordController,
                    focusNode: _passwordFocusNode,
                    label: 'Mật khẩu',
                    hintText: 'Tạo mật khẩu mới',
                    validator: _viewModel.checkPassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _viewModel.onPasswordChanged(),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _passwordFocusNode.hasFocus
                        ? Padding(
                            key: const ValueKey('register-password-rules'),
                            padding: const EdgeInsets.only(
                              top: AppSizes.compactSpacing,
                            ),
                            child: PasswordRuleBox(
                              password: _viewModel.passwordController.text,
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('register-password-rules-hidden'),
                          ),
                  ),
                  const SizedBox(height: AppSizes.itemSpacing),

                  // 3. Nhập lại mật khẩu
                  AppPasswordField(
                    controller: _viewModel.confirmPasswordController,
                    label: 'Nhập lại mật khẩu',
                    hintText: 'Nhập lại để xác nhận',
                    validator: _viewModel.checkConfirmPassword,
                    textInputAction: TextInputAction.next,
                    onChanged: _viewModel.updateConfirmPasswordError,
                  ),
                  const SizedBox(height: AppSizes.itemSpacing),

                  // 4. Họ và tên (Dưới cùng)
                  AppTextField(
                    controller: _viewModel.fullNameController,
                    label: 'Họ và tên',
                    hintText: 'Nhập họ tên đầy đủ',
                    prefixIcon: Icons.badge_outlined,
                    validator: _viewModel.checkFullName,
                    textInputAction: TextInputAction.done,
                    onChanged: _viewModel.updateFullNameError,
                  ),
                  if (_viewModel.message != null) ...[
                    const SizedBox(height: AppSizes.itemSpacing),
                    AuthFeedbackBanner(message: _viewModel.message!),
                  ],
                  const SizedBox(height: AppSizes.itemSpacing),
                  CloudflareTurnstile(
                    siteKey: Environment.turnstileSiteKey,
                    onVerified: (token) {
                      setState(() {
                        _captchaToken = token;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: (val) {
                            setState(() {
                              _agreeToTerms = val ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: 'Tôi đồng ý với '),
                              TextSpan(
                                text: 'Điều khoản sử dụng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const TextSpan(text: ' và '),
                              TextSpan(
                                text: 'Chính sách bảo vệ dữ liệu cá nhân',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const TextSpan(text: ' của Bệnh viện.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sectionSpacing),
                  ListenableBuilder(
                    listenable: _viewModel.registerCommand,
                    builder: (context, _) {
                      final isCaptchaVerified = _captchaToken != null || Environment.isDevelopment;
                      return AppButton(
                        label: 'Đăng ký',
                        icon: Icons.verified_user_outlined,
                        isLoading: _viewModel.registerCommand.running,
                        onPressed: (isCaptchaVerified && _agreeToTerms) ? _submit : null,
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.sectionSpacing),
                  AuthFooterLink(
                    label: 'Đã có tài khoản?',
                    actionLabel: 'Đăng nhập',
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
