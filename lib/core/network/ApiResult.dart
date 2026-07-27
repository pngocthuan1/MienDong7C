import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ErrorCode.dart';

/// Lớp đóng gói kết quả gọi API.
sealed class ApiResult<T> {
  const ApiResult();

  /// Xử lý cả 2 trường hợp thành công / thất bại, trả về giá trị R.
  /// Dùng thay cho switch-case dài dòng trong ViewModel.

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException exception) failure,
  }) {
    final seft = this;
    return switch (seft) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final exception) => failure(exception),
    };
  }

  /// Biến đổi data bên trong nếu là ApiSuccess, giữ nguyên nếu là ApiFailure.
  ApiResult<R> map<R>(R Function(T data) transform) {
    final self = this;
    return switch (self) {
      ApiSuccess<T>(:final data) => ApiSuccess(transform(data)),
      ApiFailure<T>(:final exception) => ApiFailure(exception),
    };
  }

  /// Chạy side-effect (ví dụ log, analytics) mà không đổi kết quả gốc.
  ApiResult<T> tap({
    void Function(T data)? onSuccess,
    void Function(ApiException exception)? onFailure,
  }) {
    final self = this;
    switch (self) {
      case ApiSuccess<T>(:final data):
        onSuccess?.call(data);
      case ApiFailure<T>(:final exception):
        onFailure?.call(exception);
    }
    return this;
  }

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  /// Lấy data nếu thành công, null nếu thất bại.
  T? get dataOrNull => switch (this) {
    ApiSuccess<T>(:final data) => data,
    ApiFailure<T>() => null,
  };

  /// Lấy exception nếu thất bại, null nếu thành công.
  ApiException? get exceptionOrNull => switch (this) {
    ApiSuccess<T>() => null,
    ApiFailure<T>(:final exception) => exception,
  };

  /// Lấy nhóm lỗi (category) nếu thất bại — tiện cho ViewModel
  /// xử lý theo nhóm mà không cần unwrap exception thủ công.
  ErrorCategory? get ErrorCategoryOrNull => switch (this) {
    ApiSuccess<T>() => null,
    ApiFailure<T>(:final exception) => exception.category,
  };

  /// true nếu lỗi thuộc nhóm cần bắt đăng nhập lại
  /// (proxy tới ApiException.shouldForceLogout, tiện gọi trực tiếp từ ApiResult)

  bool get shouldForceLogout => switch (this) {
    ApiSuccess<T>() => false,
    ApiFailure<T>(:final exception) => exception.shouldForceLogout,
  };
}

/// Trả về khi gọi API thành công
class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

/// Trả về khi gọi API xảy ra lỗi (lỗi mạng, lỗi server, lỗi nghiệp vụ HIS, v.v...)
class ApiFailure<T> extends ApiResult<T> {
  final ApiException exception;
  const ApiFailure(this.exception);
}
