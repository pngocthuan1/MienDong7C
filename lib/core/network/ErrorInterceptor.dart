import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:dio/dio.dart';

/// Chuẩn hóa mọi lỗi Dio thành ApiException ngay tại tầng network,
/// để tầng data/repository chỉ cần đọc error.error đã là ApiException,
/// không cần tự parse lại DioException ở từng RemoteDataSource.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = ApiException.fromDioError(err);
    final newError = err.copyWith(error: apiException);
    handler.next(newError);
  }
}
