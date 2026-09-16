import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/core/services/TurnstileVerifyService.dart';
import 'package:benhvien7c/core/network/DioClient.dart';

class AppLocator {
  const AppLocator._();

  static late final AuthRepository authRepository;
  static late final SecureStorageService secureStorage;
  static late final PortalRepository portalRepository;
  static late final AppSessionStore sessionStore;
  static late final TurnstileVerifyService turnstileService;
  static late final DioClient dioClient;
  // SharedPreferences đã được khởi tạo trong main() — inject vào đây để các
  // ViewModel đọc sync mà không cần gọi SharedPreferences.getInstance() async lại
  static late final SharedPreferences sharedPreferences;

  static void init({
    required AuthRepository repository,
    required SecureStorageService storage,
    required PortalRepository portalRepo,
    required AppSessionStore session,
    required DioClient dio,
    required SharedPreferences prefs,
    TurnstileVerifyService? turnstile,
  }) {
    authRepository = repository;
    secureStorage = storage;
    portalRepository = portalRepo;
    sessionStore = session;
    dioClient = dio;
    sharedPreferences = prefs;
    turnstileService = turnstile ?? TurnstileVerifyService();
  }
}
