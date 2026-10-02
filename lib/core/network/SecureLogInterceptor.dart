import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/utils/LogSanitizer.dart';

/// Interceptor ghi log mạng an toàn:
/// 1. Tự động ẩn hoàn toàn Authorization Bearer Token, mật khẩu, OTP, CCCD, SĐT.
/// 2. Tóm tắt các response dung lượng lớn (ListMaster) thành thông tin súc tích.
/// 3. Tuyệt đối không log dữ liệu thô ra console.
class SecureLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) return handler.next(options);

    final path = options.uri.path;
    final method = options.method.toUpperCase();

    // Làm sạch Authorization header
    final authHeader = options.headers['Authorization']?.toString();
    final maskedAuth = LogSanitizer.maskAuthorizationHeader(authHeader);

    final buffer = StringBuffer();
    buffer.writeln('🌐 [HTTP REQ] $method $path');
    buffer.writeln('   Headers: Authorization: $maskedAuth');

    if (options.data != null) {
      if (options.data is FormData) {
        final formData = options.data as FormData;
        final fields = formData.fields.map((f) {
          final isSensitive = f.key.toLowerCase().contains('pass') ||
              f.key.toLowerCase().contains('token') ||
              f.key.toLowerCase().contains('otp');
          return '${f.key}: ${isSensitive ? "[REDACTED]" : f.value}';
        }).join(', ');
        final files = formData.files.map((f) => '${f.key}: ${f.value.filename}').join(', ');
        buffer.writeln('   Body: FormData [Fields: $fields | Files: $files]');
      } else {
        buffer.writeln('   Body: ${LogSanitizer.formatRequestData(options.data)}');
      }
    }

    debugPrint(buffer.toString().trimRight());
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) return handler.next(response);

    final path = response.requestOptions.uri.path;
    final statusCode = response.statusCode;
    final summary = LogSanitizer.summarizeResponse(path, statusCode, response.data);

    debugPrint('📥 [HTTP RES] $statusCode $path -> $summary');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) return handler.next(err);

    final path = err.requestOptions.uri.path;
    final statusCode = err.response?.statusCode ?? 'N/A';
    final errorData = err.response?.data;
    final sanitizedError = errorData != null
        ? LogSanitizer.formatRequestData(errorData)
        : err.message;

    debugPrint('❌ [HTTP ERR] $statusCode $path -> $sanitizedError');
    return handler.next(err);
  }
}
