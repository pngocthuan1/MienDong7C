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
        AppNavigator.replaceNamed(
          context,
          RouteNames.resetPassword,
          arguments: ResetPasswordViewArgs(
            phoneNumber: widget.args.phoneNumber,
            otpCode: _viewModel.otpController.text.trim(),
          ),
        );
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHorizontalPadding,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _OtpHeroIcon(),
                        const SizedBox(height: 18),
                        const Text(
                          'Xác thực mã OTP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Vui lòng nhập mã 6 chữ số đã được gửi tới số điện thoại $_maskedPhoneNumber',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
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
                        const SizedBox(height: 14),
                        OtpCountdown(
                          isBusy: _viewModel.resendOtpCommand.running,
                          onResend: _resendOtp,
                        ),
                        const SizedBox(height: 14),
                        _OtpSubmitButton(
                          isEnabled: _viewModel.isOtpComplete,
                          isLoading: _viewModel.verifyOtpCommand.running,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 22),
                        const _OtpImagePlaceholder(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpHeroIcon extends StatelessWidget {
  const _OtpHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(31),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.shield_outlined,
          color: AppColors.primary,
          size: 28,
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
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
          else
            const Text('Xác thực ngay'),
          if (!isLoading) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ],
      ),
    );
  }
}

class _OtpImagePlaceholder extends StatelessWidget {
  const _OtpImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2F2)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'Chỗ để thêm ảnh',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Bạn có thể tự chèn ảnh vào đây sau.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
