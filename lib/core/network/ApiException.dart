import 'dart:io';
import 'package:benhvien7c/core/network/ErrorCode.dart';
import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ErrorCode? errorCode;

  const ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;

  /// Nhóm lỗi nghiệp vụ theo category, tiện cho ViewModel xử lý chung
  /// (vd: mọi lỗi insurance đều show cùng 1 kiểu dialog)
  ErrorCategory get category => errorCode?.category ?? ErrorCategory.unknown;

  /// true nếu lỗi này nên bắt người dùng đăng nhập lại
  bool get shouldForceLogout => this is UnauthorizedException;

  factory ApiException.fromDioError(DioException error) {
    // 1. Kiểm tra SocketException sâu bên trong (kể cả khi Dio bọc ngoài)
    if (error.error is SocketException) {
      return const NetworkException(
        'Không có kết nối mạng. Vui lòng kiểm tra lại Wifi hoặc 4G/5G.',
        isNoInternet: true,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutNetworkException(
          'Kết nối đến máy chủ quá hạn (timeout). Vui lòng thử lại.',
        );

      case DioExceptionType.badResponse:
        final response = error.response;
        final statusCode = response?.statusCode;
        final data = response?.data;

        String errorMessage = 'Đã xảy ra lỗi từ hệ thống.';
        ErrorCode? errorCode;

        if (data is Map<String, dynamic>) {
          // Ưu tiên 1: có ErrorCode dạng int -> lấy cả message chuẩn lẫn category
          if (data['ErrorCode'] != null && data['ErrorCode'] is int) {
            errorCode = ErrorCode.fromValue(data['ErrorCode'] as int);
            errorMessage = errorCode.message;
          }

          // Ưu tiên 2: có ErrorMessage riêng -> override message hiển thị,
          // nhưng vẫn giữ errorCode ở trên nếu có, để category không bị mất
          final rawErrorMessage = data['ErrorMessage'];
          if (rawErrorMessage != null &&
              rawErrorMessage.toString().trim().isNotEmpty) {
            errorMessage = rawErrorMessage.toString();
          }
          // Ưu tiên 3: fallback message thông thường
          else if (errorCode == null &&
              data['message'] != null &&
              data['message'].toString().trim().isNotEmpty) {
            errorMessage = data['message'].toString();
          }
        }

        switch (statusCode) {
          case 400:
            return BadRequestException(
              errorMessage,
              statusCode: statusCode,
              errorCode: errorCode,
            );
          case 401:
            return UnauthorizedException(
              errorMessage,
              statusCode: statusCode,
              errorCode: errorCode,
            );
          case 403:
            return ForbiddenException(
              errorMessage,
              statusCode: statusCode,
              errorCode: errorCode,
            );
          case 404:
            return NotFoundException(
              errorMessage,
              statusCode: statusCode,
              errorCode: errorCode,
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException(
              errorMessage.isNotEmpty && errorMessage != 'Đã xảy ra lỗi từ hệ thống.'
                  ? errorMessage
                  : 'Máy chủ bệnh viện đang bận hoặc gặp sự cố (Mã: $statusCode). Vui lòng thử lại sau.',
              statusCode: statusCode,
              errorCode: errorCode,
            );
          default:
            return UnknownException(
              errorMessage,
              statusCode: statusCode,
              errorCode: errorCode,
            );
        }

      case DioExceptionType.cancel:
        return const UnauthorizedException('Yêu cầu bị hủy');
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Không có kết nối mạng. Vui lòng kiểm tra lại kết nối Wifi hoặc 4G/5G.',
          isNoInternet: true,
        );
      default:
        return const NetworkException(
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại đường truyền mạng.',
        );
    }
  }

  /// Dùng khi backend trả HTTP 200 nhưng body chứa ErrorCode nghiệp vụ != 0
  /// (kiểu response phổ biến ở hệ thống HIS cũ: luôn 200, tự quản lý mã lỗi riêng)
  factory ApiException.fromBusinessErrorCode(int code, {int? statusCode}) {
    final errorCode = ErrorCode.fromValue(code);
    return BusinessException(
      errorCode.message,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  factory ApiException.validation(String message) {
    return BadRequestException(message);
  }
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(
    super.message, {
    super.statusCode,
    super.errorCode,
  });
}

class BadRequestException extends ApiException {
  const BadRequestException(super.message, {super.statusCode, super.errorCode});
}

class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.statusCode, super.errorCode});
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.statusCode, super.errorCode});
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, super.errorCode});
}

class NetworkException extends ApiException {
  final bool isNoInternet;
  final bool isTimeout;

  const NetworkException(
    super.message, {
    this.isNoInternet = false,
    this.isTimeout = false,
    super.statusCode,
    super.errorCode,
  });
}

class TimeoutNetworkException extends NetworkException {
  const TimeoutNetworkException([
    super.message = 'Kết nối đến máy chủ quá hạn (timeout). Vui lòng kiểm tra lại mạng và thử lại.',
  ]) : super(isTimeout: true);
}

/// Lỗi nghiệp vụ HIS trả về dù HTTP status vẫn là 200
/// (vd: ErrorCode = 306 "Bệnh nhân đã tồn tại" nhưng response code 200)
class BusinessException extends ApiException {
  const BusinessException(super.message, {super.statusCode, super.errorCode});
}

class UnknownException extends ApiException {
  const UnknownException(super.message, {super.statusCode, super.errorCode});
}
