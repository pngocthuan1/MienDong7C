import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/utils/NotificationHelper.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/features/auth/presentation/widgets/AuthCaptchaField.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/DevTestingViewModel.dart';

class DevTestingView extends StatefulWidget {
  const DevTestingView({super.key});

  @override
  State<DevTestingView> createState() => _DevTestingViewState();
}

class _DevTestingViewState extends State<DevTestingView> {
  late final DevTestingViewModel _viewModel;
  final TextEditingController _captchaInputController = TextEditingController();
  final Random _random = Random();
  String _captchaCode = '';
  String? _captchaResult;

  bool _isSpamming = false;
  int _spamTotal = 0;
  int _spamSuccess = 0;
  int _spamBlocked = 0;
  String _spamLog = '';

  Future<void> _runSpamTest(int count) async {
    if (_isSpamming) return;
    setState(() {
      _isSpamming = true;
      _spamTotal = 0;
      _spamSuccess = 0;
      _spamBlocked = 0;
      _spamLog = '🚀 Đang khởi chạy $count requests spam liên tục sang Cloudflare Edge...\n';
    });

    const token = 'cf-token-bot-failed';

    for (var i = 1; i <= count; i++) {
      final res = await AppLocator.turnstileService.verifyToken(token);
      res.when(
        success: (_) {
          _spamSuccess++;
          _spamLog += '[$i/$count] ✅ PASSED\n';
        },
        failure: (exc) {
          _spamBlocked++;
          _spamLog += '[$i/$count] 🛑 BLOCKED: Cloudflare Edge chặn\n';
        },
      );
      if (mounted) {
        setState(() {
          _spamTotal = i;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isSpamming = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = DevTestingViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
    _refreshTestCaptcha();
  }

  @override
  void dispose() {
    _captchaInputController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _refreshTestCaptcha() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 5; i++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    setState(() {
      _captchaCode = buffer.toString();
      _captchaInputController.clear();
      _captchaResult = null;
    });
  }

  void _verifyTestCaptcha() {
    final input = _captchaInputController.text.trim().toUpperCase();
    setState(() {
      if (input.isEmpty) {
        _captchaResult = 'Vui lòng nhập mã captcha';
      } else if (input == _captchaCode) {
        _captchaResult = 'Xác minh Captcha thành công! (Hợp lệ)';
      } else {
        _captchaResult = 'Mã Captcha chưa chính xác, vui lòng thử lại.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return AppResponsiveContainer(
          maxWidth: 600.0,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D6EFD),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Bảng điều khiển thử nghiệm',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => AppNavigator.safePop(context),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFE6CC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEAD2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.developer_mode_rounded,
                            color: Color(0xFFD67A10),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'BẢNG ĐIỀU KHIỂN THỬ NGHIỆM',
                          style: TextStyle(
                            color: Color(0xFF9E5404),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '1. Giả lập thông báo Firebase (FCM Push)',
                      style: TextStyle(
                        color: Color(0xFF4D3319),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _DevButton(
                          label: 'Test: Duyệt (Đồng ý/Hủy)',
                          icon: Icons.assignment_turned_in_rounded,
                          color: const Color(0xFF2F7DE1),
                          onTap: () async {
                            await _viewModel.sendTestNotification(
                              context,
                              title: 'Yêu cầu duyệt ca tiếp nhận mới',
                              message: 'Bệnh nhân Nguyễn Văn B đang đợi duyệt tại Quầy tiếp nhận 2.',
                              details: 'Hồ sơ bệnh án điện tử đã sẵn sàng. Vui lòng đối chiếu thông tin BHYT và xác nhận tiếp nhận hoặc hủy lượt khám nếu thông tin sai lệch.',
                              category: 'queue',
                              isImportant: true,
                              primaryActionLabel: 'Đồng ý',
                              secondaryActionLabel: 'Hủy',
                              attachmentName: 'yeu-cau-duyet-33.docx',
                            );
                          },
                        ),
                        _DevButton(
                          label: 'Test: Tải tài liệu (PDF)',
                          icon: Icons.picture_as_pdf_rounded,
                          color: const Color(0xFFE05252),
                          onTap: () async {
                            await _viewModel.sendTestNotification(
                              context,
                              title: 'Báo cáo kết quả siêu âm tim',
                              message: 'Kết quả siêu âm tim của bệnh nhân Trần Văn C đã hoàn tất.',
                              details: 'Tệp siêu âm tim định dạng PDF đã được tải lên máy chủ bệnh viện. Vui lòng tải về máy để xem kết quả chi tiết chẩn đoán.',
                              category: 'document',
                              isImportant: false,
                              attachmentName: 'sieu-am-tim.docx',
                            );
                          },
                        ),
                        _DevButton(
                          label: 'Test: Nhắc uống thuốc',
                          icon: Icons.medical_services_outlined,
                          color: const Color(0xFF2E8B57),
                          onTap: () async {
                            await _viewModel.sendTestNotification(
                              context,
                              title: 'Nhắc lịch uống thuốc buổi trưa',
                              message: 'Vui lòng uống thuốc sau khi ăn 30 phút theo toa thuốc số 09.',
                              details: 'Toa thuốc số 09 gồm Paracetamol 500mg (1 viên) và Vitamin C 500mg (1 viên). Chú ý không uống thuốc khi bụng đói.',
                              category: 'reminder',
                              isImportant: true,
                              attachmentName: 'nhac-uong-thuoc.docx',
                            );
                          },
                        ),
                        _DevButton(
                          label: 'Test: Bảo trì hệ thống',
                          icon: Icons.construction_rounded,
                          color: const Color(0xFF6B7280),
                          onTap: () async {
                            await _viewModel.sendTestNotification(
                              context,
                              title: 'Bảo trì máy chủ dịch vụ khám',
                              message: 'Hệ thống đăng ký khám trực tuyến sẽ tạm ngưng để bảo trì tối nay.',
                              details: 'Thời gian bảo trì dự kiến: 23:00 hôm nay đến 01:00 ngày mai. Toàn bộ tính năng đặt lịch sẽ được khôi phục sau 01:00.',
                              category: 'announcement',
                              isImportant: false,
                              attachmentName: 'bao-tri-he-thong.docx',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Divider(color: Color(0xFFFFE6CC)),
                    const SizedBox(height: 12),
                    const Text(
                      '2. Thử nghiệm mã Captcha',
                      style: TextStyle(
                        color: Color(0xFF4D3319),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AuthCaptchaField(
                      controller: _captchaInputController,
                      challenge: _captchaCode,
                      onRefresh: _refreshTestCaptcha,
                      validator: (val) => null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _verifyTestCaptcha,
                          icon: const Icon(Icons.verified_user_rounded),
                          label: const Text('Kiểm tra Captcha'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD67A10),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _captchaInputController.text = _captchaCode;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD67A10),
                            side: const BorderSide(color: Color(0xFFD67A10)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Auto-fill mã đúng'),
                        ),
                      ],
                    ),
                    if (_captchaResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _captchaResult!.contains('thành công')
                              ? const Color(0xFFEAF9EB)
                              : const Color(0xFFFDECEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _captchaResult!.contains('thành công')
                                ? const Color(0xFFC3EDC8)
                                : const Color(0xFFFBC8CD),
                          ),
                        ),
                        child: Text(
                          _captchaResult!,
                          style: TextStyle(
                            color: _captchaResult!.contains('thành công')
                                ? const Color(0xFF1E6323)
                                : const Color(0xFFB3262E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Divider(color: Color(0xFFFFE6CC)),
                    const SizedBox(height: 12),
                    const Text(
                      '3. Thử nghiệm 7 loại Thông báo UI',
                      style: TextStyle(
                        color: Color(0xFF4D3319),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppNavigator.pushNamed(context, RouteNames.notificationPlayground);
                        },
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Mở Playground thử nghiệm 7 loại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6EFD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Divider(color: Color(0xFFFFE6CC)),
                    const SizedBox(height: 12),
                    const Text(
                      '4. Thông tin Firebase FCM Token',
                      style: TextStyle(
                        color: Color(0xFF4D3319),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD1A9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            NotificationHelper.fcmToken ?? 'Đang tải Token hoặc đang chạy ở Web (Mock)...',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Color(0xFF5C3A21),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (NotificationHelper.fcmToken != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: NotificationHelper.fcmToken!));
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép FCM Token vào bộ nhớ tạm!'),
                                      backgroundColor: Color(0xFF0F766E),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Sao chép FCM Token'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE67E22),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Divider(color: Color(0xFFFFE6CC)),
                    const SizedBox(height: 12),
                    const Text(
                      '5. Công cụ thử nghiệm Spam Bot (Turnstile Edge Test)',
                      style: TextStyle(
                        color: Color(0xFF4D3319),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD1A9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSpamming ? null : () => _runSpamTest(10),
                                  icon: const Icon(Icons.bolt_rounded, size: 16),
                                  label: const Text('Spam 10 Request'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSpamming ? null : () => _runSpamTest(30),
                                  icon: const Icon(Icons.security_rounded, size: 16),
                                  label: const Text('Spam 30 Request'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC62828),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isSpamming) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(
                              color: Color(0xFFC62828),
                              backgroundColor: Color(0xFFFFEBEE),
                            ),
                          ],
                          if (_spamTotal > 0 || _isSpamming) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('Đã gửi: $_spamTotal', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Cho qua: $_spamSuccess', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text('Chặn đứng: $_spamBlocked', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 120,
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _spamLog,
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DevButton extends StatelessWidget {
  const _DevButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
