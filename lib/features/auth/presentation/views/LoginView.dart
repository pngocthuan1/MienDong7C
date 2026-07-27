import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/constants/AppStrings.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/theme/AppTextStyles.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/core/widgets/AppPasswordField.dart';
import 'package:benhvien7c/core/widgets/AppTextField.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/LoginViewModel.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/widgets/CloudflareTurnstile.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCardShell.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFeedbackBanner.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFooterLink.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthGradientBackground.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  late final LoginViewModel _viewModel;
  String? _captchaToken;
  bool _isBotSimulation = false;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(
      AppLocator.authRepository,
      AppLocator.secureStorage,
    );
    _viewModel.loginCommand.addListener(_onLoginChanged);
  }

  @override
  void dispose() {
    _viewModel.loginCommand.removeListener(_onLoginChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onLoginChanged() {
    if (_viewModel.loginCommand.running) {
      return;
    }

    final result = _viewModel.loginCommand.result;
    if (result == null || !mounted) {
      return;
    }

    result.when(
      success: (AuthSessionEntity _) {
        _viewModel.loginCommand.clearResult();
        AppNavigator.resetToNamed(context, RouteNames.home);
      },
      failure: (exception) {
        _viewModel.loginCommand.clearResult();
      },
    );
  }

  Future<void> _submit() async {
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) {
        return;
      }
      await _viewModel.loginCommand.execute();
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
              child: _LoginForm(
                viewModel: _viewModel,
                onSubmit: _submit,
                captchaToken: _captchaToken,
                simulateBot: _isBotSimulation,
                onCaptchaVerified: (token) {
                  setState(() {
                    _captchaToken = token;
                  });
                },
                onBotToggled: (val) {
                  setState(() {
                    _isBotSimulation = val;
                    if (val) {
                      _captchaToken = null;
                    }
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginIntro extends StatelessWidget {
  const _LoginIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LogoPlaceholder(),
        const SizedBox(height: 22),
        Text(
          'Đăng nhập hệ thống',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 10),
        const Text(
          'Đăng nhập để tiếp tục sử dụng các chức năng của bệnh viện.',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageSubtitle,
        ),
      ],
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFCDE2F6), width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Vị trí chèn logo bệnh viện',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bạn có thể thay khung này bằng ảnh logo sau.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.viewModel,
    required this.onSubmit,
    required this.captchaToken,
    required this.simulateBot,
    required this.onCaptchaVerified,
    required this.onBotToggled,
  });

  final LoginViewModel viewModel;
  final Future<void> Function() onSubmit;
  final String? captchaToken;
  final bool simulateBot;
  final ValueChanged<String> onCaptchaVerified;
  final ValueChanged<bool> onBotToggled;


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LoginIntro(),
        const SizedBox(height: AppSizes.sectionSpacing),
        const _SectionTitle(
          icon: Icons.lock_person_rounded,
          title: 'Thông tin đăng nhập',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: viewModel.phoneController,
          label: 'Số điện thoại / Tên đăng nhập',
          hintText: 'Nhập số điện thoại hoặc tên đăng nhập',
          keyboardType: TextInputType.text,
          prefixIcon: Icons.person_outline_rounded,
          validator: viewModel.checkPhone,
          textInputAction: TextInputAction.next,
          onChanged: viewModel.updatePhoneError,
        ),
        const SizedBox(height: AppSizes.itemSpacing),
        AppPasswordField(
          controller: viewModel.passwordController,
          label: 'Mật khẩu',
          hintText: 'Nhập mật khẩu',
          validator: viewModel.checkPassword,
          textInputAction: TextInputAction.done,
          onChanged: viewModel.updatePasswordError,
        ),
        const SizedBox(height: AppSizes.itemSpacing),
        // Section Demo Accounts & Server Mode Toggle
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: viewModel.isOfflineDemo ? const Color(0xFFF2FAFF) : const Color(0xFFFFF8F2),
            borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
            border: Border.all(color: viewModel.isOfflineDemo ? const Color(0xFFCDEBFF) : const Color(0xFFFFE2CC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    viewModel.isOfflineDemo ? Icons.bolt_rounded : Icons.cloud_done_rounded,
                    color: viewModel.isOfflineDemo ? const Color(0xFF0A5FB6) : const Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.isOfflineDemo ? 'Chế độ Demo (Không cần Server)' : 'Chế độ Server Thật (API Backend)',
                          style: TextStyle(
                            color: viewModel.isOfflineDemo ? const Color(0xFF0A4F95) : const Color(0xFFB45309),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          viewModel.isOfflineDemo ? 'Cho phép dùng thử UI mà không cần bật máy chủ.' : 'Gửi yêu cầu đăng nhập trực tiếp tới Server.',
                          style: TextStyle(
                            color: viewModel.isOfflineDemo ? const Color(0xFF4A729D) : const Color(0xFF92400E),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: viewModel.isOfflineDemo,
                      activeColor: const Color(0xFF0A5FB6),
                      onChanged: (val) => viewModel.setOfflineDemo(val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFDDEEFE)),
              const SizedBox(height: 10),
              const Text(
                'Điền nhanh tài khoản mẫu:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        viewModel.phoneController.text = AppStrings.demoCustomerPhone;
                        viewModel.passwordController.text = AppStrings.demoPassword;
                        viewModel.updatePhoneError(null);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: Color(0xFFBBE0FF)),
                      ),
                      icon: const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF0A5FB6)),
                      label: const Text('Khách hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0A5FB6))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        viewModel.phoneController.text = AppStrings.demoEmployeePhone;
                        viewModel.passwordController.text = AppStrings.demoPassword;
                        viewModel.updatePhoneError(null);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: Color(0xFFBBE0FF)),
                      ),
                      icon: const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0A5FB6)),
                      label: const Text('Bác sĩ/Nhân viên', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0A5FB6))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              AppNavigator.pushNamed(context, RouteNames.forgotPassword);
            },
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: const Text('Quên mật khẩu?'),
          ),
        ),
        if (viewModel.message != null) ...[
          AuthFeedbackBanner(message: viewModel.message!),
          const SizedBox(height: AppSizes.itemSpacing),
        ],
        Center(
          child: CloudflareTurnstile(
            siteKey: Environment.turnstileSiteKey,
            simulateBot: simulateBot,
            onVerified: onCaptchaVerified,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_outlined, size: 16, color: Color(0xFFE05252)),
                    SizedBox(width: 6),
                    Text(
                      'Giả lập hành vi Bot (Spam)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: simulateBot,
                    activeColor: const Color(0xFFE05252),
                    onChanged: onBotToggled,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.itemSpacing),
        SizedBox(
          width: double.infinity,
          child: ListenableBuilder(
            listenable: viewModel.loginCommand,
            builder: (context, __) {
              final isCaptchaVerified = captchaToken != null;
              return AppButton(
                label: 'Đăng nhập',
                icon: Icons.login_rounded,
                isLoading: viewModel.loginCommand.running,
                onPressed: isCaptchaVerified ? onSubmit : null,
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.sectionSpacing),
        const Divider(color: Color(0xFFE4EDF7), height: 1),
        const SizedBox(height: AppSizes.sectionSpacing),
        AuthFooterLink(
          label: 'Chưa có tài khoản?',
          actionLabel: 'Đăng ký ngay',
          onTap: () {
            AppNavigator.pushNamed(context, RouteNames.register);
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF0B6EDB), size: 19),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF15395F),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
