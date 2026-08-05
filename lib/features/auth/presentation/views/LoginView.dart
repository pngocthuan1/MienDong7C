import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/theme/AppTextStyles.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/core/widgets/AppPasswordField.dart';
import 'package:benhvien7c/core/widgets/AppTextField.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/LoginViewModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/widgets/CloudflareTurnstile.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCardShell.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFeedbackBanner.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthFooterLink.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthGradientBackground.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthRoleSwitcher.dart';

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

  int _logoTapCount = 0;
  DateTime? _lastLogoTapTime;

  void _onLogoTapped() {
    final now = DateTime.now();
    if (_lastLogoTapTime == null || now.difference(_lastLogoTapTime!) > const Duration(milliseconds: 1500)) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    _lastLogoTapTime = now;

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _showServerConfigDialog();
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: Environment.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.settings_suggest_rounded, color: Color(0xFF0D6EFD)),
            SizedBox(width: 8),
            Text('Cấu hình Server API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập địa chỉ Server API Backend (Bao gồm http:// hoặc https://):',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://api.benhvien7c.vn',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Gợi ý URL nhanh:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Localhost (7185)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'https://localhost:7185',
                ),
                ActionChip(
                  label: const Text('Localhost (7157)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'https://localhost:7157',
                ),
                ActionChip(
                  label: const Text('Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'https://10.0.2.2:7185',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('custom_base_url');
              Environment.setCustomBaseUrl(null);
              AppLocator.dioClient.dio.options.baseUrl = Environment.baseUrl;
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã khôi phục Server mặc định: ${Environment.baseUrl}'),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              }
            },
            child: const Text('Khôi phục mặc định', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('custom_base_url', newUrl);
                Environment.setCustomBaseUrl(newUrl);
                AppLocator.dioClient.dio.options.baseUrl = Environment.baseUrl;
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã cập nhật Server API thành: ${Environment.baseUrl}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD)),
            child: const Text('Lưu & Cập nhật', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientBackground(
      child: AuthCardShell(
        onLogoTap: _onLogoTapped,
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
                  _viewModel.captchaToken = token;
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
        Text(
          'Đăng nhập bệnh viện Miền Đông 7C',
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
        AuthRoleSwitcher(
          selectedRole: viewModel.selectedRole,
          onChanged: viewModel.updateRole,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: viewModel.phoneController,
          label: viewModel.selectedRole == UserRole.employee
              ? 'Tên đăng nhập HIS / Số điện thoại'
              : 'Số điện thoại đăng ký',
          hintText: viewModel.selectedRole == UserRole.employee
              ? 'Nhập mã tài khoản HIS (VD: hunglng)'
              : 'Nhập số điện thoại đăng ký',
          keyboardType: TextInputType.text,
          prefixIcon: viewModel.selectedRole == UserRole.employee
              ? Icons.badge_outlined
              : Icons.phone_outlined,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report_outlined, size: 16, color: Color(0xFFE05252)),
                  SizedBox(width: 6),
                  Text(
                    'Giả lập hành vi Bot (Spam)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: simulateBot,
                  activeThumbColor: const Color(0xFFE05252),
                  onChanged: onBotToggled,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.itemSpacing),
        SizedBox(
          width: double.infinity,
          child: ListenableBuilder(
            listenable: viewModel.loginCommand,
            builder: (context, _) {
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
