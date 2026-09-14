import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/auth/presentation/viewmodels/OtpViewModel.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/core/network/ApiResult.dart';

class MockAuthRepo implements AuthRepository {
  int signUpCallCount = 0;
  String? lastPassedPassword;

  @override
  Future<ApiResult<String>> signUp(
    String fullName,
    String phone,
    String password,
    String otp,
    String key,
    int adjustSeconds,
  ) async {
    signUpCallCount++;
    lastPassedPassword = password;
    if (otp == '000000') {
      return const ApiSuccess('Invalid');
    }
    return const ApiSuccess('OK');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Đợt 3: PII Security & Password Memory Lifecycle', () {
    test('OtpViewModel: Password được GIỮ LẠI khi nhập sai OTP để retry, và CHỈ giải phóng khi signUp thành công', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final mockRepo = MockAuthRepo();
      final secureStorage = SecureStorageService();

      AppLocator.init(
        repository: mockRepo,
        storage: secureStorage,
        portalRepo: FakePortalRepository(),
        session: AppSessionStore.instance,
        dio: DioClient(secureStorage: secureStorage),
      );

      final viewModel = OtpViewModel(
        mockRepo,
        phoneNumber: '0912345678',
        purpose: OtpPurpose.registration,
        fullName: 'Nguyen Van A',
        password: 'SecretPassword123!',
      );

      expect(viewModel.password, 'SecretPassword123!');

      // Lần 1: Người dùng nhập sai mã OTP
      viewModel.otpController.text = '000000';
      await viewModel.verifyOtpCommand.execute();

      // Kiểm tra: Mật khẩu KHÔNG ĐƯỢC BỊ XÓA khi thất bại để người dùng còn retry
      expect(mockRepo.signUpCallCount, 1);
      expect(mockRepo.lastPassedPassword, 'SecretPassword123!');
      expect(viewModel.password, 'SecretPassword123!',
          reason: 'Mật khẩu phải được bảo lưu khi OTP sai để phục vụ lần thử lại tiếp theo');

      // Lần 2: Người dùng sửa lại mã OTP đúng
      viewModel.otpController.text = '123456';
      await viewModel.verifyOtpCommand.execute();

      expect(mockRepo.signUpCallCount, 2);
      expect(mockRepo.lastPassedPassword, 'SecretPassword123!',
          reason: 'Lần gọi thứ 2 phải gửi mật khẩu gốc hợp lệ chứ không phải chuỗi rỗng');

      // Sau khi signUp thành công thật sự -> Mật khẩu PHẢI được giải phóng khỏi RAM
      expect(viewModel.password, isNull,
          reason: 'Mật khẩu phải được giải phóng khỏi RAM ngay khi đăng ký thành công');

      // Dữ liệu họ tên theo SĐT đã được lưu an toàn vào SecureStorage
      expect(await secureStorage.getSavedFullName(), 'Nguyen Van A');
      expect(await secureStorage.getFullNameForPhone('0912345678'), 'Nguyen Van A');
    });

    test('OtpViewModel: Password được giải phóng khi dispose() nếu người dùng hủy/rời màn hình', () {
      final mockRepo = MockAuthRepo();
      final viewModel = OtpViewModel(
        mockRepo,
        phoneNumber: '0912345678',
        purpose: OtpPurpose.registration,
        fullName: 'Nguyen Van A',
        password: 'SecretPassword123!',
      );

      expect(viewModel.password, 'SecretPassword123!');
      viewModel.dispose();
      expect(viewModel.password, isNull);
    });

    test('SecureStorageService: Di chuyển an toàn PII và full_name_\$phone từ SharedPreferences cũ sang SecureStorage', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        'saved_phone': '0987654321',
        'saved_full_name': 'Tran Thi B',
        'saved_role': 'customer',
        'full_name_0987654321': 'Tran Thi B',
        'full_name_0911223344': 'Le Van C',
      });

      final prefs = await SharedPreferences.getInstance();
      final secureStorage = SecureStorageService();

      // Kiểm tra trước khi migration: SharedPreferences có dữ liệu cũ, SecureStorage rỗng
      expect(prefs.getString('saved_phone'), '0987654321');
      expect(await secureStorage.getSavedPhone(), isNull);
      expect(await secureStorage.getFullNameForPhone('0987654321'), isNull);
      expect(await secureStorage.getFullNameForPhone('0911223344'), isNull);

      // Thực hiện migration
      await secureStorage.migratePiiFromPreferences(prefs);

      // Kiểm tra sau khi migration: Dữ liệu đã chuyển an toàn vào SecureStorage
      expect(await secureStorage.getSavedPhone(), '0987654321');
      expect(await secureStorage.getSavedFullName(), 'Tran Thi B');
      expect(await secureStorage.getSavedRole(), 'customer');
      expect(await secureStorage.getFullNameForPhone('0987654321'), 'Tran Thi B');
      expect(await secureStorage.getFullNameForPhone('0911223344'), 'Le Van C');

      // Các khóa cũ trong SharedPreferences đã được dọn dẹp sạch sẽ
      expect(prefs.getString('saved_phone'), isNull);
      expect(prefs.getString('saved_full_name'), isNull);
      expect(prefs.getString('saved_role'), isNull);
      expect(prefs.getString('full_name_0987654321'), isNull);
      expect(prefs.getString('full_name_0911223344'), isNull);
    });
  });
}

class FakePortalRepository implements PortalRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
