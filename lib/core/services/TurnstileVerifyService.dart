import 'package:dio/dio.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/network/ApiException.dart';

class TurnstileVerifyResult {
  final bool success;
  final String? hostname;
  final String? challengeTs;
  final List<String> errorCodes;

  const TurnstileVerifyResult({
    required this.success,
    this.hostname,
    this.challengeTs,
    this.errorCodes = const [],
  });

  factory TurnstileVerifyResult.fromJson(Map<String, dynamic> json) {
    return TurnstileVerifyResult(
      success: json['success'] as bool? ?? false,
      hostname: json['hostname'] as String?,
      challengeTs: json['challenge_ts'] as String?,
      errorCodes: (json['error-codes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class TurnstileVerifyService {
  final Dio _dio;

  TurnstileVerifyService({Dio? dio}) : _dio = dio ?? Dio();

  /// Gọi trực tiếp Cloudflare Siteverify API từ App Flutter
  /// Hỗ trợ kiểm tra mã Token (kể cả mã thật từ Cloudflare hoặc mã Mock tự sinh)
  Future<ApiResult<TurnstileVerifyResult>> verifyToken(String captchaToken) async {
    if (captchaToken.isEmpty) {
      return ApiFailure(
        BusinessException('Mã xác thực CAPTCHA không được để trống'),
      );
    }

    // 1. Nếu là token giả lập Bot (Thử nghiệm Bot thật từ Cloudflare Edge)
    if (captchaToken == 'cf-token-bot-failed') {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          'https://challenges.cloudflare.com/turnstile/v0/siteverify',
          data: {
            'secret': '2x0000000000000000000000000000000AB', // Secret Key thử nghiệm chặn Bot của Cloudflare
            'response': 'invalid_bot_token',
          },
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ),
        );
        if (response.data != null) {
          final result = TurnstileVerifyResult.fromJson(response.data!);
          return ApiFailure(
            BusinessException(
              'Máy chủ Cloudflare Edge đã phát hiện hành vi Spam Bot! Lỗi: ${result.errorCodes.join(", ")}',
            ),
          );
        }
      } catch (_) {}
      return ApiFailure(
        BusinessException('Phát hiện nghi ngờ Spam Bot / Tự động hóa!'),
      );
    }

    // 2. Nếu là token mô phỏng đăng nhập nhanh cho môi trường Demo
    if (captchaToken.startsWith('cf-token-mock-')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return const ApiSuccess(
        TurnstileVerifyResult(
          success: true,
          hostname: 'localhost',
          challengeTs: 'mock_timestamp',
        ),
      );
    }

    // 3. Nếu là token thật từ Cloudflare -> Gọi API https://challenges.cloudflare.com/turnstile/v0/siteverify
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://challenges.cloudflare.com/turnstile/v0/siteverify',
        data: {
          'secret': Environment.turnstileSecretKey,
          'response': captchaToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.data != null) {
        final result = TurnstileVerifyResult.fromJson(response.data!);
        if (result.success) {
          return ApiSuccess(result);
        } else {
          return ApiFailure(
            BusinessException(
              'Xác thực CAPTCHA thất bại: ${result.errorCodes.join(", ")}',
            ),
          );
        }
      }

      return ApiFailure(
        UnknownException('Không nhận được phản hồi từ máy chủ Cloudflare'),
      );
    } on DioException catch (e) {
      return ApiFailure(ApiException.fromDioError(e));
    } catch (e) {
      return ApiFailure(UnknownException('Lỗi xác minh CAPTCHA: $e'));
    }
  }
}
