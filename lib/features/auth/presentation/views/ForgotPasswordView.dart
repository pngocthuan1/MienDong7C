import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/utils/AppInputFormatters.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/core/widgets/AppTextField.dart';
import 'package:benhvien7c/core/widgets/CloudflareTurnstile.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/ForgotPasswordViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCardShell.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFeedbackBanner.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFooterLink.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthGradientBackground.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/FirebaseRecaptchaHost.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final ForgotPasswordViewModel _viewModel;
  String? _captchaToken;
  int _captchaResetKey = 0;

  void _resetCaptcha() {
    if (!mounted) return;
    setState(() {
      _captchaToken = null;
      _captchaResetKey++;
    });
  }

  @override
  void initState() {
    super.initState();
    _viewModel = ForgotPasswordViewModel(AppLocator.authRepository);
    _viewModel.requestOtpCommand.addListener(_onOtpRequested);
  }

  @override
  void dispose() {
    _viewModel.requestOtpCommand.removeListener(_onOtpRequested);
    _viewModel.dispose();
    super.dispose();
  }

  void _onOtpRequested() {
    if (_viewModel.requestOtpCommand.running) {
      return;
    }

    final result = _viewModel.requestOtpCommand.result;
    if (result == null || !mounted) {
      return;
    }

    result.when(
      success: (message) {
        _viewModel.requestOtpCommand.clearResult();
        _resetCaptcha();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        AppNavigator.pushNamed(
          context,
          RouteNames.verifyOtp,
          arguments: OtpViewArgs(
            phoneNumber: _viewModel.phoneController.text.trim(),
            purpose: OtpPurpose.passwordReset,
            key: _viewModel.otpKey,
            adjustSeconds: _viewModel.adjustSeconds,
            remainingSeconds: _viewModel.remainingSeconds,
          ),
        );
      },
      failure: (_) {
        _viewModel.requestOtpCommand.clearResult();
        _resetCaptcha();
      },
    );
  }

  Future<void> _submit() async {
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) {
        return;
      }

      // ── Xác thực CAPTCHA duy nhất 1 lần tại thời điểm bấm Gửi mã OTP ──
      final isBypassedOnWeb = kIsWeb && Environment.disableTurnstileOnWeb;
      if (!isBypassedOnWeb) {
        if (_captchaToken == null || _captchaToken!.isEmpty) {
          _viewModel.message = 'Vui lòng hoàn thành xác thực CAPTCHA.';
          return;
        }

        final currentToken = _captchaToken!;
        _resetCaptcha(); // Xóa token lưu trữ và reset widget Captcha lập tức

        final verifyRes = await AppLocator.turnstileService.verifyToken(currentToken);
        if (verifyRes is ApiFailure) {
          _viewModel.message = 'Xác thực CAPTCHA thất bại hoặc nghi ngờ Spam Bot.';
          return;
        }
      }

      await _viewModel.requestOtpCommand.execute();
      if (_viewModel.phoneError != null) {
        _formKey.currentState!.validate();
      }
    } catch (_) {
      _resetCaptcha();
    }
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
                          Text(
                            'Quên mật khẩu',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nhập số điện thoại đã đăng ký. Hệ thống sẽ gửi OTP để bạn xác minh và tạo mật khẩu mới.',
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
                    const FirebaseRecaptchaHost(),
                    const SizedBox(height: AppSizes.itemSpacing),
                    AppTextField(
                      controller: _viewModel.phoneController,
                      label: 'Số điện thoại',
                      hintText: 'Nhập số điện thoại đã đăng ký',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_iphone,
                      inputFormatters: AppInputFormatters.phoneNumber,
                      validator: _viewModel.checkPhone,
                      textInputAction: TextInputAction.done,
                      onChanged: _viewModel.updatePhoneError,
                    ),
                    if (_viewModel.message != null) ...[
                      const SizedBox(height: AppSizes.itemSpacing),
                      AuthFeedbackBanner(message: _viewModel.message!),
                    ],
                    if (!(kIsWeb && Environment.disableTurnstileOnWeb)) ...[
                      const SizedBox(height: AppSizes.itemSpacing),
                      CloudflareTurnstile(
                        key: ValueKey('turnstile_forgot_$_captchaResetKey'),
                        onVerified: (token) {
                          setState(() {
                            _captchaToken = token;
                          });
                        },
                        onExpired: () {
                          _resetCaptcha();
                        },
                      ),
                    ],
                    const SizedBox(height: AppSizes.sectionSpacing),
                    ListenableBuilder(
                      listenable: _viewModel.requestOtpCommand,
                      builder: (context, _) {
                        final isCaptchaVerified =
                            (kIsWeb && Environment.disableTurnstileOnWeb) ||
                            _captchaToken != null;
                        return AppButton(
                          label: 'Gửi mã OTP',
                          icon: Icons.sms_outlined,
                          isLoading: _viewModel.requestOtpCommand.running,
                          onPressed: isCaptchaVerified ? _submit : null,
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
