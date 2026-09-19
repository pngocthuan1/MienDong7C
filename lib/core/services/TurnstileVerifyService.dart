import 'package:dio/dio.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';
import 'package:benhvien7c/core/network/ApiException.dart';

class TurnstileVerifyResult {
  final bool success;
  final String? error;

  const TurnstileVerifyResult({
    required this.success,
    this.error,
  });

  factory TurnstileVerifyResult.fromJson(Map<String, dynamic> json) {
    return TurnstileVerifyResult(
      success: json['valid'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}

class TurnstileVerifyService {
  final Dio _dio;

  TurnstileVerifyService({Dio? dio}) : _dio = dio ?? Dio();

  /// Xác thực token qua máy chủ bảo mật Cloudflare Worker (không để lộ Secret Key trong App)
  Future<ApiResult<TurnstileVerifyResult>> verifyToken(String captchaToken) async {
    if (captchaToken.isEmpty) {
      return ApiFailure(
        BusinessException('Mã xác thực CAPTCHA không được để trống'),
      );
    }

    try {
      final workerUrl = Environment.captchaVerifyWorkerUrl;
      final response = await _dio.post<Map<String, dynamic>>(
        workerUrl,
        data: {
          'token': captchaToken,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data != null) {
        final result = TurnstileVerifyResult.fromJson(response.data!);
        if (result.success) {
          return ApiSuccess(result);
        } else {
          return ApiFailure(
            BusinessException(
              'Xác thực CAPTCHA thất bại: ${result.error ?? "Phát hiện nghi ngờ tự động hóa"}',
            ),
          );
        }
      }

      return ApiFailure(
        UnknownException('Không nhận được phản hồi từ máy chủ xác thực Cloudflare Worker'),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return ApiFailure(
          NetworkException('Không thể kết nối đến máy chủ xác thực bảo mật. Vui lòng kiểm tra kết nối mạng.'),
        );
      }
      return ApiFailure(ApiException.fromDioError(e));
    } catch (e) {
      return ApiFailure(UnknownException('Lỗi xác minh CAPTCHA: $e'));
    }
  }

  /// Hàm tiện ích hỗ trợ xác thực nhanh từ Widget
  static Future<bool> verify(String token) async {
    final service = TurnstileVerifyService();
    final result = await service.verifyToken(token);
    if (result is ApiSuccess<TurnstileVerifyResult>) {
      return result.data.success;
    }
    return false;
  }
}
