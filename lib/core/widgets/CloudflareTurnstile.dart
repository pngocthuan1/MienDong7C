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
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isSuccess = false;
  bool _isWebviewFailed = false;
  String? _errorDetail;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initTurnstile();
  }

  @override
  void didUpdateWidget(covariant CloudflareTurnstile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.simulateBot != oldWidget.simulateBot || widget.siteKey != oldWidget.siteKey) {
      _initTurnstile();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initTurnstile() {
    _timeoutTimer?.cancel();

    // ── Chế độ mô phỏng Bot (DevTesting) ──
    if (widget.simulateBot) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = false;
            _isWebviewFailed = false;
            _errorDetail = null;
          });
          widget.onExpired?.call();
        }
      });
      return;
    }

    // ── Web platform (Chrome/Edge localhost): tự động thông qua để dev/test ──
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
            _isWebviewFailed = false;
            _errorDetail = null;
          });
          widget.onVerified(
            'cf-token-mock-web-${DateTime.now().millisecondsSinceEpoch}',
          );
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

              if (type == 'success') {
                _timeoutTimer?.cancel();
                final token = data['token'] as String;

                // Cập nhật UI: Đang xác thực token với Cloudflare Worker
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _isVerifying = true;
                    _errorDetail = null;
                  });
                }

                // Gọi verify qua Cloudflare Worker
                final isValid = await TurnstileVerifyService.verify(token);

                if (mounted) {
                  setState(() {
                    _isVerifying = false;
                    _isSuccess = isValid;
                    _isWebviewFailed = !isValid;
                    if (!isValid) {
                      _errorDetail = 'Xác thực không hợp lệ từ máy chủ';
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
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: transparent;
        overflow: hidden;
      }
    </style>
  </head>
  <body>
    <div class="cf-turnstile"
         data-sitekey="$siteKey"
         data-callback="onTurnstileSuccess"
         data-expired-callback="onTurnstileExpired"
         data-error-callback="onTurnstileError"
         data-theme="light">
    </div>
    <script>
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
        _isLoading = true;
        _isVerifying = false;
        _isSuccess = false;
        _isWebviewFailed = false;
        _errorDetail = null;
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
    _initTurnstile();
  }

  @override
  Widget build(BuildContext context) {
    // ── Hiển thị WebView khi đang load Turnstile ──
    final showWebView = _webViewController != null &&
        !_isSuccess &&
        !_isVerifying &&
        !widget.simulateBot &&
        !_isWebviewFailed;

    if (showWebView) {
      return Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: WebViewWidget(controller: _webViewController!),
      );
    }

    // ── Hiển thị trạng thái: đang verify với Worker / thành công / lỗi ──
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(
          color: _isWebviewFailed || widget.simulateBot
              ? const Color(0xFFFCA5A5)
              : _isSuccess
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: (_isLoading || _isVerifying)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1976D2),
                          ),
                        ),
                      )
                    : _isWebviewFailed || widget.simulateBot
                        ? const Icon(
                            Icons.error_outline_rounded,
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isVerifying
                        ? 'Đang xác thực bảo mật máy chủ...'
                        : _isLoading
                            ? 'Đang nạp Cloudflare Turnstile...'
                            : _isWebviewFailed
                                ? 'Không thể tải xác thực'
                                : widget.simulateBot
                                    ? 'Xác thực thất bại (Bot)'
                                    : 'Xác minh thành công ✓',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: (_isLoading || _isVerifying)
                          ? const Color(0xFF334155)
                          : _isWebviewFailed || widget.simulateBot
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isVerifying
                        ? 'Đang kiểm tra token qua Cloudflare Worker'
                        : _isLoading
                            ? 'Kiểm tra an toàn Cloudflare Edge...'
                            : _isWebviewFailed
                                ? (_errorDetail ?? 'Kiểm tra kết nối internet và thử lại')
                                : widget.simulateBot
                                    ? 'Nghi ngờ tự động / Spam'
                                    : 'Bảo vệ bởi Cloudflare Turnstile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _isWebviewFailed ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Nút Thử lại khi lỗi ──
            if (_isWebviewFailed)
              GestureDetector(
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.cloud_outlined, color: Color(0xFFF97316), size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Turnstile',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Bảo mật Cloudflare',
                    style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
