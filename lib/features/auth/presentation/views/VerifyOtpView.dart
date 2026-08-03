import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/widgets/AppOtpField.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/OtpViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFeedbackBanner.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/OtpCountdown.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthGradientBackground.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCardShell.dart';

class VerifyOtpView extends StatefulWidget {
  const VerifyOtpView({required this.args, super.key});

  final OtpViewArgs args;

  @override
  State<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  final _formKey = GlobalKey<FormState>();
  late final OtpViewModel _viewModel;

  String get _maskedPhoneNumber => _maskPhoneNumber(widget.args.phoneNumber);

  @override
  void initState() {
    super.initState();
    _viewModel = OtpViewModel(
      AppLocator.authRepository,
      phoneNumber: widget.args.phoneNumber,
      purpose: widget.args.purpose,
      fullName: widget.args.fullName,
      password: widget.args.password,
      key: widget.args.key,
      adjustSeconds: widget.args.adjustSeconds,
    );
    _viewModel.verifyOtpCommand.addListener(_onVerifyChanged);
  }

  @override
  void dispose() {
    _viewModel.verifyOtpCommand.removeListener(_onVerifyChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onVerifyChanged() {
    if (_viewModel.verifyOtpCommand.running) {
      return;
    }

    final result = _viewModel.verifyOtpCommand.result;
    if (result == null || !mounted) {
      return;
    }

    result.when(
      success: (message) {
        _viewModel.verifyOtpCommand.clearResult();
        _showSnackBar(_maskedMessage(message));
        if (widget.args.purpose == OtpPurpose.registration) {
          AppNavigator.resetToNamed(context, RouteNames.login);
        } else {
          AppNavigator.replaceNamed(
            context,
            RouteNames.resetPassword,
            arguments: ResetPasswordViewArgs(
              phoneNumber: widget.args.phoneNumber,
              otpCode: _viewModel.otpController.text.trim(),
              key: _viewModel.key,
              adjustSeconds: _viewModel.adjustSeconds,
            ),
          );
        }
      },
      failure: (_) {
        _viewModel.verifyOtpCommand.clearResult();
      },
    );
  }

  Future<void> _submit() async {
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) {
        return;
      }
      await _viewModel.verifyOtpCommand.execute();
    } catch (_) {}
  }

  Future<bool> _resendOtp() async {
    try {
      await _viewModel.resendOtpCommand.execute();
      final result = _viewModel.resendOtpCommand.result;
      if (!mounted || result == null) {
        return false;
      }

      final isSuccess = result.isSuccess;
      result.when(
        success: (message) {
          _showSnackBar(_maskedMessage(message));
        },
        failure: (_) {},
      );
      _viewModel.resendOtpCommand.clearResult();
      return isSuccess;
    } catch (_) {
      return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _maskedMessage(String message) {
    final digitsOnly = widget.args.phoneNumber.replaceAll(RegExp(r'\D'), '');

    return message
        .replaceAll(widget.args.phoneNumber, _maskedPhoneNumber)
        .replaceAll(digitsOnly, _maskedPhoneNumber);
  }

  static String _maskPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return '******';
    }

    final visibleCount = digitsOnly.length >= 4 ? 4 : digitsOnly.length;
    final visiblePart = digitsOnly.substring(digitsOnly.length - visibleCount);
    return '******$visiblePart';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthGradientBackground(
        child: AuthCardShell(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              final feedbackMessage = _viewModel.message == null
                  ? null
                  : _maskedMessage(_viewModel.message!);

              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF), // bg-blue-50
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.message_outlined,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Xác thực số điện thoại',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'Vui lòng nhập mã OTP 6 số vừa được gửi đến '),
                                  TextSpan(
                                    text: _maskedPhoneNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppOtpField(
                      controller: _viewModel.otpController,
                      validator: _viewModel.checkOtp,
                      autofocus: true,
                      onChanged: _viewModel.updateOtpError,
                    ),
                    if (feedbackMessage != null) ...[
                      const SizedBox(height: AppSizes.itemSpacing),
                      AuthFeedbackBanner(message: feedbackMessage),
                    ],
                    const SizedBox(height: 20),
                    _OtpSubmitButton(
                      isEnabled: _viewModel.isOtpComplete,
                      isLoading: _viewModel.verifyOtpCommand.running,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                    OtpCountdown(
                      isBusy: _viewModel.resendOtpCommand.running,
                      onResend: _resendOtp,
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
                      label: const Text(
                        'Quay lại sửa số điện thoại',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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

class _OtpSubmitButton extends StatelessWidget {
  const _OtpSubmitButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isEnabled && !isLoading ? onPressed : null;

    return FilledButton(
      onPressed: effectiveOnPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE3E7F2),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else ...[
            const Icon(Icons.check_circle_outline_rounded, size: 18),
            const SizedBox(width: 8),
            const Text('Xác nhận'),
          ],
        ],
      ),
    );
  }
}
