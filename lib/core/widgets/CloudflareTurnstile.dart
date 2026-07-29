import 'dart:async';
import 'package:flutter/material.dart';

class CloudflareTurnstile extends StatefulWidget {
  const CloudflareTurnstile({
    super.key,
    required this.onVerified,
    this.onExpired,
    this.simulateBot = false,
    this.siteKey,
  });

  final ValueChanged<String> onVerified;
  final VoidCallback? onExpired;
  final bool simulateBot;
  final String? siteKey;

  @override
  State<CloudflareTurnstile> createState() => _CloudflareTurnstileState();
}

class _CloudflareTurnstileState extends State<CloudflareTurnstile> {
  bool _isLoading = true;
  bool _isSuccess = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startVerification();
  }

  @override
  void didUpdateWidget(covariant CloudflareTurnstile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.simulateBot != oldWidget.simulateBot) {
      _startVerification();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVerification() {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        if (widget.simulateBot) {
          setState(() {
            _isLoading = false;
            _isSuccess = false;
          });
          widget.onVerified('cf-token-bot-failed');
          if (widget.onExpired != null) {
            widget.onExpired!();
          }
        } else {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          // Emit a mock token
          widget.onVerified('cf-token-mock-${DateTime.now().millisecondsSinceEpoch}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 300,
        minHeight: 60,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        border: Border.all(
          color: _isLoading
              ? const Color(0xFFE2E8F0)
              : widget.simulateBot
                  ? const Color(0xFFFED7D7)
                  : const Color(0xFFE2E8F0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox / Loading section
          SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F7DE1)),
                      ),
                    )
                  : widget.simulateBot
                      ? const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFFD32F2F),
                          size: 24,
                        )
                      : const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
            ),
          ),
          const SizedBox(width: 8),
          // Label section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isLoading
                      ? 'Xác thực bạn là con người'
                      : widget.simulateBot
                          ? 'Xác thực thất bại (Bot)'
                          : 'Xác minh thành công',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: (_isSuccess || widget.simulateBot) ? FontWeight.w600 : FontWeight.w500,
                    color: _isLoading
                        ? const Color(0xFF4A5568)
                        : widget.simulateBot
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF2E7D32),
                  ),
                ),
                if (_isLoading)
                  const Text(
                    'Đang kiểm tra bảo mật...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF718096),
                    ),
                  ),
                if (!_isLoading && widget.simulateBot)
                  const Text(
                    'Nghi ngờ tự động / Spam',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cloudflare Branding section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_rounded,
                    color: Color(0xFFF38020),
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Turnstile',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Bảo mật - Điều khoản',
                style: TextStyle(
                  fontSize: 8,
                  color: Color(0xFF718096),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
