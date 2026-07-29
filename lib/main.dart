import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:benhvien7c/features/patients/data/repositories/PortalRepositoryImpl.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/core/constants/AppStrings.dart';

// Views
import 'package:benhvien7c/features/patients/presentation/views/HomeView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationDetailView.dart';
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
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';

import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 4. Khởi tạo các Service phụ trợ và gán vào AppLocator tĩnh
  final dioClient = DioClient(secureStorage: secureStorage);
  final remoteDataSource = AuthRemoteDataSource(dioClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource, secureStorage);

  final datLichKhamRemoteDataSource = DatLichKhamRemoteDataSource(dioClient);
  final portalDatasource = PortalMockDatasource();
  final portalRepository = PortalRepositoryImpl(portalDatasource, datLichKhamRemoteDataSource);
  final appSessionStore = AppSessionStore.instance;

  AppLocator.init(
    repository: authRepository,
    storage: secureStorage,
    portalRepo: portalRepository,
    session: appSessionStore,
  );

  // Phục hồi session nếu có
  try {
    final tokens = await secureStorage.getTokensRecord();
    final isExpired = await secureStorage.isRefreshTokenExpired();
    if (tokens.$1 != null && tokens.$2 != null && !isExpired) {
      final expires = await secureStorage.getExpiresRefreshToken();
      final expiry = _parseExpiry(expires);

      final savedPhone = sharedPreferences.getString('saved_phone') ?? '';
      final role = savedPhone == AppStrings.demoEmployeePhone ? UserRole.employee : UserRole.customer;

      appSessionStore.setSession(
        AuthSessionEntity(
          accessToken: tokens.$1!,
          refreshToken: tokens.$2!,
          refreshTokenExpiry: expiry,
        ),
        UserProfileSession(
          fullName: role == UserRole.employee ? 'Nhân Viên Demo' : 'Khách Hàng Demo',
          phoneNumber: savedPhone.isNotEmpty ? savedPhone : '0902377251',
          role: role,
        ),
      );
    }
  } catch (e) {
    debugPrint('Lỗi phục hồi session: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        // Ghi đè sharedPreferencesProvider bằng instance thật đã tải xong
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bệnh viện 7C',
      theme: AppTheme.light(), // Sử dụng cấu hình theme sáng có sẵn trong dự án
      navigatorKey: AppNavigator.navigatorKey, // Đăng ký navigatorKey toàn cục
      initialRoute: RouteNames.login,
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
