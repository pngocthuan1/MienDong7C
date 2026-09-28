import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/services/TurnstileVerifyService.dart';

class CloudflareTurnstile extends StatefulWidget {
  const CloudflareTurnstile({
    super.key,
    required this.onVerified,
    this.onExpired,
    this.onRetry,
    this.simulateBot = false,
    this.hasError = false,
    this.errorMessage,
    this.siteKey,
  });

  final ValueChanged<String> onVerified;
  final VoidCallback? onExpired;
  final VoidCallback? onRetry;
  final bool simulateBot;
  final bool hasError;
  final String? errorMessage;
  final String? siteKey;

  @override
  State<CloudflareTurnstile> createState() => _CloudflareTurnstileState();
}

class _CloudflareTurnstileState extends State<CloudflareTurnstile> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isSuccess = false;
  bool _isWebviewFailed = false;
  String? _errorDetail;
  Timer? _timeoutTimer;
  Timer? _webCheckTimer;

  @override
  void initState() {
    super.initState();
    _initTurnstile();
  }

  @override
  void didUpdateWidget(covariant CloudflareTurnstile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      setState(() {
        _isLoading = false;
        _isVerifying = false;
        _isSuccess = false;
        _isWebviewFailed = true;
        _errorDetail = widget.errorMessage ?? 'Xác thực CAPTCHA thất bại hoặc nghi ngờ Spam Bot';
      });
      return;
    }
    if (!widget.hasError && oldWidget.hasError) {
      _retry();
      return;
    }
    if (widget.simulateBot != oldWidget.simulateBot || widget.siteKey != oldWidget.siteKey) {
      _initTurnstile();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _webCheckTimer?.cancel();
    super.dispose();
  }

  void _initTurnstile() {
    _timeoutTimer?.cancel();
    _webCheckTimer?.cancel();

    // Thiết lập trạng thái ban đầu: Đang xoay vòng kiểm tra an toàn
    setState(() {
      _isLoading = true;
      _isVerifying = false;
      _isSuccess = false;
      _isWebviewFailed = false;
      _errorDetail = null;
    });

    // ── Chế độ mô phỏng Bot (DevTesting) ──
    if (widget.simulateBot) {
      _webCheckTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isVerifying = false;
            _isSuccess = false;
            _isWebviewFailed = true;
            _errorDetail = 'Phát hiện nghi ngờ tự động hóa / Spam Bot';
          });
          widget.onExpired?.call();
        }
      });
      return;
    }

    // ── Nền tảng Web: Chặn hẳn, xoay vòng kiểm tra 1.8s rồi báo Không thể xác thực ──
    // Không tự động báo "thành công" giả để người dùng kiểm thử đúng trạng thái chặn thật
    if (kIsWeb) {
      _webCheckTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isVerifying = false;
            _isSuccess = false;
            _isWebviewFailed = true;
            _errorDetail = 'Không thể xác thực: Trình duyệt Web chưa được cấp phép bảo mật di động';
          });
          widget.onExpired?.call();
        }
      });
      return;
    }

    final siteKey = widget.siteKey ?? Environment.turnstileSiteKey;

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (String url) {
            _timeoutTimer?.cancel();
            if (mounted && _isLoading && !_isSuccess && !_isVerifying && !_isWebviewFailed) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              debugPrint(
                '[Turnstile] onWebResourceError: ${error.description} (code: ${error.errorCode}, isMainFrame: ${error.isForMainFrame})',
              );
            }
            if (error.isForMainFrame == true && error.errorCode != -1) {
              if (mounted && _isLoading && !_isSuccess) {
                _timeoutTimer?.cancel();
                setState(() {
                  _isLoading = false;
                  _isWebviewFailed = true;
                  _errorDetail = 'Lỗi mạng: ${error.description}';
                });
              }
            }
          },
        ))
        ..addJavaScriptChannel(
          'TurnstileChannel',
          onMessageReceived: (JavaScriptMessage message) async {
            try {
              final data = jsonDecode(message.message) as Map<String, dynamic>;
              final type = data['type'] as String?;

              if (type == 'ready') {
                _timeoutTimer?.cancel();
                if (mounted && _isLoading) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              } else if (type == 'success') {
                _timeoutTimer?.cancel();
                final token = data['token'] as String;
                debugPrint('[Turnstile] 🟢 Cloudflare vừa xác nhận người dùng thật! Token prefix: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

                // Cập nhật UI: Đang xác thực token với Cloudflare Worker
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _isVerifying = true;
                    _errorDetail = null;
                  });
                }

                // Gọi verify qua Cloudflare Worker thật
                final isValid = await TurnstileVerifyService.verify(token);
                debugPrint('[Turnstile] 🎯 Kết quả xác thực cuối cùng: isValid = $isValid');

                if (mounted) {
                  setState(() {
                    _isVerifying = false;
                    _isSuccess = isValid;
                    _isWebviewFailed = !isValid;
                    if (!isValid) {
                      _errorDetail = 'Xác thực không hợp lệ từ máy chủ bảo mật';
                    }
                  });
                }

                if (isValid) {
                  widget.onVerified(token);
                } else {
                  widget.onExpired?.call();
                }
              } else if (type == 'expired') {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _isSuccess = false;
                  });
                }
                widget.onExpired?.call();
              } else if (type == 'error') {
                _timeoutTimer?.cancel();
                final err = data['error'];
                if (kDebugMode) {
                  debugPrint('[Turnstile] Cloudflare onTurnstileError: $err');
                }
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _isWebviewFailed = true;
                    _errorDetail = 'Lỗi Cloudflare Turnstile: $err';
                  });
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[Turnstile] Parse message error: $e');
              }
            }
          },
        );

      final htmlContent = '''<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoaded" async defer></script>
    <style>
      * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
      }
      html, body {
        width: 100%;
        height: 100%;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: transparent;
        overflow: hidden;
      }
      .cf-turnstile {
        width: 100% !important;
        display: flex;
        justify-content: center;
      }
      .cf-turnstile > iframe {
        width: 100% !important;
        max-width: 100% !important;
        height: 65px !important;
      }
    </style>
  </head>
  <body>
    <div class="cf-turnstile"
         data-sitekey="$siteKey"
         data-size="flexible"
         data-callback="onTurnstileSuccess"
         data-expired-callback="onTurnstileExpired"
         data-error-callback="onTurnstileError"
         data-theme="light">
    </div>
    <script>
      function onTurnstileLoaded() {
        if (window.TurnstileChannel) {
          window.TurnstileChannel.postMessage(JSON.stringify({ type: 'ready' }));
        }
      }
      function onTurnstileSuccess(token) {
        if (window.TurnstileChannel) {
          window.TurnstileChannel.postMessage(JSON.stringify({ type: 'success', token: token }));
        }
      }
      function onTurnstileExpired() {
        if (window.TurnstileChannel) {
          window.TurnstileChannel.postMessage(JSON.stringify({ type: 'expired' }));
        }
      }
      function onTurnstileError(err) {
        if (window.TurnstileChannel) {
          window.TurnstileChannel.postMessage(JSON.stringify({ type: 'error', error: String(err) }));
        }
      }
    </script>
  </body>
</html>''';

      controller.loadHtmlString(
        htmlContent,
        baseUrl: 'https://quandanymiendong.vn',
      );

      setState(() {
        _webViewController = controller;
      });

      // Timeout 15 giây nếu mạng yếu
      _timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _isLoading && !_isSuccess && !_isVerifying) {
          setState(() {
            _isLoading = false;
            _isWebviewFailed = true;
            _errorDetail = 'Quá thời gian chờ phản hồi (15s)';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isWebviewFailed = true;
          _errorDetail = 'Khởi tạo thất bại: $e';
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _isVerifying = false;
      _isSuccess = false;
      _isWebviewFailed = false;
      _webViewController = null;
      _errorDetail = null;
    });
    widget.onRetry?.call();
    _initTurnstile();
  }

  @override
  Widget build(BuildContext context) {
    final isFailed = _isWebviewFailed || widget.simulateBot || widget.hasError;

    // ── Hiển thị WebView khi đang load Turnstile trên Mobile ──
    final showWebView = !kIsWeb &&
        _webViewController != null &&
        !_isSuccess &&
        !_isVerifying &&
        !isFailed;

    final Widget currentChild;

    if (showWebView) {
      currentChild = SizedBox(
        key: const ValueKey('turnstile_webview'),
        width: double.infinity,
        height: 65,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: WebViewWidget(controller: _webViewController!),
        ),
      );
    } else {
      currentChild = _buildStatusCard(
        key: ValueKey(
          'turnstile_${isFailed ? "failed" : _isSuccess ? "success" : "loading"}',
        ),
        isFailed: isFailed,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: currentChild,
    );
  }

  Widget _buildStatusCard({required Key key, required bool isFailed}) {
    final Color bgColor;
    final Color borderColor;
    final Widget iconWidget;
    final String title;
    final String subtitle;
    final Color titleColor;
    final Color subtitleColor;
    Widget? actionWidget;

    if (isFailed) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      iconWidget = const Icon(
        Icons.error_outline_rounded,
        color: Color(0xFFDC2626),
        size: 24,
      );
      title = 'Không thể xác thực';
      subtitle = widget.errorMessage ??
          _errorDetail ??
          'Phát hiện nghi ngờ tự động hóa / Spam Bot';
      titleColor = const Color(0xFFDC2626);
      subtitleColor = const Color(0xFFB91C1C);

      if (!_isLoading && !_isVerifying) {
        actionWidget = GestureDetector(
          onTap: _retry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Thử lại',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    } else if (_isSuccess) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF86EFAC);
      iconWidget = const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF16A34A),
        size: 24,
      );
      title = 'Xác minh thành công ✓';
      subtitle = 'Bảo vệ bởi Cloudflare Turnstile';
      titleColor = const Color(0xFF15803D);
      subtitleColor = const Color(0xFF166534);
    } else {
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      iconWidget = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
        ),
      );
      title = _isVerifying
          ? 'Đang xác thực bảo mật máy chủ...'
          : 'Đang kiểm tra an toàn...';
      subtitle = _isVerifying
          ? 'Đang kiểm tra token qua Cloudflare Worker'
          : 'Kiểm tra an toàn Cloudflare Edge...';
      titleColor = const Color(0xFF334155);
      subtitleColor = const Color(0xFF64748B);
    }

    return Container(
      key: key,
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.0),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (actionWidget != null)
            actionWidget
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.cloud_outlined, color: Color(0xFFF97316), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Turnstile',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Bảo mật Cloudflare',
                  style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
