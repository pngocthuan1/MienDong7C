import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/core/theme/AppTheme.dart';
import 'package:benhvien7c/features/auth/data/datasources/AuthRemoteDataSource.dart';
import 'package:benhvien7c/features/auth/data/repositories/AuthRepositoryImpl.dart';
import 'package:benhvien7c/features/auth/presentation/providers/AuthProviders.dart';
import 'package:benhvien7c/features/auth/presentation/views/LoginView.dart';
import 'package:benhvien7c/features/auth/presentation/views/RegisterView.dart';
import 'package:benhvien7c/features/auth/presentation/views/ForgotPasswordView.dart';
import 'package:benhvien7c/features/auth/presentation/views/VerifyOtpView.dart';
import 'package:benhvien7c/features/auth/presentation/views/ResetPasswordView.dart';
import 'package:benhvien7c/features/auth/presentation/views/ChangePasswordView.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';

// Patients & Core Session
import 'package:benhvien7c/features/patients/data/datasources/PortalMockDatasource.dart';
import 'package:benhvien7c/features/patients/data/datasources/DatLichKhamRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/data/datasources/ThongBaoRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/data/repositories/PortalRepositoryImpl.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/core/constants/AppStrings.dart';

// Views
import 'package:benhvien7c/features/patients/presentation/views/HomeView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationDetailView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationRecipientStatusView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationPlaygroundView.dart';
import 'package:benhvien7c/features/patients/presentation/views/AppointmentBookingView.dart';
import 'package:benhvien7c/features/patients/presentation/views/PatientProfileCreateView.dart';
import 'package:benhvien7c/features/patients/presentation/views/PatientProfileSelectView.dart';
import 'package:benhvien7c/features/patients/presentation/views/DevTestingView.dart';
import 'package:benhvien7c/features/patients/presentation/views/UserManagementView.dart';
import 'package:benhvien7c/features/patients/presentation/views/UserManagementDetailView.dart';
import 'package:benhvien7c/features/patients/presentation/views/TypeFourDemoView.dart';
import 'package:benhvien7c/features/patients/presentation/views/TypeFourProcessingView.dart';
import 'package:benhvien7c/features/patients/presentation/views/TypeFourResultView.dart';
import 'package:benhvien7c/features/patients/presentation/views/MedicalTicketView.dart';
import 'package:benhvien7c/features/patients/presentation/views/CreateNotificationView.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/core/services/FirebaseTokenService.dart';

