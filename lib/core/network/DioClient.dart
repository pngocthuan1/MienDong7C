import 'dart:io';

import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/network/AuthInterceptor.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  DioClient({required this.secureStorage, Dio? dio}) : dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = Environment.baseUrl
      ..connectTimeout = const Duration(seconds: 60)
      ..receiveTimeout = const Duration(seconds: 60)
      ..responseType = ResponseType.json;

    // Chèn Interceptor tự động chèn headers bắt buộc & Logging
    this.dio.interceptors.addAll([
      AuthInterceptor(secureStorage, this.dio),
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    ]);

    // Bypass chứng chỉ SSL tự ký khi dev chạy localhost/IP nội bộ/máy thật
    final isLocalhost =
        Environment.isDevelopment ||
        Environment.baseUrl.contains('localhost') ||
        Environment.baseUrl.contains('10.0.2.2') ||
        Environment.baseUrl.contains('127.0.0.1') ||
        Environment.baseUrl.contains('192.168.');
    if (isLocalhost) {
      final clientAdapter = this.dio.httpClientAdapter;
      if (clientAdapter is IOHttpClientAdapter) {
        clientAdapter.createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        };
      }
    }
  }
}
