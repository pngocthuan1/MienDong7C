import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ErrorCode.dart';

/// Validate response trả về từ backend HIS.
/// Backend luôn trả HTTP 200, nên phải tự kiểm tra ErrorCode/ErrorId
/// trong body để biết request có thực sự thành công hay không.

class ApiValidator {
  /// Tầng 2: Hàm chung kiểm tra lỗi khi HTTP status là 200 OK.
  /// Bắt buộc ErrorCode = 0 và ErrorId = "0" hoặc null hoặc "null" thì mới đúng.

  static T validateResponse<T>({
    required Map<String, dynamic> json,
    required T Function(Object? json) fromJsonT,
  }) {
    final rawErrorCode = json['ErrorCode'] as int? ?? 0;
    final errorId = json['ErrorId']?.toString();
    final errorCode = ErrorCode.fromValue(rawErrorCode);

    final isErrorIdValid =
        errorId == null ||
        errorId.trim().isEmpty ||
        errorId.trim() == '0' ||
        errorId == 'null';
    final isErrorCodeValid = rawErrorCode == 0;

    if (!isErrorCodeValid || !isErrorIdValid) {
      final rawMessage = json['ErrorMessage'] as String?;
      final message = (rawMessage != null && rawMessage.trim().isNotEmpty)
          ? rawMessage
          : errorCode.message;

      throw BusinessException(message, errorCode: errorCode);
    }

    final data = json['Data'];
    if (data == null) {
      return fromJsonT(null);
    }

    return fromJsonT(data);
  }
}