import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo kết nối Firebase (google-services.json / GoogleService-Info.plist) & lấy Token
  await FirebaseTokenService.instance.initialize();

  // 1. Khởi tạo dịch vụ lưu trữ an toàn & Lấy Device ID định danh thiết bị
  final secureStorage = SecureStorageService();
  final deviceId = await secureStorage.getOrCreateDeviceId();

  // Xác định hệ điều hành & kiểm tra thiết bị thật vs máy ảo
  String platform = kIsWeb ? 'android' : Platform.operatingSystem;
  bool isPhysicalDevice = false;
  if (!kIsWeb && Platform.isAndroid) {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
    } catch (_) {}
  }

  // 2. Khởi tạo môi trường ứng dụng
  Environment.init(
    appPackageName: 'com.hospisoft.benhvien7c',
    appVersion: '1.0.30',
    deviceId: deviceId,
    platform: platform,
    isPhysicalDevice: isPhysicalDevice,
  );

  // 3. Khởi tạo SharedPreferences phục vụ LocalStorage
  final sharedPreferences = await SharedPreferences.getInstance();

  final customBaseUrl = sharedPreferences.getString('custom_base_url');
  if (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) {
    Environment.setCustomBaseUrl(customBaseUrl.trim());
  }

  // 4. Khởi tạo các Service phụ trợ và gán vào AppLocator tĩnh
  final dioClient = DioClient(secureStorage: secureStorage);
  final remoteDataSource = AuthRemoteDataSource(dioClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource, secureStorage);

  final datLichKhamRemoteDataSource = DatLichKhamRemoteDataSource(dioClient);
  final thongBaoRemoteDataSource = ThongBaoRemoteDataSource(dioClient);
  final portalDatasource = PortalMockDatasource();
  final portalRepository = PortalRepositoryImpl(
    portalDatasource,
    datLichKhamRemoteDataSource,
    thongBaoRemoteDataSource,
  );
  final appSessionStore = AppSessionStore.instance;

  AppLocator.init(
    repository: authRepository,
    storage: secureStorage,
    portalRepo: portalRepository,
    session: appSessionStore,
    dio: dioClient,
  );

  // Phục hồi session nếu có (giữ đăng nhập ngay cả khi lướt xóa app khỏi danh sách gần đây)
  try {
    final savedPhone = sharedPreferences.getString('saved_phone') ?? '';
    final cleanPhone = savedPhone.replaceAll(RegExp(r'\D'), '');
    final savedName = cleanPhone.isNotEmpty ? sharedPreferences.getString('full_name_$cleanPhone') : sharedPreferences.getString('saved_full_name');
    final savedRoleStr = sharedPreferences.getString('saved_role');

    if (savedPhone.isNotEmpty || (savedName != null && savedName.isNotEmpty)) {
      final tokens = await secureStorage.getTokensRecord();
      final accessToken = tokens.$1 ?? 'persisted_access_token_${DateTime.now().millisecondsSinceEpoch}';
      final refreshToken = tokens.$2 ?? 'persisted_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
      final expiry = DateTime.now().add(const Duration(days: 90));

      final role = (savedRoleStr == 'employee') || (savedPhone == AppStrings.demoEmployeePhone)
          ? UserRole.employee
          : UserRole.customer;

      final displayName = (savedName != null && savedName.trim().isNotEmpty)
          ? savedName.trim()
          : (role == UserRole.employee ? 'Phạm Ngọc Thuận' : (savedPhone.isNotEmpty ? savedPhone : 'Khách hàng'));

      appSessionStore.setSession(
        AuthSessionEntity(
          accessToken: accessToken,
          refreshToken: refreshToken,
          refreshTokenExpiry: expiry,
        ),
        UserProfileSession(
          fullName: displayName,
          phoneNumber: savedPhone.isNotEmpty ? savedPhone : '0707587641',
          role: role,
        ),
      );
    }
  } catch (e) {
    debugPrint('Lỗi phục hồi session: $e');
  }

  final String initialRoute = appSessionStore.currentUser != null ? RouteNames.home : RouteNames.login;

  runApp(
    ProviderScope(
      overrides: [
        // Ghi đè sharedPreferencesProvider bằng instance thật đã tải xong
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bệnh viện 7C',
      theme: AppTheme.light(), // Sử dụng cấu hình theme sáng có sẵn trong dự án
      navigatorKey: AppNavigator.navigatorKey, // Đăng ký navigatorKey toàn cục
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'), // Đặt mặc định tiếng Việt cho toàn hệ thống
      initialRoute: initialRoute,
      routes: {
        RouteNames.login: (context) => const LoginView(),
        RouteNames.home: (context) => const HomeView(),
        RouteNames.forgotPassword: (context) => const ForgotPasswordView(),
        RouteNames.register: (context) => const RegisterView(),
        RouteNames.changePassword: (context) => const ChangePasswordView(),
        RouteNames.notifications: (context) => const NotificationView(),
        RouteNames.notificationPlayground: (context) => const NotificationPlaygroundView(),
        RouteNames.appointmentBooking: (context) => const AppointmentBookingView(),
        RouteNames.patientProfileCreate: (context) => const PatientProfileCreateView(),
        RouteNames.patientProfileSelect: (context) => const PatientProfileSelectView(),
        RouteNames.devTesting: (context) => const DevTestingView(),
        RouteNames.userManagement: (context) => const UserManagementView(),
        RouteNames.typeFourDemo: (context) => const TypeFourDemoView(),
        RouteNames.typeFourProcessing: (context) => const TypeFourProcessingView(),
        RouteNames.typeFourResult: (context) => const TypeFourResultView(),
        RouteNames.createNotification: (context) => const CreateNotificationView(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == RouteNames.verifyOtp) {
          final args = settings.arguments as OtpViewArgs;
          return MaterialPageRoute(
            builder: (context) => VerifyOtpView(args: args),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.resetPassword) {
          final args = settings.arguments as ResetPasswordViewArgs;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordView(args: args),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.notificationDetail) {
          final item = settings.arguments as NotificationItemEntity;
          return MaterialPageRoute(
            builder: (context) => NotificationDetailView(item: item),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.notificationRecipientStatus) {
          final item = settings.arguments as NotificationItemEntity;
          return MaterialPageRoute(
            builder: (context) => NotificationRecipientStatusView(item: item),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.userManagementDetail) {
          final args = settings.arguments as UserManagementDetailViewArgs;
          return MaterialPageRoute(
            builder: (context) => UserManagementDetailView(args: args),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.medicalTicket) {
          final args = settings.arguments as MedicalTicketViewArgs;
          return MaterialPageRoute(
            builder: (context) => MedicalTicketView(args: args),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => AppNavigator.safePop(context),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: Color(0xFF0B76D1),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF62748A),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              if (title.contains('Trang chủ'))
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final secureStorage = SecureStorageService();
                      await secureStorage.clearSession();
                      if (context.mounted) {
                        AppNavigator.resetToNamed(context, RouteNames.login);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng xuất'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _parseExpiry(String? expiresStr) {
  if (expiresStr == null || expiresStr.isEmpty) {
    return DateTime.now().add(const Duration(days: 1));
  }
  try {
    final parsedIso = DateTime.tryParse(expiresStr);
    if (parsedIso != null) return parsedIso;

    final numVal = int.tryParse(expiresStr);
    if (numVal != null) {
      if (numVal > 600000000000000000) {
        const unixEpochTicks = 621355968000000000;
        final ticksSince1970 = numVal - unixEpochTicks;
        final millisSince1970 = ticksSince1970 ~/ 10000;
        return DateTime.fromMillisecondsSinceEpoch(millisSince1970);
      }
      if (numVal > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numVal);
      }
      if (numVal > 100000000) {
        return DateTime.fromMillisecondsSinceEpoch(numVal * 1000);
      }
    }
  } catch (e) {
    debugPrint('Error parsing refreshTokenExpiry: $e');
  }
  return DateTime.now().add(const Duration(days: 1));
}
