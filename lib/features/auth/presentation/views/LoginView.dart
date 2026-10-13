import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
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

class _LoginViewState extends State<LoginView> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final LoginViewModel _viewModel;
  String? _captchaToken;
  DateTime? _captchaTokenIssuedAt;
  Timer? _captchaExpiryTimer;
  int _captchaResetKey = 0;
  bool _isFaceIdAvailable = false;
  bool _isBiometricLoggingIn = false;
  String _captchaStatusText = 'Đang đăng nhập...';

  /// Mốc thời gian mở màn hình LoginView để đo thời gian pre-warm token
  final DateTime _screenOpenTime = DateTime.now();

  /// Mốc thời gian người dùng chạm vân tay để đo thời gian từ lúc chạm đến lúc vào app
  DateTime? _biometricTouchTime;

  /// Completer dùng để chờ token captcha mới khi chưa có sẵn hoặc hết hạn (luồng vân tay)
  Completer<String>? _pendingBiometricCompleter;

  void _resetCaptcha() {
    if (!mounted) return;
    _captchaExpiryTimer?.cancel();
    _captchaExpiryTimer = null;
    setState(() {
      _captchaToken = null;
      _captchaTokenIssuedAt = null;
      _viewModel.captchaToken = null;
      _captchaResetKey++;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = LoginViewModel(
      AppLocator.authRepository,
      AppLocator.secureStorage,
    );
    _viewModel.loginCommand.addListener(_onLoginChanged);
    _checkFaceIdAvailable();
    _viewModel.initNetworkCheck();
    _viewModel.startListeningNetworkChanges();
  }

  Future<void> _checkFaceIdAvailable() async {
    try {
      final localAuth = LocalAuthentication();
      final available = await localAuth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) {
        setState(() {
          _isFaceIdAvailable = true;
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        debugPrint('[LoginView] App resumed -> Auto re-checking network!');
      }
      _viewModel.initNetworkCheck();
    }
  }

  @override
  void dispose() {
    _captchaExpiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.loginCommand.removeListener(_onLoginChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onLoginChanged() {
    if (_viewModel.loginCommand.running) {
      return;
    }

    if (mounted && _isBiometricLoggingIn) {
      setState(() {
        _isBiometricLoggingIn = false;
      });
    }

    final result = _viewModel.loginCommand.result;
    if (result == null || !mounted) {
      return;
    }

    result.when(
      success: (AuthSessionEntity _) async {
        if (_biometricTouchTime != null) {
          final totalMs = DateTime.now().difference(_biometricTouchTime!).inMilliseconds;
          if (kDebugMode) {
            debugPrint('[BiometricLogin] 🚀 Thành công! Tổng thời gian từ lúc chạm đến vào app: ${totalMs}ms (${(totalMs / 1000).toStringAsFixed(2)}s)');
          }
          _biometricTouchTime = null;
        }
        final phone = _viewModel.phoneController.text.trim();
        final password = _viewModel.passwordController.text;
        if (phone.isNotEmpty && password.isNotEmpty) {
          await AppLocator.secureStorage.saveBiometricCredentials(phone, password);
        }
        _viewModel.loginCommand.clearResult();
        _resetCaptcha();
        if (mounted) {
          AppNavigator.resetToNamed(context, RouteNames.home);
        }
      },
      failure: (exception) {
        if (_biometricTouchTime != null) {
          final totalMs = DateTime.now().difference(_biometricTouchTime!).inMilliseconds;
          if (kDebugMode) {
            debugPrint('[BiometricLogin] ❌ Đăng nhập thất bại sau ${totalMs}ms: $exception');
          }
          _biometricTouchTime = null;
        }
        _resetCaptcha();
        _viewModel.loginCommand.clearResult();
      },
    );
  }

  Future<void> _onBiometricLoginPressed() async {
    final localAuth = LocalAuthentication();
    try {
      final canAuthenticateWithBiometrics = await localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        _showSnackBar('Thiết bị của bạn không hỗ trợ sinh trắc học.');
        return;
      }

      final (savedPhone, savedPassword) = await AppLocator.secureStorage.getBiometricCredentials();
      if (savedPhone == null || savedPassword == null || savedPhone.isEmpty || savedPassword.isEmpty) {
        _showSnackBar('Vui lòng đăng nhập bằng mật khẩu trước để kích hoạt vân tay.');
        return;
      }

      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Xác thực vân tay để đăng nhập Bệnh viện 7C',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) {
        return;
      }

      _biometricTouchTime = DateTime.now();

      if (mounted) {
        setState(() {
          _isBiometricLoggingIn = true;
          _captchaStatusText = 'Đang đăng nhập...';
        });
      }

      _viewModel.phoneController.text = savedPhone;
      _viewModel.passwordController.text = savedPassword;

      final cleanPhone = savedPhone.replaceAll(RegExp(r'\D'), '');
      final boundRoleKey = cleanPhone.isNotEmpty ? cleanPhone : savedPhone.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final boundRole = prefs.getString('account_role_$boundRoleKey');

      if (boundRole == 'employee' && _viewModel.selectedRole != UserRole.employee) {
        _viewModel.updateRole(UserRole.employee);
      } else if (boundRole == 'customer' && _viewModel.selectedRole != UserRole.customer) {
        _viewModel.updateRole(UserRole.customer);
      }

      // Bỏ qua yêu cầu captcha trên Web (đã disable theo config)
      if (kIsWeb && Environment.disableTurnstileOnWeb) {
        await _viewModel.loginCommand.execute();
        return;
      }

      // Kiểm tra xem đã có token tươi được pre-warm sẵn (tuổi dưới 240 giây / 4 phút)
      String? tokenToUse;
      final now = DateTime.now();
      if (_captchaToken != null &&
          _captchaTokenIssuedAt != null &&
          now.difference(_captchaTokenIssuedAt!).inSeconds < 240) {
        tokenToUse = _captchaToken;
        if (kDebugMode) {
          final ageSec = now.difference(_captchaTokenIssuedAt!).inSeconds;
          debugPrint('[BiometricLogin] ⚡ Dùng ngay token pre-warm sẵn (tuổi token: ${ageSec}s)');
        }
      } else {
        // Nếu token đã quá 4 phút hoặc đã hết hạn: reset lấy token mới
        if (_captchaTokenIssuedAt != null && now.difference(_captchaTokenIssuedAt!).inSeconds >= 240) {
          if (kDebugMode) {
            debugPrint('[BiometricLogin] ⏳ Token cũ đã quá 4 phút, làm mới token...');
          }
          _resetCaptcha();
        } else {
          // Chưa có token (widget đang tải lần đầu): CHỜ TOKEN HIỆN TẠI, KHÔNG RESET GIỮA CHỪNG
          if (kDebugMode) {
            debugPrint('[BiometricLogin] ⏳ Đang chờ widget nạp xong token hiện tại (không reset giữa chừng)...');
          }
        }

        if (mounted) {
          setState(() {
            _captchaStatusText = 'Đang xác minh bảo mật...';
          });
        }

        // Nếu sau 1.5s mà vẫn chưa có token, nhắc người dùng chạm vào ô vuông xác nhận
        final promptTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted && _isBiometricLoggingIn && _captchaToken == null) {
            _showSnackBar('👉 Vui lòng chạm vào ô vuông để xác nhận bạn không phải người máy');
          }
        });

        _pendingBiometricCompleter = Completer<String>();
        try {
          tokenToUse = await _pendingBiometricCompleter!.future
              .timeout(const Duration(seconds: 30));
        } on TimeoutException {
          promptTimer.cancel();
          _pendingBiometricCompleter = null;
          if (mounted) {
            setState(() {
              _isBiometricLoggingIn = false;
              _captchaStatusText = 'Đang đăng nhập...';
            });
          }
          _showSnackBar('Xác thực bảo mật mất quá lâu. Vui lòng đăng nhập bằng mật khẩu hoặc thử lại.');
          _resetCaptcha();
          return;
        } finally {
          promptTimer.cancel();
          _pendingBiometricCompleter = null;
        }
      }

      if (!mounted) return;

      if (mounted) {
        setState(() {
          _captchaStatusText = 'Đang đăng nhập...';
        });
      }

      // Dùng token mới vừa nhận/đã có, verify đúng 1 lần khi execute
      _viewModel.captchaToken = tokenToUse;
      await _viewModel.loginCommand.execute();
      // Sau khi login hoàn tất (thành công hay thất bại), _onLoginChanged sẽ gọi _resetCaptcha()
      // để xóa token đã dùng và widget Turnstile tự động tải token mới sẵn sàng cho lần tiếp theo.
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isBiometricLoggingIn = false;
          _captchaStatusText = 'Đang đăng nhập...';
        });
      }
      _showSnackBar('Lỗi xác thực vân tay: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBiometricLoggingIn = false;
          _captchaStatusText = 'Đang đăng nhập...';
        });
      }
      _showSnackBar('Lỗi xác thực vân tay: $e');
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.blueAccent),
    );
  }

  Future<void> _submit() async {
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) {
        return;
      }
      await _viewModel.loginCommand.execute();
    } catch (_) {
    } finally {
      _resetCaptcha();
    }
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
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
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
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
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
        child: Form(
          key: _formKey,
          child: _LoginForm(
            viewModel: _viewModel,
            onSubmit: _submit,
            captchaToken: _captchaToken,
            captchaResetKey: _captchaResetKey,
            onCaptchaVerified: (token) {
              _viewModel.captchaToken = token;
              _captchaExpiryTimer?.cancel();
              _captchaExpiryTimer = Timer(const Duration(seconds: 240), () {
                if (mounted && _captchaToken == token) {
                  if (kDebugMode) {
                    debugPrint('[Turnstile] ⏰ Token đã quá 4 phút chưa dùng, tự reset lấy token mới...');
                  }
                  _resetCaptcha();
                }
              });

              final prewarmMs = DateTime.now().difference(_screenOpenTime).inMilliseconds;
              if (kDebugMode) {
                debugPrint('[Turnstile] ⏱️ Thời gian từ lúc mở LoginView đến khi có token: ${prewarmMs}ms (${(prewarmMs / 1000).toStringAsFixed(2)}s)');
              }

              setState(() {
                _captchaToken = token;
                _captchaTokenIssuedAt = DateTime.now();
              });
              // Nếu luồng vân tay đang chờ token mới, hoàn thành Completer
              if (_pendingBiometricCompleter != null &&
                  !_pendingBiometricCompleter!.isCompleted) {
                _pendingBiometricCompleter!.complete(token);
              }
            },
            onResetCaptcha: _resetCaptcha,
            onBiometricPressed: _onBiometricLoginPressed,
            onInteractiveRequired: () {
              if (mounted) {
                _showSnackBar('Vui lòng chạm vào ô vuông để xác nhận bạn không phải người máy.');
              }
            },
            isFaceIdAvailable: _isFaceIdAvailable,
            isBiometricLoggingIn: _isBiometricLoggingIn,
            captchaStatusText: _captchaStatusText,
          ),
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
    required this.captchaResetKey,
    required this.onCaptchaVerified,
    required this.onResetCaptcha,
    required this.onBiometricPressed,
    this.onInteractiveRequired,
    required this.isFaceIdAvailable,
    required this.isBiometricLoggingIn,
    required this.captchaStatusText,
  });

  final LoginViewModel viewModel;
  final Future<void> Function() onSubmit;
  final String? captchaToken;
  final int captchaResetKey;
  final ValueChanged<String> onCaptchaVerified;
  final VoidCallback onResetCaptcha;
  final VoidCallback onBiometricPressed;
  final VoidCallback? onInteractiveRequired;
  final bool isFaceIdAvailable;
  final bool isBiometricLoggingIn;
  final String captchaStatusText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.lock_person_rounded,
          title: 'Thông tin đăng nhập',
        ),
        ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.allowEmployeeRole) ...[
                  AuthRoleSwitcher(
                    selectedRole: viewModel.selectedRole,
                    onChanged: viewModel.updateRole,
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  controller: viewModel.phoneController,
                  label: viewModel.selectedRole == UserRole.employee
                      ? 'Tên đăng nhập HIS / Số điện thoại'
                      : 'Số điện thoại đăng ký',
                  hintText: viewModel.selectedRole == UserRole.employee
                      ? 'Nhập mã tài khoản HIS (VD: hunglng)'
                      : 'Nhập số điện thoại đăng ký',
                  keyboardType: viewModel.selectedRole == UserRole.customer
                      ? TextInputType.phone
                      : TextInputType.text,
                  inputFormatters: viewModel.selectedRole == UserRole.customer
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : null,
                  prefixIcon: viewModel.selectedRole == UserRole.employee
                      ? Icons.badge_outlined
                      : Icons.phone_outlined,
                  validator: viewModel.checkPhone,
                  textInputAction: TextInputAction.next,
                  onChanged: viewModel.updatePhoneError,
                ),
              ],
            );
          },
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
        const SizedBox(height: 0),
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
        ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            if (viewModel.message == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.itemSpacing),
              child: AuthFeedbackBanner(message: viewModel.message!),
            );
          },
        ),
        if (!(kIsWeb && Environment.disableTurnstileOnWeb)) ...[
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              final hasCaptchaError = viewModel.message != null &&
                  viewModel.message!.contains('CAPTCHA');
              return Center(
                child: CloudflareTurnstile(
                  key: ValueKey('turnstile_login_$captchaResetKey'),
                  siteKey: Environment.turnstileSiteKey,
                  hasError: hasCaptchaError,
                  errorMessage: viewModel.message,
                  onRetry: () {
                    viewModel.clearMessage();
                    onResetCaptcha();
                  },
                  onVerified: (token) {
                    viewModel.clearMessage();
                    onCaptchaVerified(token);
                  },
                  onInteractiveRequired: onInteractiveRequired,
                  onExpired: () {
                    onResetCaptcha();
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
        ],
        Row(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: viewModel.loginCommand,
                builder: (context, _) {
                  final isCaptchaVerified =
                      (kIsWeb && Environment.disableTurnstileOnWeb) ||
                      captchaToken != null;
                  final isBusy = viewModel.loginCommand.running || isBiometricLoggingIn;
                  return AppButton(
                    label: isBiometricLoggingIn ? captchaStatusText : 'Đăng nhập',
                    icon: Icons.login_rounded,
                    isLoading: isBusy,
                    onPressed: isCaptchaVerified && !isBusy ? onSubmit : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: isBiometricLoggingIn
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        isFaceIdAvailable ? Icons.face_unlock_rounded : Icons.fingerprint_rounded,
                        color: const Color(0xFF1976D2),
                        size: 32,
                      ),
                      onPressed: viewModel.loginCommand.running ? null : onBiometricPressed,
                    ),
            ),
          ],
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
