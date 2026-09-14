import 'dart:async';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/core/network/ErrorCode.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _dio;
  Completer<String?>? _refreshTokenCompleter;

  AuthInterceptor(this._secureStorage, this._dio);

  Future<void> _handleSessionExpiration() async {
    await _secureStorage.clearSession();
    AppSessionStore.instance.clear();
    AppNavigator.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      RouteNames.login,
      (route) => false,
    );
  }

  static const _loginPath = '/api/token/login';
  static const _refreshTokenPath = '/api/token/refreshtoken';

  bool _isAuthFreePath(String path) {
    final lower = path.toLowerCase();
    return lower.contains(_loginPath) || lower.contains(_refreshTokenPath);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Chèn các headers thiết bị & app bắt buộc.
    // Dùng deviceId từ SecureStorageService (persist, có fallback UUID),
    // không dùng Environment.deviceId để tránh 2 nguồn deviceId khác nhau.
    final deviceId = await _secureStorage.getOrCreateDeviceId();
    options.headers['HisDeviceInfo'] = '${Environment.platform} | $deviceId';
    options.headers['BanBuild'] = Environment.appPackageName;

    // 2. Không chèn Authorization header cho API Login hoặc RefreshToken
    if (!_isAuthFreePath(options.path)) {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Không thực hiện refresh nếu chính API Login hoặc RefreshToken lỗi 401
    if (_isAuthFreePath(err.requestOptions.path)) {
      return handler.next(err);
    }

    // 1. Nếu đang có một request khác thực hiện RefreshToken -> Chờ Completer hoàn tất
    if (_refreshTokenCompleter != null) {
      try {
        final newAccessToken = await _refreshTokenCompleter!.future;
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } else {
          return handler.next(err);
        }
      } catch (retryErr) {
        return handler.reject(
          retryErr is DioException
              ? retryErr
              : DioException(requestOptions: err.requestOptions, error: retryErr),
        );
      }
    }

    final accessToken = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      return handler.next(err);
    }

    // 2. Kiểm tra nếu request 401 này dùng token cũ hơn token đã lưu trong SecureStorage
    // (Đã có request khác refresh thành công ngay trước đó khi request này đang in-flight)
    final sentAuthHeader = err.requestOptions.headers['Authorization']?.toString();
    final sentToken = sentAuthHeader?.replaceFirst('Bearer ', '').trim();
    if (sentToken != null && accessToken != sentToken) {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $accessToken';
      try {
        final retryResponse = await _dio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } catch (retryErr) {
        return handler.reject(
          retryErr is DioException
              ? retryErr
              : DioException(requestOptions: err.requestOptions, error: retryErr),
        );
      }
    }

    final isExpired = await _secureStorage.isRefreshTokenExpired();
    if (isExpired) {
      await _handleSessionExpiration();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(
            'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại (Refresh Token đã hết hạn).',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    }

    final completer = Completer<String?>();
    _refreshTokenCompleter = completer;

    try {
      // Client riêng để gọi RefreshToken, tránh vòng lặp vô chậm interceptor.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: Environment.apiTimeout,
          receiveTimeout: Environment.apiTimeout,
        ),
      );

      // Dùng chung httpClientAdapter với client cha để thừa hưởng
      // cấu hình SSL bypass đã set đúng theo Environment.isDevelopment.
      refreshDio.httpClientAdapter = _dio.httpClientAdapter;

      final deviceId = await _secureStorage.getOrCreateDeviceId();
      refreshDio.options.headers['HisDeviceInfo'] =
          '${Environment.platform} | $deviceId';
      refreshDio.options.headers['BanBuild'] = Environment.appPackageName;

      final response = await refreshDio.post(
        '/api/Token/RefreshToken',
        data: {'AccessToken': accessToken, 'RefreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['Data'];
        final newAccessToken = data?['AccessToken'];
        final newRefreshToken = data?['RefreshToken'];
        final expiresRefreshToken = data?['ExpiresRefreshToken'];

        if (newRefreshToken != null && newAccessToken != null) {
          await _secureStorage.saveTokensRecord(
            newAccessToken,
            newRefreshToken,
          );
          if (expiresRefreshToken != null) {
            await _secureStorage.saveExpiresRefreshToken(
              expiresRefreshToken.toString(),
            );
          }

          completer.complete(newAccessToken.toString());

          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        }
      }

      // Response 200 nhưng thiếu token mới -> coi như refresh thất bại
      if (!completer.isCompleted) completer.complete(null);
      await _handleSessionExpiration();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(
            'Không thể làm mới phiên đăng nhập. Vui lòng đăng nhập lại.',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
      await _handleSessionExpiration();

      String expiredMessage =
          'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.';

      if (e is DioException) {
        final response = e.response;
        if (response != null && response.statusCode == 400) {
          final rawContent = response.data?.toString() ?? '';

          if (rawContent.contains('Token-Invalid-Access')) {
            expiredMessage =
                'Phiên làm việc đã hết hạn\nVui lòng đăng xuất rồi sau đó đăng nhập lại (Lỗi: Kiểm tra mã không hợp lệ)';
          } else if (rawContent.contains('Token-Invalid-Refresh')) {
            expiredMessage =
                'Phiên làm việc đã hết hạn\nVui lòng đăng xuất rồi sau đó đăng nhập lại (Lỗi: Kiểm tra mã làm mới không hợp lệ)';
          } else if (response.data is Map<String, dynamic>) {
            final map = response.data as Map<String, dynamic>;
            if (map['ErrorCode'] == ErrorCode.showErrorMessage.value) {
              expiredMessage = map['ErrorMessage'] as String? ?? expiredMessage;
            }
          }
        }
      }

      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: UnauthorizedException(
            expiredMessage,
          ), // ✅ ApiException, không phải String
          response: e is DioException ? e.response : null,
          type: DioExceptionType.badResponse,
        ),
      );
    } finally {
      _refreshTokenCompleter = null;
    }
  }
}
