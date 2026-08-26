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
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // bg-slate-50/50
        border: Border.all(
          color: _isLoading
              ? const Color(0xFFE2E8F0)
              : widget.simulateBot
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox / Loading section
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                      ),
                    )
                  : widget.simulateBot
                      ? const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFFDC2626),
                          size: 26,
                        )
                      : const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF22C55E),
                          size: 26,
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isLoading
                        ? const Color(0xFF475569)
                        : widget.simulateBot
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF15803D),
                  ),
                ),
                if (_isLoading)
                  const Text(
                    'Đang kiểm tra bảo mật...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                if (!_isLoading && widget.simulateBot)
                  const Text(
                    'Nghi ngờ tự động / Spam',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFDC2626),
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
                children: const [
                  Icon(
                    Icons.cloud_outlined,
                    color: Color(0xFFF97316),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Turnstile',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Bảo mật - Điều khoản',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
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
