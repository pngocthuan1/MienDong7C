import 'package:flutter_test/flutter_test.dart';
import 'package:benhvien7c/core/utils/LogSanitizer.dart';

void main() {
  group('LogSanitizer Tests', () {
    test('maskPhone masks middle digits properly', () {
      expect(LogSanitizer.maskPhone('0823458431'), equals('082***8431'));
      expect(LogSanitizer.maskPhone('0901237251'), equals('090***7251'));
      expect(LogSanitizer.maskPhone('12345'), equals('***'));
      expect(LogSanitizer.maskPhone(null), equals(''));
      expect(LogSanitizer.maskPhone(''), equals(''));
    });

    test('maskIdentifier masks CCCD and patient codes properly', () {
      expect(LogSanitizer.maskIdentifier('079123456789'), equals('079***6789'));
      expect(LogSanitizer.maskIdentifier('BN123456'), equals('BN1***3456'));
      expect(LogSanitizer.maskIdentifier('123'), equals('***'));
      expect(LogSanitizer.maskIdentifier(null), equals(''));
    });

    test('maskToken and maskAuthorizationHeader redact tokens', () {
      expect(LogSanitizer.maskToken('abc123token'), equals('[REDACTED: len=11]'));
      expect(LogSanitizer.maskToken(null), equals('null'));
      expect(
        LogSanitizer.maskAuthorizationHeader('Bearer my-secret-jwt-token'),
        equals('Bearer [REDACTED]'),
      );
      expect(
        LogSanitizer.maskAuthorizationHeader(null),
        equals('[NONE]'),
      );
    });

    test('sanitizeData recursively masks sensitive fields in Maps and Lists', () {
      final input = {
        'userName': 'patient01',
        'password': 'SuperSecretPassword123!',
        'accessToken': 'secret-access-token',
        'refreshToken': 'secret-refresh-token',
        'otp': '123456',
        'soDienThoai': '0823458431',
        'cccd': '079123456789',
        'nested': {
          'matKhau': 'nested_pass',
          'phone': '0901237251',
          'tokens': ['token1', 'token2'],
        },
      };

      final sanitized = LogSanitizer.sanitizeData(input) as Map<String, dynamic>;

      expect(sanitized['userName'], equals('patient01'));
      expect(sanitized['password'], equals('[REDACTED]'));
      expect(sanitized['accessToken'], equals('[REDACTED]'));
      expect(sanitized['refreshToken'], equals('[REDACTED]'));
      expect(sanitized['otp'], equals('[REDACTED]'));
      expect(sanitized['soDienThoai'], equals('082***8431'));
      expect(sanitized['cccd'], equals('079***6789'));

      final nested = sanitized['nested'] as Map<String, dynamic>;
      expect(nested['matKhau'], equals('[REDACTED]'));
      expect(nested['phone'], equals('090***7251'));
    });

    test('summarizeResponse generates compact summary for ListMaster', () {
      final listMasterData = {
        'ErrorCode': 0,
        'Data': {
          'ListTinh': List.generate(63, (i) => {'Id': i, 'Display': 'Tỉnh $i'}),
          'DicPhuong': {'tinh_1': [], 'tinh_2': []},
          'ListGioKham': List.generate(16, (i) => {'Id': '$i', 'Display': '07g00'}),
          'ListNgayKham': ['2026-10-02', '2026-10-03'],
        },
      };

      final summary = LogSanitizer.summarizeResponse(
        '/api/DatLichKham/ListMaster',
        200,
        listMasterData,
      );

      expect(summary, contains('ListMaster: nhận OK, 63 tỉnh, 2 nhóm phường, 16 khung giờ, 2 ngày khám'));
      expect(summary, isNot(contains('Tỉnh 0')));
    });
  });
}
