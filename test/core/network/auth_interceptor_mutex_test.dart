import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:benhvien7c/core/network/AuthInterceptor.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  FakeSecureStorageService({String initialAccess = 'old_token', String initialRefresh = 'old_refresh'}) {
    _data['access_token'] = initialAccess;
    _data['refresh_token'] = initialRefresh;
  }

  @override
  Future<void> saveTokensRecord(String? access, String? refresh) async {
    if (access != null) _data['access_token'] = access;
    if (refresh != null) _data['refresh_token'] = refresh;
  }

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<bool> isRefreshTokenExpired() async => false;

  @override
  Future<String> getOrCreateDeviceId() async => 'fake_device_id';

  @override
  Future<void> saveExpiresRefreshToken(String ticks) async {}

  @override
  Future<void> clearSession() async {
    _data.clear();
  }
}

class ConcurrentTestAdapter implements HttpClientAdapter {
  int refreshTokenCallCount = 0;
  final List<String> requestHistory = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    requestHistory.add(path);

    // Xử lý request Refresh Token
    if (path.contains('/api/Token/RefreshToken')) {
      refreshTokenCallCount++;
      // Giả lập độ trễ mạng 60ms để các request khác có thời gian chạm 401 đồng thời
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final responseBody = jsonEncode({
        'Data': {
          'AccessToken': 'new_access_token_xyz',
          'RefreshToken': 'new_refresh_token_xyz',
          'ExpiresRefreshToken': '123456789',
        }
      });

      return ResponseBody.fromString(
        responseBody,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    // Xử lý request API thông thường
    final authHeader = options.headers['Authorization']?.toString();
    if (authHeader == 'Bearer new_access_token_xyz') {
      return ResponseBody.fromString(
        jsonEncode({'status': 'ok', 'data': 'success_for_${options.path}'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    // Nếu dùng token cũ -> Trả về lỗi 401 Unauthorized
    return ResponseBody.fromString(
      jsonEncode({'message': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AuthInterceptor Mutex - 3 request 401 đồng thời chỉ kích hoạt duy nhất 1 lần RefreshToken', () async {
    final fakeStorage = FakeSecureStorageService();
    final adapter = ConcurrentTestAdapter();

    final dio = Dio(BaseOptions(baseUrl: 'https://test.benhvien7c.vn'));
    dio.httpClientAdapter = adapter;

    final authInterceptor = AuthInterceptor(fakeStorage, dio);
    dio.interceptors.add(authInterceptor);

    // Gửi đồng thời 3 request API thông thường khi access token cũ đã hết hạn
    final future1 = dio.get<Map<String, dynamic>>('/api/Patient/Info1');
    final future2 = dio.get<Map<String, dynamic>>('/api/Patient/Info2');
    final future3 = dio.get<Map<String, dynamic>>('/api/Patient/Info3');

    final results = await Future.wait([future1, future2, future3]);

    // 1. Xác nhận cả 3 request đều nhận được kết quả thành công 200 sau khi retry với token mới
    expect(results[0].statusCode, 200);
    expect(results[1].statusCode, 200);
    expect(results[2].statusCode, 200);

    expect(results[0].data?['status'], 'ok');
    expect(results[1].data?['status'], 'ok');
    expect(results[2].data?['status'], 'ok');

    // 2. Điểm then chốt: API RefreshToken CHỈ ĐƯỢC GỌI DUY NHẤT 1 LẦN dù có 3 request 401 đồng thời
    expect(adapter.refreshTokenCallCount, 1,
        reason: 'Mutex phải gộp 3 request 401 lại và chỉ gọi refresh token đúng 1 lần duy nhất');

    // 3. Token mới đã được lưu an toàn vào Storage
    final savedAccess = await fakeStorage.getAccessToken();
    expect(savedAccess, 'new_access_token_xyz');
  });
}
